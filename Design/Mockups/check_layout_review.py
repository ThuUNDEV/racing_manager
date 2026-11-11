"""Check the design mockup only; does not launch Godot or touch saves."""
from pathlib import Path
import json
from playwright.sync_api import sync_playwright

HERE = Path(__file__).resolve().parent
report = {'scope': 'HTML design mockup; no Godot runtime verification', 'views': [], 'errors': []}
with sync_playwright() as p:
    browser = p.chromium.launch(executable_path=r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe', headless=True)
    page = browser.new_page()
    page.on('pageerror', lambda e: report['errors'].append(str(e)))
    for width,height in [(320,568),(360,800),(390,844),(412,915)]:
        page.set_viewport_size({'width':width,'height':height})
        page.goto((HERE/'layout_asset_redesign.html').as_uri())
        page.wait_for_selector('#pl-content h3')
        options = page.locator('#pl-screen option').evaluate_all('(els)=>els.map(e=>e.value)')
        for screen in options:
            page.select_option('#pl-screen',screen)
            issue = page.evaluate('''()=>{
              const root=document.getElementById('pitlane-layout');
              const b=root.getBoundingClientRect();
              const overflow=[...root.querySelectorAll('*')].filter(e=>{
                const r=e.getBoundingClientRect();return r.width>0&&(r.right>b.right+1||r.left<b.left-1);
              }).map(e=>e.tagName+'.'+e.className);
              return {overflow,brokenImages:[...root.querySelectorAll('img')].filter(i=>i.complete&&!i.naturalWidth).length,
                empty:!root.querySelector('#pl-content').textContent.trim()};
            }''')
            report['views'].append(dict(width=width,screen=screen,**issue))
        page.select_option('#pl-screen','bag')
        page.locator('[data-detail="gear"]').first.click()
        assert page.locator('#pl-content').inner_text().find('Thiếu 6 mảnh') >= 0
        page.locator('[data-close]').first.click()
        assert page.locator('.pl-inventory').is_visible()
        page.select_option('#pl-screen','look')
        page.locator('[data-color="Đỏ"]').click()
        assert 'Đỏ' in page.locator('#pl-draft').inner_text()
    page.set_viewport_size({'width':390,'height':844})
    page.select_option('#pl-screen','garage')
    page.screenshot(path=str(HERE/'layout_review_assets/garage_review.png'),full_page=True)
    page.select_option('#pl-screen','bag')
    page.screenshot(path=str(HERE/'layout_review_assets/bag_review.png'),full_page=True)
    browser.close()
bad=[v for v in report['views'] if v['overflow'] or v['brokenImages'] or v['empty']]
report['passed'] = not bad and not report['errors']
(HERE/'layout_review_assets/validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'passed':report['passed'],'views':len(report['views']),'issues':bad,'errors':report['errors']},ensure_ascii=False))
assert report['passed']
