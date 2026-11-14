from pathlib import Path
import json
from playwright.sync_api import sync_playwright

OUT=Path(__file__).resolve().parent
GROUPS=['featured','drivers','perks','passes','resources','extras']
REPORT={'boards':[],'mobile':[],'errors':[]}
for folder in ['boards','cards','popups','mobile']:
    (OUT/folder).mkdir(exist_ok=True)
with sync_playwright() as pw:
    browser=pw.chromium.launch(channel='msedge')
    page=browser.new_page(viewport={'width':1250,'height':950},device_scale_factor=2)
    page.on('pageerror',lambda e:REPORT['errors'].append(str(e)))
    page.goto((OUT/'index.html').as_uri()+'?print=1')
    page.wait_for_function('document.querySelectorAll(".specimen").length===38')
    page.evaluate('document.fonts.ready')
    page.wait_for_timeout(700)
    assert page.locator('.card[data-sku]').count()==38
    for i,g in enumerate(GROUPS,1):
        element=page.locator('#'+g)
        element.screenshot(path=str(OUT/'boards'/f'{i:02}_{g}.png'))
        REPORT['boards'].append({'group':g,'cards':element.locator('.card').count()})
    skus=page.locator('.specimen').evaluate_all('(els)=>els.map(e=>e.dataset.ref)')
    for sku in skus:
        page.locator(f'.specimen[data-ref="{sku}"] .card').screenshot(path=str(OUT/'cards'/f'{sku}.png'))
        page.evaluate('(sku)=>openPack(sku)',sku)
        page.locator('#modal').screenshot(path=str(OUT/'popups'/f'{sku}.png'))
        page.locator('#modal .close').click()
    # Actual dialog interactions: owned driver conversion and service state preview.
    page.evaluate("openPack('char_my',true)")
    assert '70 mảnh' in page.locator('#modalbody').inner_text()
    page.locator('#modal').screenshot(path=str(OUT/'popups'/'char_my_owned.png'))
    for state in ['busy','pending','offline','owned','limit']:
        page.evaluate('(s)=>statePreview(s)',state)
        assert page.locator('#modalbody .price').is_disabled()
    page.locator('#modal .close').click()
    # Review fields are local-only and export includes all catalog entries.
    page.evaluate("save('starter_1','status','approved')")
    assert page.evaluate("JSON.parse(localStorage.getItem('shop-review-01')).starter_1.status")=='approved'
    page.evaluate("localStorage.removeItem('shop-review-01');review={}")
    for width in [320,390,412]:
        page.set_viewport_size({'width':width,'height':915})
        page.evaluate('(w)=>{document.querySelector("#width").value=String(w);document.querySelector("#width").onchange()}',width)
        page.locator('#groups').select_option('all')
        page.wait_for_timeout(150)
        overflow=page.evaluate('document.documentElement.scrollWidth>window.innerWidth')
        bad=page.locator('.card').evaluate_all('(els)=>els.filter(e=>e.scrollWidth>e.clientWidth+2).map(e=>({sku:e.dataset.sku,scroll:e.scrollWidth,client:e.clientWidth}))')
        REPORT['mobile'].append({'width':width,'page_overflow':overflow,'card_overflow':bad})
        assert not overflow,(width,'page overflow')
        assert not bad,(width,bad)
        for g in ['featured','drivers','resources']:
            page.locator('#groups').select_option(g)
            page.screenshot(path=str(OUT/'mobile'/f'{width}_{g}.png'),full_page=True)
        page.evaluate("openPack('starter_2')")
        page.locator('#modal').screenshot(path=str(OUT/'mobile'/f'{width}_popup.png'))
        page.locator('#modal .close').click()
    browser.close()
(OUT/'verification.json').write_text(json.dumps(REPORT,indent=2),encoding='utf-8')
assert not REPORT['errors'],REPORT['errors']
print(json.dumps(REPORT))
