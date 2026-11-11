"""Workshop GP completion: fresh vector art, original synthesized audio, resources.

No raster images are edited/re-encoded. Pillow only measures alpha for atlas regions.
Run after build_pack.py. The optional image arguments copy ImageGen originals unchanged.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import shutil
import wave
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

from build_pack import ROOT, RES, alpha_bounds, atlas_resource, style, svg_panel, write

RATE = 44100
ORANGE = "#F47510"
INK = "#202B38"
CREAM = "#FFF7E8"
TEAL = "#248B91"


def svg(path: str, body: str, w: int = 128, h: int = 128) -> None:
    write(path, f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{body}</svg>\n')


def make_icons() -> list[str]:
    # New vector artwork, 128px source; matches the palette of the rendered primary icons.
    shapes = {
        "close": '<path d="M40 40L88 88M88 40L40 88"/>',
        "back": '<path d="M76 30L42 64L76 98M44 64H102"/>',
        "next": '<path d="M49 30L83 64L49 98"/>',
        "plus": '<path d="M64 30V98M30 64H98"/>',
        "minus": '<path d="M30 64H98"/>',
        "check": '<path d="M28 65L52 88L101 36"/>',
        "lock": '<rect x="33" y="57" width="62" height="48" rx="9"/><path d="M43 57V39A21 21 0 0 1 85 39V57M64 76V87"/>',
        "unlock": '<rect x="33" y="57" width="62" height="48" rx="9"/><path d="M43 57V39A21 21 0 0 1 85 39M64 76V87"/>',
        "settings": '<path d="M54 22H74L78 36L91 43L105 40L115 57L105 68L105 81L96 95L81 92L70 104H50L46 90L32 83L18 86L8 69L19 58L19 44L30 30L45 33Z"/><circle cx="62" cy="63" r="18"/>',
        "music": '<path d="M51 86V31L98 22V75M51 43L98 34"/><ellipse cx="36" cy="89" rx="15" ry="12"/><ellipse cx="83" cy="78" rx="15" ry="12"/>',
        "sound": '<path d="M22 51H41L64 31V97L41 77H22ZM80 45Q100 64 80 83M92 31Q124 64 92 97"/>',
        "mute": '<path d="M19 51H38L61 31V97L38 77H19ZM82 47L109 81M109 47L82 81"/>',
        "vibration": '<rect x="42" y="24" width="44" height="80" rx="8"/><path d="M25 40L17 52L25 64L17 77L25 89M103 40L111 52L103 64L111 77L103 89M59 90H69"/>',
        "motion": '<path d="M19 43H49M12 63H38M23 83H49M61 31L103 64L61 97Z"/>',
        "info": '<circle cx="64" cy="64" r="43"/><path d="M64 57V89M64 39V40"/>',
        "help": '<circle cx="64" cy="64" r="43"/><path d="M48 48C48 28 86 29 86 49C86 63 64 65 64 77M64 92V93"/>',
        "clock": '<circle cx="64" cy="64" r="43"/><path d="M64 35V66L84 77"/>',
        "offline": '<path d="M38 45C16 44 12 80 36 86H95C123 80 111 46 91 47C83 18 43 16 38 45ZM64 48V77M52 66L64 78L76 66"/>',
        "gift": '<rect x="25" y="52" width="78" height="54" rx="5"/><path d="M20 40H108V58H20ZM64 40V106C38 42 26 31 36 22C48 13 61 24 64 40C67 24 82 13 92 22C103 33 87 44 64 40"/>',
        "mission": '<rect x="30" y="26" width="72" height="83" rx="8"/><path d="M47 20H83V37H47ZM41 57L47 63L57 51M68 57H89M41 82L47 88L57 76M68 82H89"/>',
        "mail": '<rect x="17" y="32" width="94" height="67" rx="8"/><path d="M20 37L64 73L108 37M20 95L47 71M108 95L81 71"/>',
        "engine": '<path d="M27 40H86V50H103V92H86V101H37V88H24V65H13V44H27ZM41 26H75M58 26V40M104 60H115V82H104M47 60L64 75L77 59"/>',
        "tyre": '<ellipse cx="64" cy="64" rx="34" ry="47"/><ellipse cx="64" cy="64" rx="16" ry="27"/><path d="M41 28L51 39M86 28L76 39M32 55H47M81 55H96M32 75H47M81 75H96M41 100L51 89M86 100L76 89"/>',
        "chassis": '<path d="M43 22H85L101 42V91L85 108H43L27 91V42ZM43 22V108M85 22V108M43 42L85 89M85 42L43 89M20 40V59M108 40V59M20 77V96M108 77V96"/>',
        "gearbox": '<path d="M36 28V78C36 88 64 90 64 78V28M64 59H92V28M23 17H49M51 17H77M79 17H105"/><circle cx="36" cy="105" r="9"/><circle cx="64" cy="105" r="9"/><circle cx="92" cy="105" r="9"/>',
        "venue": '<path d="M18 54L64 23L110 54V106H18ZM36 106V68H92V106M45 82H83M45 94H83M32 46H96"/>',
        "training": '<path d="M16 49V79M29 37V91M99 37V91M112 49V79M29 64H99"/>',
        "flag": '<path d="M27 110V23C54 5 76 49 107 24V78C77 102 57 60 27 78M49 20V76M72 32V86M94 32V86M28 49C55 32 77 76 107 51"/>',
        "pause": '<path d="M43 29V99M85 29V99"/>',
        "play": '<path d="M39 24L104 64L39 104Z"/>',
        "home": '<path d="M15 62L64 21L113 62M29 52V108H99V52M53 108V77H75V108"/>',
        "refresh": '<path d="M101 50A40 40 0 1 0 100 83M101 24V52H74"/>',
        "warning": '<path d="M64 18L115 106H13ZM64 50V76M64 90V91"/>',
        "star": '<path d="M64 15L79 46L113 51L89 75L95 110L64 93L33 110L39 75L15 51L49 46Z"/>',
        "fan": '<circle cx="64" cy="38" r="17"/><path d="M37 106V91C37 65 91 65 91 91V106M31 36A13 13 0 0 0 31 62M97 36A13 13 0 0 1 97 62M24 77C8 81 12 98 12 106M104 77C120 81 116 98 116 106"/>',
        "rank_up": '<path d="M24 61L64 22L104 61M24 91L64 52L104 91M64 56V110"/>',
        "coin_small": '<circle cx="64" cy="64" r="45"/><circle cx="64" cy="64" r="32"/><path d="M64 39V89M77 47C46 33 41 61 64 64C88 67 82 94 50 81"/>',
        "gem_small": '<path d="M34 27H94L115 52L64 110L13 52ZM13 52H115M34 27L47 52L64 110L81 52L94 27M47 52L64 27L81 52"/>',
        "lap": '<path d="M35 26H93Q110 26 110 43V85Q110 102 93 102H35Q18 102 18 85V43Q18 26 35 26ZM48 47H80V81H48ZM17 63H49M26 53V73M36 53V73"/>',
        "save": '<path d="M22 22H93L107 37V107H22ZM38 22V56H88V22M39 107V75H90V107M75 30V46"/>',
    }
    for name, shape in shapes.items():
        body = f'<g fill="none" stroke="{INK}" stroke-width="10" stroke-linecap="round" stroke-linejoin="round">{shape}</g><g fill="none" stroke="{CREAM}" stroke-width="6" stroke-linecap="round" stroke-linejoin="round" transform="translate(0 -2)">{shape}</g>'
        svg(f"icons/vector/{name}.svg", body)
        # Neutral monochrome silhouette for buttons on light surfaces.
        svg(f"icons/vector_dark/{name}.svg", f'<g fill="none" stroke="{INK}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round">{shape}</g>')
    return list(shapes)


def make_ui() -> None:
    for name, top, bottom, border in [
        ("button_secondary", "#4D5968", "#202B38", "#15202B"),
        ("button_success", "#55A95A", "#28753A", "#1F612D"),
        ("button_danger", "#E76750", "#AE372D", "#872C24"),
        ("card_selected", "#FFF9EC", "#FFE4C7", "#F47510"),
        ("card_locked", "#E8E3DC", "#D3CDC4", "#B5AB9E"),
        ("toast", "#354456", "#202B38", "#758191"),
        ("modal", "#FFFDF8", "#EDE3D4", "#B9A98E"),
    ]:
        svg_panel(name, top, bottom, border, 12)
        style(name, name, 16, (12, 10, 12, 12))
    svg("ui/progress_track.svg", '<rect x="2" y="2" width="252" height="20" rx="10" fill="#D6CBBC" stroke="#BBAE9C" stroke-width="2"/>', 256, 24)
    svg("ui/progress_fill.svg", '<rect x="2" y="2" width="252" height="20" rx="10" fill="#F47510"/><path d="M12 6H244" stroke="#FFC988" stroke-width="3" stroke-linecap="round"/>', 256, 24)
    svg("ui/slider_track.svg", '<rect x="2" y="8" width="252" height="8" rx="4" fill="#C7BBAA"/>', 256, 24)
    svg("ui/slider_grabber.svg", '<circle cx="16" cy="16" r="13" fill="#F47510" stroke="#FFF7E8" stroke-width="3"/>', 32, 32)
    for checked in [False, True]:
        svg(f'ui/toggle_{"on" if checked else "off"}.svg', f'<rect x="2" y="2" width="60" height="32" rx="16" fill="{"#F47510" if checked else "#B8B0A5"}"/><circle cx="{46 if checked else 18}" cy="18" r="12" fill="#FFFDF8"/>', 64, 36)
        svg(f'ui/checkbox_{"on" if checked else "off"}.svg', '<rect x="3" y="3" width="30" height="30" rx="7" fill="' + (ORANGE if checked else CREAM) + '" stroke="#B7A58D" stroke-width="2"/>' + ('<path d="M10 18L16 24L27 12" fill="none" stroke="white" stroke-width="3" stroke-linecap="round"/>' if checked else ''), 36, 36)
    svg("ui/modal_overlay.svg", '<rect width="64" height="64" fill="#101B28" opacity=".72"/>', 64, 64)
    svg("ui/notification_dot.svg", '<circle cx="12" cy="12" r="10" fill="#E4583E" stroke="#FFF7E8" stroke-width="3"/>', 24, 24)
    svg("ui/tooltip_arrow.svg", '<path d="M2 2H30L16 18Z" fill="#202B38"/>', 32, 20)
    svg("ui/empty_state.svg", '<circle cx="64" cy="64" r="56" fill="#E8DFD0"/><path d="M29 49L64 29L99 49V89L64 109L29 89ZM29 49L64 69L99 49M64 69V109" fill="none" stroke="#B2A28C" stroke-width="4"/>')
    svg("ui/tutorial_hand.svg", '<path d="M53 112L29 75Q22 61 34 58Q41 57 50 73V28Q50 13 62 16Q70 18 70 28V55Q77 45 84 53Q93 48 99 59Q113 57 112 73L107 101Q104 116 91 120H67Z" fill="#FFF7E8" stroke="#202B38" stroke-width="5" stroke-linejoin="round"/><path d="M70 58V80M84 61V82M98 67V85" fill="none" stroke="#B9A98E" stroke-width="3"/><path d="M37 23L28 16M61 8V1M85 21L97 14" stroke="#F47510" stroke-width="5" stroke-linecap="round"/>')
    svg("ui/loading_spinner.svg", '<circle cx="64" cy="64" r="43" fill="none" stroke="#495566" stroke-width="8"/><path d="M64 21A43 43 0 0 1 107 64" fill="none" stroke="#F47510" stroke-width="8" stroke-linecap="round"/>')
    for name, color, number in [("rookie", "#B77B44", "I"), ("semi_pro", "#A6B6C6", "II"), ("pro", "#F4B933", "III")]:
        # Decorative stripes instead of baked rank labels: all labels remain live in UI.
        stripes = ''.join(f'<rect x="{55+(i-(len(number)-1)/2)*16}" y="63" width="10" height="39" rx="3" fill="#FFF6DA"/>' for i in range(len(number)))
        svg(f"badges/{name}.svg", f'<path d="M64 7L112 25V70C112 99 84 117 64 123C44 117 16 99 16 70V25Z" fill="{INK}" stroke="{color}" stroke-width="7"/><path d="M31 40L43 52L64 32L85 52L97 40V65H31Z" fill="{color}"/>{stripes}')
    for i, color in enumerate(["#F4B933", "#A6B6C6", "#B77B44"]):
        svg(f"badges/medal_{i+1}.svg", f'<path d="M32 8H56L64 45L72 8H96L86 64H42Z" fill="#F47510"/><circle cx="64" cy="81" r="35" fill="{color}" stroke="#FFF2CB" stroke-width="4"/><path d="M64 56L71 71L88 73L76 85L79 103L64 94L49 103L52 85L40 73L57 71Z" fill="#FFF2CB"/>')
    svg("branding/app_icon.svg", '<defs><linearGradient id="b" x2="0" y2="1"><stop stop-color="#3B4755"/><stop offset="1" stop-color="#18222F"/></linearGradient></defs><rect width="1024" height="1024" rx="210" fill="url(#b)"/><path d="M150 325H625C825 325 875 685 625 685H150V575H625C710 575 710 435 625 435H150Z" fill="#F47510"/><path d="M195 235H255V345H195ZM255 235H315V290H255ZM315 235H375V345H315ZM375 235H435V290H375Z" fill="#FFF7E8"/><path d="M195 745H435V790H195ZM475 745H585V790H475Z" fill="#FFF7E8"/>', 1024, 1024)
    # Text is intentionally absent. Add localizable game name with the engine font.
    svg("branding/splash_background.svg", '<rect width="390" height="844" fill="#202B38"/><g stroke="#F47510" stroke-width="2" opacity=".3"><path d="M0 125L390 515M0 165L390 555M0 205L390 595M0 245L390 635"/></g><path d="M0 800H390V844H0Z" fill="#F47510"/>', 390, 844)


def make_vfx() -> None:
    # Individual SVG frame sources, also collected into native Godot SpriteFrames.
    effects = {"upgrade": 12, "reward_burst": 12, "confetti": 16, "finish_flash": 10, "coin_spin": 12, "player_ring": 12}
    rng = np.random.default_rng(7301)
    particles = [(float(rng.uniform(0, math.tau)), float(rng.uniform(.55, 1)), int(rng.integers(0, 4))) for _ in range(24)]
    for name, count in effects.items():
        for frame in range(count):
            t = frame / (count - 1)
            parts = []
            if name in ["upgrade", "reward_burst"]:
                for a, speed, c in particles[:8 if name=='upgrade' else 24]:
                    r = (12 + 84 * t) * speed
                    x, y = 128 + math.cos(a)*r, 128 + math.sin(a)*r
                    opacity = math.sin(math.pi * t) ** .6
                    color = [ORANGE, "#FFD983", "#FFF8D8", TEAL][c]
                    if name=='upgrade':
                        parts.append(f'<path d="M{x-4} {y}H{x+4}M{x} {y-4}V{y+4}" stroke="{color}" stroke-width="3" opacity="{opacity:.3f}"/>')
                    else:
                        parts.append(f'<circle cx="{x:.2f}" cy="{y:.2f}" r="{3+3*speed:.2f}" fill="#F5BF42" stroke="#FFE6A2" stroke-width="1.5" opacity="{opacity:.3f}"/>')
                parts.append(f'<circle cx="128" cy="128" r="{20+85*t:.2f}" fill="none" stroke="#FFA338" stroke-width="{7*(1-t):.2f}" opacity="{(1-t)*.7:.3f}"/>')
                if name=='upgrade':
                    y=160-65*t
                    parts.append(f'<path d="M105 {y}L128 {y-24}L151 {y}M105 {y+20}L128 {y-4}L151 {y+20}" fill="none" stroke="#FFB147" stroke-width="9" stroke-linecap="round" stroke-linejoin="round" opacity="{math.sin(math.pi*t):.3f}"/>')
            elif name == "confetti":
                for j, (a, speed, c) in enumerate(particles):
                    x = 128 + math.cos(a) * speed * 116 * min(1, t*2)
                    y = 90 - math.sin(a)*speed*80*t + 140*t*t
                    parts.append(f'<rect x="{x:.2f}" y="{y:.2f}" width="5" height="11" rx="1" fill="{[ORANGE,TEAL,"#FFD675",CREAM][c]}" opacity="{min(1,t*8)*(1-t):.3f}" transform="rotate({j*19+t*250:.1f} {x:.2f} {y:.2f})"/>')
            elif name == "finish_flash":
                parts.append(f'<path d="M0 {154-60*t:.2f}L256 {30+60*t:.2f}V{90+60*t:.2f}L0 {214-60*t:.2f}Z" fill="#FFF4CB" opacity="{math.sin(math.pi*t)*.8:.3f}"/>')
                for j in range(8):
                    parts.append(f'<rect x="{j*32}" y="112" width="32" height="32" fill="{"#FFF7E8" if j%2 else INK}" opacity="{math.sin(math.pi*t):.3f}"/>')
            elif name == "coin_spin":
                width = 9 + 55*abs(math.cos(math.tau*t))
                parts.append(f'<ellipse cx="128" cy="128" rx="{width:.2f}" ry="64" fill="#F3B631" stroke="#FFE79B" stroke-width="7"/><ellipse cx="128" cy="128" rx="{width*.75:.2f}" ry="49" fill="none" stroke="#C48615" stroke-width="3"/>')
            elif name == "player_ring":
                r = 60 + 12*math.sin(math.tau*t)
                parts.append(f'<circle cx="128" cy="128" r="{r:.2f}" fill="none" stroke="#FFF8E7" stroke-width="6" opacity=".9"/><circle cx="128" cy="128" r="{r+8:.2f}" fill="none" stroke="#F47510" stroke-width="2" opacity=".7"/>')
            svg(f"vfx/{name}/frame_{frame:02d}.svg", ''.join(parts), 256, 256)
        exts = '\n'.join(f'[ext_resource type="Texture2D" path="{RES}/vfx/{name}/frame_{i:02d}.svg" id="{i+1}"]' for i in range(count))
        frames = ',\n'.join('{"duration": 1.0, "texture": ExtResource("%d")}' % (i+1) for i in range(count))
        loop = 'true' if name in ["coin_spin", "player_ring"] else 'false'
        write(f"vfx/{name}.tres", f'[gd_resource type="SpriteFrames" load_steps={count+1} format=3]\n\n{exts}\n\n[resource]\nanimations = [{{"frames": [{frames}], "loop": {loop}, "name": &"default", "speed": 24.0}}]\n')
        write(f"vfx/{name}.tscn", f'[gd_scene load_steps=3 format=3]\n\n[ext_resource type="SpriteFrames" path="{RES}/vfx/{name}.tres" id="1"]\n[ext_resource type="Script" path="{RES}/components/fx_player.gd" id="2"]\n\n[node name="{name.title().replace("_", "")}" type="AnimatedSprite2D"]\nscript = ExtResource("2")\nsprite_frames = ExtResource("1")\nautoplay = "default"\n')


def make_components_and_paths() -> None:
    defaults = {
        'upgrade': ('Động cơ','Cấp 2 · 44 → 46','icons/vector_dark/engine.svg','Nâng cấp · 120'),
        'driver': ('An','Pace 44 · Kỹ thuật 40 · Bình tĩnh 40','portraits/driver_an.tres','Chọn tay đua'),
        'league': ('Giải tập sự','24 / 36 điểm','rewards/rookie_cup.tres',''),
        'reward': ('Quà hằng ngày','200 tiền','rewards/daily_gift.tres','Nhận quà'),
        'mission': ('Hoàn thành cuộc đua đầu','1/1 · Thưởng 100 tiền','icons/vector_dark/mission.svg','Nhận thưởng'),
        'toast': ('Nâng cấp thành công','Động cơ đã tăng một cấp','icons/vector/check.svg',''),
        'stat': ('Tốc độ','44 / 100','icons/vector_dark/engine.svg',''),
        'resource': ('12.450','Tiền','icons/coins.tres',''),
        'modal': ('Chào mừng trở lại','Thu nhập cơ sở khi bạn vắng mặt','rewards/money_bag.tres','Tiếp tục'),
    }
    for kind in ['upgrade','driver','league','reward','mission','toast','stat','resource','modal']:
        title, subtitle, image, action = defaults[kind]
        write(f'components/{kind}_card.tscn', f'''[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="{RES}/components/asset_widget.gd" id="1"]

[node name="{kind.title()}Card" type="PanelContainer"]
script = ExtResource("1")
kind = "{kind}"
title = "{title}"
subtitle = "{subtitle}"
image_path = "{RES}/{image}"
action_text = "{action}"
''')
    for kind, title, description, image, confirm in [
        ('result','Kết quả cuộc đua','Vị trí 2/8 · +100 tiền · +8 điểm mùa','semi_pro_cup','Tiếp tục'),
        ('offline','Chào mừng trở lại!','30 phút · 8 tiền/s × 50% · +7.200 tiền','money_bag','Tiếp tục'),
        ('season','Thăng hạng!','38/50 điểm · Mở giải Bán chuyên','pro_cup','Bắt đầu mùa mới'),
        ('daily_reward','Quà hằng ngày','200 tiền · Một lần mỗi ngày','daily_gift','Nhận quà'),
        ('confirm','Xác nhận thao tác','Đây là cửa sổ xác nhận dùng lại.','','Xác nhận'),
    ]:
        write(f'components/{kind}_dialog.tscn',f'''[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="{RES}/components/asset_dialog.gd" id="1"]

[node name="{kind.title().replace('_','')}Dialog" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")
title = "{title}"
description = "{description}"
image_path = "{RES+'/rewards/'+image+'.tres' if image else ''}"
confirm_text = "{confirm}"
show_cancel = {'true' if kind=='confirm' else 'false'}
''')
    layouts = {
        'harbor': ('textures/workshop_oval.png', .775, [
            [.737,.775,-.1,0,.1065,0], [.930,.5,0,.152,0,-.152], [.737,.225,.1065,0,-.1,0],
            [.263,.225,.1,0,-.1065,0], [.070,.5,0,-.152,0,.152], [.263,.775,-.1065,0,.1,0]]),
        'pine': ('textures/pine_circuit.png', .803, [
            [.735,.803,-.12,0,.115,0], [.932,.485,0,.177,0,-.177], [.747,.185,.105,0,-.09,0],
            [.5,.303,.1,0,-.1,0], [.24,.185,.1,0,-.1,0], [.066,.47,0,-.16,0,.18], [.265,.803,-.11,0,.12,0]]),
        'city': ('textures/city_technical.png', .786, [
            [.735,.786,-.12,0,.115,0], [.930,.49,0,.165,0,-.165], [.735,.225,.1,0,-.08,0],
            [.64,.228,.045,0,-.045,0], [.5,.319,.06,0,-.06,0], [.36,.228,.045,0,-.045,0],
            [.265,.225,.06,0,-.11,0], [.067,.49,0,-.165,0,.165], [.265,.786,-.11,0,.12,0]])}
    for name,(texture,y,points) in layouts.items():
        start=[.5,y,-.08,0,.08,0]
        write(f'layout/{name}.json',json.dumps({
            'id':name, 'texture':texture,'origin':'top-left','point_format':['x','y','in_x','in_y','out_x','out_y'],
            'points':[start]+points+[start], 'closed':True,'car_forward':'+Y',
            'mapping':'Normalized lap_fraction maps to baked visual curve length; gameplay sectors remain owned by RaceSim.',
            'direction':'bottom start line toward right, then upward around the circuit',
        },indent=2)+'\n')


def tone(freq: float, duration: float, volume: float = 1.0, kind: str = "sine") -> np.ndarray:
    t = np.arange(int(duration*RATE), dtype=np.float64)/RATE
    phase = 2*np.pi*freq*t
    sound = np.sin(phase)
    if kind == "warm":
        sound = .72*np.sin(phase)+.20*np.sin(2*phase)+.08*np.sin(3*phase)
    elif kind == "bass":
        sound = .8*np.sin(phase)+.2*np.sin(2*phase)
    envelope = np.minimum(t/.006, 1) * np.minimum(np.maximum(duration-t, 0)/.04, 1)
    return sound*envelope*volume


def write_wav(relative: str, data: np.ndarray, loop: bool = False) -> dict:
    if data.ndim == 1:
        data = np.stack([data, data], axis=1)
    peak = float(np.max(np.abs(data)))
    if peak > .88:
        data = data*.88/peak
    dest = ROOT/relative
    dest.parent.mkdir(parents=True, exist_ok=True)
    pcm = np.rint(data*32767).astype('<i2')
    with wave.open(str(dest), 'wb') as f:
        f.setnchannels(2)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(pcm.tobytes())
    return {"path": relative, "duration": round(len(data)/RATE, 4), "sample_rate": RATE, "channels": 2, "bits": 16, "loop": loop, "peak": round(float(np.max(np.abs(pcm)))/32767, 5), "rms": round(float(np.sqrt(np.mean(data**2))), 5), "origin": "original procedural synthesis, not a recording"}


def make_audio() -> list[dict]:
    records = []
    def save(name: str, data: np.ndarray, loop: bool = False):
        records.append(write_wav(f"audio/{name}.wav", data, loop))
    def chord(freqs: list[float], length: float, volume: float = .15) -> np.ndarray:
        return sum((tone(f, length, volume, "warm") for f in freqs), start=np.zeros(int(length*RATE)))
    def melody(notes: list[float], spacing: float = .11, duration: float = .28) -> np.ndarray:
        out = np.zeros(int((len(notes)*spacing+duration)*RATE))
        for i, f in enumerate(notes):
            sig = tone(f, duration, .24, "warm")*np.exp(-np.arange(int(duration*RATE))/RATE*7)
            start = int(i*spacing*RATE)
            out[start:start+len(sig)] += sig
        return out
    for name, freqs in {"ui_click":[780], "ui_back":[660,440], "ui_tab":[420,630], "ui_confirm":[660,880], "upgrade":[440,554.37,659.25,880], "reward":[523.25,659.25,783.99,1046.5], "unlock":[392,523.25,659.25,783.99], "mission_complete":[659.25,783.99,1046.5], "promotion":[392,523.25,659.25,783.99,1046.5], "coin_pickup":[1244.5,1567.98], "daily_gift":[523.25,783.99,1046.5], "finish":[523.25,659.25,783.99,1046.5,1318.5]}.items():
        save(name, melody(freqs, .045 if name.startswith('ui_') else .10, .12 if name.startswith('ui_') else .28))
    save("ui_error", melody([180,150], .09, .20)*.6)
    save("countdown_tick", tone(880,.14,.22)*np.exp(-np.arange(int(.14*RATE))/RATE*18))
    save("countdown_go", chord([523.25,659.25,783.99],.45)*np.exp(-np.arange(int(.45*RATE))/RATE*5))
    rng = np.random.default_rng(1988)
    # Periodic engine loops have integer harmonics, so PCM wrap introduces no waveform jump.
    for name, base in [("engine_idle_loop",48),("engine_race_loop",96)]:
        t = np.arange(4*RATE)/RATE
        signal = sum((.14/h)*np.sin(2*np.pi*base*h*t+np.sin(2*np.pi*2*t)*.3) for h in range(1,9))
        signal *= .88+.12*np.cos(2*np.pi*4*t)
        save(name, signal, True)
    t = np.arange(int(.6*RATE))/RATE
    save("car_pass", rng.standard_normal(len(t))*.065*np.sin(np.pi*t/.6)**2 + np.sin(2*np.pi*(170*t-55*t*t))*.16*np.sin(np.pi*t/.6)**2)
    t = np.arange(int(.32*RATE))/RATE
    save("tyre_squeak", (np.sin(2*np.pi*(1350*t+200*t*t))*.08+rng.standard_normal(len(t))*.015)*np.sin(np.pi*t/.32)**2)
    # Two composed 16-bar loops, 120 BPM, 4/4. Chords C/Am/F/G; different arrangement each.
    # All notes/percussion are original synthesized sounds. No external samples or melodies.
    bpm, bars = 120, 16
    beat, length = 60/bpm, bars*4*60/bpm
    chords = [[48,52,55],[45,48,52],[41,45,48],[43,47,50]]
    midi = lambda n: 440*2**((n-69)/12)
    for name, race in [("music_workshop_loop", False),("music_race_loop", True)]:
        stereo = np.zeros((int(length*RATE),2), dtype=np.float64)
        def mix(sig: np.ndarray, start_sec: float, pan: float = 0.0):
            start = int(round(start_sec*RATE))
            gains = np.array([math.sqrt((1-pan)/2), math.sqrt((1+pan)/2)])
            # Circular mixing preserves release tails across the loop boundary.
            indices = (start+np.arange(len(sig))) % len(stereo)
            stereo[indices] += sig[:,None]*gains
        for bar in range(bars):
            notes = chords[(bar//2)%4]
            for step in range(8):
                n = notes[[0,1,2,1,0,2,1,2][step]]+24+(12 if race and step%4==3 else 0)
                dur = .22 if race else .36
                sig = tone(midi(n),dur,.058 if race else .065,"warm")*np.exp(-np.arange(int(dur*RATE))/RATE*8)
                mix(sig,(bar*4+step*.5)*beat, -.28 if step%2 else .28)
            for b in range(4):
                mix(tone(midi(notes[0]-12),.31,.15,"bass"),(bar*4+b)*beat)
                kickdur = .18
                tt=np.arange(int(kickdur*RATE))/RATE
                kick=np.sin(2*np.pi*(45*tt+3*(1-np.exp(-tt*35))))*np.exp(-tt*22)*(.20 if race else .13)
                if race or b%2==0:
                    mix(kick,(bar*4+b)*beat)
                if b%2:
                    tt=np.arange(int(.14*RATE))/RATE
                    snare=rng.standard_normal(len(tt))*.055*np.exp(-tt*35)
                    mix(snare,(bar*4+b)*beat,.12)
            for h in range(16 if race else 8):
                tt=np.arange(int(.045*RATE))/RATE
                hat=rng.standard_normal(len(tt))*.015*np.exp(-tt*100)
                mix(hat,(bar*4+h*(.25 if race else .5))*beat, -.25)
        save(name, stereo, True)
    write("audio/catalog.json",json.dumps(records,indent=2)+"\n")
    write("audio/default_bus_layout.tres", '''[gd_resource type="AudioBusLayout" format=3]

[resource]
bus/0/name = &"Master"
bus/0/volume_db = -3.0
bus/1/name = &"Music"
bus/1/send = &"Master"
bus/1/volume_db = -10.0
bus/2/name = &"SFX"
bus/2/send = &"Master"
bus/2/volume_db = -6.0
bus/3/name = &"Engine"
bus/3/send = &"Master"
bus/3/volume_db = -15.0
''')
    return records


def copy_sources(args: argparse.Namespace) -> None:
    for key, dest in [("pine","textures/pine_circuit.png"),("city","textures/city_technical.png"),("drivers","atlases/drivers_extra.png"),("props","atlases/workshop_props.png"),("rewards","atlases/rewards.png")]:
        source = getattr(args, key)
        if source:
            (ROOT/dest).parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source,ROOT/dest)
    if (ROOT/"atlases/drivers_extra.png").exists():
        with Image.open(ROOT/"atlases/drivers_extra.png") as im:
            for i,name in enumerate(["binh","chi"]):
                box = (i*im.width//2,0,(i+1)*im.width//2,im.height)
                region=alpha_bounds(im,box,8)
                atlas_resource(f"portraits/driver_{name}.tres","atlases/drivers_extra.png",region)
        atlas_resource("portraits/driver_binh_avatar.tres","atlases/drivers_extra.png",(320,0,460,510))
        atlas_resource("portraits/driver_chi_avatar.tres","atlases/drivers_extra.png",(1410,0,430,510))
    atlas_resource("portraits/driver_an.tres","portraits/driver_orange.png",(0,0,1254,1254))
    for atlas, ids in [("workshop_props",["garage","grandstand","pine","broadleaf","barrier","tyre_stack","tool_cabinet","light_pole"]),("rewards",["rookie_cup","semi_pro_cup","pro_cup","daily_gift","toolbox","money_bag","finish_flags","venue_model"])]:
        src=ROOT/f"atlases/{atlas}.png"
        if not src.exists():
            continue
        with Image.open(src) as im:
            for i,name in enumerate(ids):
                x,y=i%4,i//4
                box=(x*im.width//4,y*im.height//2,(x+1)*im.width//4,(y+1)*im.height//2)
                # Measure significant disconnected alpha components; ignore tiny neighboring
                # specks at cell edges. This changes only the AtlasTexture rectangle.
                alpha=np.asarray(im.getchannel('A'))[box[1]:box[3],box[0]:box[2]]
                labels,n=ndimage.label(alpha>24)
                areas=np.bincount(labels.ravel())
                areas[0]=0
                keep=areas>max(80,int(areas.max()*.001))
                yy,xx=np.where(keep[labels])
                region=(max(box[0],box[0]+int(xx.min())-8),max(box[1],box[1]+int(yy.min())-8),0,0)
                right=min(box[2],box[0]+int(xx.max())+9)
                bottom=min(box[3],box[1]+int(yy.max())+9)
                region=(region[0],region[1],right-region[0],bottom-region[1])
                atlas_resource(f"{'props' if atlas=='workshop_props' else 'rewards'}/{name}.tres",f"atlases/{atlas}.png",region)


def inventory(icons: list[str], audio: list[dict]) -> None:
    write('manifest.json',json.dumps({'name':'Workshop GP','version':'1.0','catalog':'asset_catalog.json','inventory':'manifest_complete.json','coverage':'ASSET_COVERAGE.md','asset_type':'2D','source_rasters_edited':False},indent=2)+'\n')
    files=[]
    for path in sorted(ROOT.rglob('*')):
        if not path.is_file() or any(p.startswith('.') or p=='__pycache__' for p in path.relative_to(ROOT).parts) or path.suffix in ['.import','.uid'] or path.name in ['manifest_complete.json']:
            continue
        relative=path.relative_to(ROOT).as_posix()
        entry={"path":relative,"bytes":path.stat().st_size,"sha256":hashlib.sha256(path.read_bytes()).hexdigest()}
        if path.suffix=='.png':
            with Image.open(path) as im:
                entry.update(width=im.width,height=im.height,mode=im.mode)
                if 'A' in im.getbands():
                    entry['transparent_pixels']=im.getchannel('A').histogram()[0]
        files.append(entry)
    write('manifest_complete.json',json.dumps({"name":"Workshop GP","version":"1.0","scope":"2D MVP art and audio; 3 tracks, 3 drivers, 8 cars, 5 tabs and supporting dialogs", "source_rasters_edited":False, "vector_icon_ids":icons,"audio":audio,"files":files},indent=2,ensure_ascii=False)+'\n')
    print(f'Complete inventory: {len(files)} files, {len(icons)} vector icons in two colorways, {len(audio)} WAVs')


def main() -> None:
    parser=argparse.ArgumentParser()
    for key in ['pine','city','drivers','props','rewards']:
        parser.add_argument('--'+key,type=Path)
    parser.add_argument('--inventory-only',action='store_true')
    args=parser.parse_args()
    if not args.inventory_only:
        copy_sources(args)
        icons=make_icons()
        make_ui()
        make_vfx()
        make_components_and_paths()
        audio=make_audio()
    else:
        icons=[p.stem for p in sorted((ROOT/'icons/vector').glob('*.svg'))]
        audio=json.loads((ROOT/'audio/catalog.json').read_text())
    inventory(icons,audio)


if __name__=='__main__':
    main()
