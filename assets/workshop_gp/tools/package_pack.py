"""Package the verified sources and clean gallery project. Excludes import caches.

Run from repository: python assets/workshop_gp/tools/package_pack.py --preview-project PATH
"""
from __future__ import annotations

import argparse
import hashlib
import json
import zipfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
REPO=ROOT.parents[1]


def main() -> None:
    parser=argparse.ArgumentParser()
    parser.add_argument('--preview-project',type=Path,required=True)
    parser.add_argument('--output',type=Path,default=REPO/'Design/AssetPacks/Workshop_GP_2D_Complete_v1.0.zip')
    args=parser.parse_args()
    manifest=json.loads((ROOT/'manifest_complete.json').read_text())
    for entry in manifest['files']:
        path=ROOT/entry['path']
        assert path.is_file() and hashlib.sha256(path.read_bytes()).hexdigest()==entry['sha256'],entry['path']
    project=(args.preview_project/'project.godot').read_text(encoding='utf-8')
    assert 'autoload' not in project and 'asset_gallery.tscn' in project
    output=args.output.resolve()
    output.parent.mkdir(parents=True,exist_ok=True)
    previews=REPO/'Design/Previews/Workshop_GP_Complete'
    assert (previews/'ASSET_CATALOG.png').is_file() and (previews/'OVERVIEW.png').is_file()
    start='''# Workshop GP — Complete 2D MVP Asset Pack 1.0

1. Giải nén vào một thư mục mới.
2. Mở `project.godot` bằng Godot 4.7.2 và Run để xem gallery độc lập.
3. Dùng menu đầu màn hình để chọn 12 màn; năm tab dưới tương ứng MVP.
4. Vào Cài đặt → Thư viện asset & âm thanh để nghe từng cue và xem VFX.

- Hướng dẫn: [assets/workshop_gp/README.md](assets/workshop_gp/README.md)
- Danh mục: [asset_catalog.json](assets/workshop_gp/asset_catalog.json)
- Phủ nội dung: [ASSET_COVERAGE.md](assets/workshop_gp/ASSET_COVERAGE.md)
- Kiểm tra: [QA.md](assets/workshop_gp/QA.md)
- Toàn bộ hình: [ASSET_CATALOG.png](Previews/ASSET_CATALOG.png)
- Các màn UI: [OVERVIEW.png](Previews/OVERVIEW.png)

Để tích hợp vào dự án đang có, sao chép thư mục `assets/workshop_gp` và nối các signal/data với gameplay của dự án đó. File project ở gói này chỉ dành cho gallery riêng. Không cần Python để sử dụng asset.

Asset 2D phong cách render 3D; không có model 3D. Các số liệu/kết quả trong gallery là minh họa duyệt UI. Xem hướng dẫn cho API card, dialog, track, audio và VFX.
'''
    entries=[]
    with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
        archive.writestr('project.godot',project)
        archive.writestr('START_HERE.md',start)
        for path in sorted(ROOT.rglob('*')):
            if not path.is_file() or path.suffix in ['.import','.uid','.pyc'] or any(p.startswith('.') or p=='__pycache__' for p in path.relative_to(ROOT).parts):
                continue
            name='assets/workshop_gp/'+path.relative_to(ROOT).as_posix()
            archive.write(path,name)
            entries.append(name)
        for path in sorted(previews.rglob('*.png')):
            archive.write(path,'Previews/'+path.relative_to(previews).as_posix())
        for path in sorted(previews.glob('native_validation_*.log')):
            text=path.read_text(encoding='utf-8')
            assert 'failures=0' in text and 'ERROR:' not in text,path
            archive.write(path,'QA/'+path.name)
        archive.write(previews/'asset_validation.json','QA/asset_validation.json')
    with zipfile.ZipFile(output) as archive:
        assert archive.testzip() is None,'ZIP CRC error'
        assert len(archive.namelist())==len(set(archive.namelist())),'Duplicate ZIP paths'
        archive_count=len(archive.namelist())
    digest=hashlib.sha256(output.read_bytes()).hexdigest()
    output.with_suffix('.sha256').write_text(digest+'  '+output.name+'\n',encoding='ascii')
    report={'path':str(output),'bytes':output.stat().st_size,'sha256':digest,'archive_files':archive_count,'source_files':len(entries),'crc':'PASS','manifest_hashes':'PASS'}
    output.with_suffix('.delivery.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2))


if __name__=='__main__':
    main()
