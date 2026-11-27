from pathlib import Path
import json, base64, mimetypes
ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).resolve().parent
catalog=json.loads((ROOT/'data/iap.json').read_text())
products={p['sku']:p for p in catalog['products']}
def asset(path):
 p=ROOT/path
 return 'data:'+mimetypes.guess_type(p.name)[0]+';base64,'+base64.b64encode(p.read_bytes()).decode()
paths={
 'starter':'assets/pack_promo_v1/hero_starter.webp','weekly':'assets/pack_promo_v1/hero_weekly.webp','bundle':'assets/pack_promo_v1/hero_noads.webp',
 'income':'assets/pack_promo_v1/perk_income.png','noads':'assets/soft_miniature_ui_v1/runtime_flare/shop_no_ads.png','my':'assets/soft_miniature_ui_v1/runtime_flare/driver_my.png',
 'gem':'assets/daily_gift_v3/icons/gem.png','pro':'assets/pack_promo_v1/ticket_pro.png','allstar':'assets/pack_promo_v1/ticket_allstar.png','standard':'assets/pack_promo_v1/ticket_standard.png','elite':'assets/pack_promo_v1/ticket_elite.png',
 'cash':'assets/soft_miniature_ui_v1/runtime_flare/currency_cash.png','online':'assets/pack_promo_v1/icon_income.png','race':'assets/pack_promo_v1/icon_race.png','block':'assets/reward_icons/no_ads.svg',
 'font':'assets/soft_miniature_ui_v1/fonts/Nunito.ttf'}
a={k:asset(v) for k,v in paths.items()}
configs=[
 ('starter_1','Gói Tân binh','Khởi đầu','Sẵn sàng cho cuộc đua đầu tiên!','starter','Giá trị ×4,4','Quà khởi đầu','Nhận đủ tài nguyên ngay sau khi mua.'),
 ('weekly_s','Gói tuần S','Tiếp sức mỗi tuần','Thêm tài nguyên, tăng tốc đội đua.','weekly','Giá trị ×2,6','Quà tiếp sức','Nhận đủ tài nguyên ngay sau khi mua.'),
 ('offer_noads_bundle','Đội tự do + quà','Quyền lợi & quà','Bỏ quảng cáo, nhận thêm quà.','bundle','Vĩnh viễn','Bỏ quảng cáo','Nhận thưởng quảng cáo không cần xem.'),
 ('income_x2','Thu nhập ×2','Nâng cấp vĩnh viễn','Nhân đôi thu nhập, mãi mãi!','income','Vĩnh viễn','Nhân đôi thu nhập','Áp dụng cho online và thưởng đua.'),
 ('no_ads','Đội tự do','Nâng cấp vĩnh viễn','Đua thỏa thích, nhận thưởng nhanh.','noads','Vĩnh viễn','Bỏ quảng cáo','Nhận thưởng quảng cáo không cần xem.'),
 ('char_my','My về đội bạn','Tay đua & quà','Thêm một gương mặt cho đội đua.','my','Chắc chắn nhận','Tay đua Zielinski','Nhận trực tiếp, không mở ngẫu nhiên.')]
cards=[]
for sku,title,group,sub,art,badge,benefit,desc in configs:
 p=products[sku]; g=p['grant']; rewards=[]
 if g.get('gems'):rewards.append(('gem',str(g['gems']),'Gem'))
 for kind,count in g.get('driver_coupon',{}).items():rewards.append((kind,str(count),'Vé tay đua '+{'pro':'Pro','allstar':'All-Star'}[kind]))
 for kind,count in g.get('gear_coupon',{}).items():rewards.append((kind,str(count),'Vé trang bị '+kind.title()))
 if g.get('income_min'):rewards.append(('cash',str(g['income_min']//60)+' giờ','Thu nhập tức thì'))
 if g.get('driver_shards'):rewards.insert(0,('my',str(g['driver_shards']),'Mảnh Zielinski'))
 if sku=='income_x2':rewards=[('online','×2','Thu nhập online'),('race','×2','Thưởng đua')]
 icon='block' if 'noads' in art or art=='bundle' else ('my' if art=='my' else ('online' if art=='income' else 'cash'))
 note='Tiền nhận theo thu nhập của đội tại thời điểm mua.' if g.get('income_min') else ('Không nhân chồng với boost quảng cáo; dùng hệ số cao hơn.' if art=='income' else ('Đã có tay đua: đổi thành tổng 70 mảnh Zielinski.' if art=='my' else 'Tắt quảng cáo ngắt quãng và bỏ bước xem video nhận thưởng.'))
 cards.append(dict(sku=sku,title=title,group=group,sub=sub,art=art,badge=badge,benefit=benefit,desc=desc,icon=icon,rewards=rewards,note=note,price=p['price_fallback'],limit='1 lần / tuần' if p.get('weekly_limit') else 'Mua 1 lần',odds=bool(g.get('driver_coupon') or g.get('gear_coupon'))))
html=(OUT/'template.html').read_text().replace('__ASSETS__',json.dumps(a)).replace('__CARDS__',json.dumps(cards,ensure_ascii=False)).replace('__FONT__',a['font'])
(OUT/'index.html').write_text(html)
print('Built',OUT/'index.html')
