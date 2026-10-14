"""Análise ESTÁTICA do Auras Pack e geração do relatório (AURAS_PACK_AUDIT.md + JSON).

Entrada: lista de instâncias {class, name, path, parent, props, source?} vinda do Lune
(tools/packaudit/auras_dump.luau) ou do leitor tolerante (rbxm_reader.py). O código dos scripts
é tratado como DADO: aqui só se calcula tamanho, SHA-256 e presença de padrões de risco; o texto
nunca vai para o relatório. Nada é baixado, executado ou requerido.
"""
from __future__ import annotations

import hashlib
import json
import re
from collections import Counter, defaultdict

EXEC = {"Script", "LocalScript", "ModuleScript"}
REMOTES = {"RemoteEvent", "RemoteFunction", "UnreliableRemoteEvent"}
BINDABLES = {"BindableEvent", "BindableFunction"}
MOVERS = {
    "BodyVelocity", "BodyPosition", "BodyGyro", "BodyForce", "BodyAngularVelocity", "BodyThrust", "RocketPropulsion",
    "LinearVelocity", "AngularVelocity", "VectorForce", "AlignPosition", "AlignOrientation", "Torque",
}
JOINTS = {"Weld", "WeldConstraint", "Motor6D", "ManualWeld", "Snap"}
LIGHTS = {"PointLight", "SpotLight", "SurfaceLight"}
SURFACES = {"Decal", "Texture", "SurfaceAppearance"}
MESHES = {"MeshPart", "SpecialMesh", "FileMesh", "BlockMesh", "CylinderMesh"}
LEGACY_VFX = {"Fire", "Smoke", "Sparkles", "Highlight"}
CATALOG = [
    "Script", "LocalScript", "ModuleScript", "RemoteEvent", "RemoteFunction", "UnreliableRemoteEvent",
    "BindableEvent", "BindableFunction", "ParticleEmitter", "Beam", "Trail", "Attachment", "PointLight",
    "SpotLight", "SurfaceLight", "Sound", "Animation", "Animator", "Humanoid", "AnimationController",
    "BodyVelocity", "BodyPosition", "BodyGyro", "BodyForce", "BodyAngularVelocity", "BodyThrust",
    "LinearVelocity", "AngularVelocity", "VectorForce", "AlignPosition", "AlignOrientation", "Weld",
    "WeldConstraint", "Motor6D", "MeshPart", "SpecialMesh", "Decal", "Texture", "Model", "Folder", "Part",
    "Fire", "Smoke", "Sparkles", "Highlight",
]
# propriedade -> tipo de asset
ASSET_PROPS = {
    "Texture": "Image", "TextureID": "Image", "TextureId": "Image", "Image": "Image", "Graphic": "Image",
    "ShirtTemplate": "Clothing", "PantsTemplate": "Clothing", "MeshId": "Mesh", "SoundId": "Audio",
    "AnimationId": "Animation",
    # tipos Content novos (Studio 2024+): mesmo asset, outro nome de propriedade
    "AudioContent": "Audio", "MeshContent": "Mesh", "TextureContent": "Image", "ColorMapContent": "Image",
    "AnimationContent": "Animation",
}
ID_RE = re.compile(r"(?:rbxassetid://|[?&]id=)(\d+)|^(\d{5,})$", re.I)
CODE_ID_RE = re.compile(r"rbxassetid://(\d+)|[?&]id=(\d+)|\brequire\s*\(\s*(\d{5,})\s*\)")
# padrões de risco procurados no código (como texto)
CODE_FLAGS = {
    "require(número) — módulo remoto": re.compile(r"\brequire\s*\(\s*\d{5,}\s*\)"),
    "loadstring": re.compile(r"\bloadstring\b"),
    "getfenv/setfenv": re.compile(r"\b(?:getfenv|setfenv)\b"),
    "HttpService": re.compile(r"HttpService"),
    "InsertService": re.compile(r"InsertService"),
    "MarketplaceService": re.compile(r"MarketplaceService"),
    "TeleportService": re.compile(r"TeleportService"),
    "Kick()": re.compile(r":\s*Kick\s*\("),
    "rede (FireServer/OnServerEvent/InvokeServer)": re.compile(r"FireServer|OnServerEvent|InvokeServer|OnServerInvoke|FireClient|FireAllClients"),
    "ofuscação (string.char / \\x / escape numérico longo)": re.compile(r"string\.char\s*\(|(?:\\x[0-9a-fA-F]{2}){8,}|(?:\\\d{2,3}){12,}"),
    "mexe no personagem do jogador (LocalPlayer/Character)": re.compile(r"LocalPlayer|\.Character\b|CharacterAdded"),
}
GROUPS = [
    ("Electric", r"electr|lightning|thunder|volt|shock|zap|raio|storm"),
    ("Flame", r"fire|flame|burn|blaze|inferno|ember|fogo|magma|lava|heat"),
    ("Void", r"void|abyss|black ?hole|cosmic|galax|nebula|vazio"),
    ("Dark", r"dark|shadow|evil|demon|curse|sombr|corrupt"),
    ("Celestial", r"celest|holy|angel|divine|heaven|god|sacred|star|light ?aura|luz"),
    ("Smoke", r"smoke|mist|fog|fuma|cloud|steam"),
    ("Halos", r"halo"),
    ("Rings", r"ring|circle|anel"),
    ("Ground", r"ground|floor|shockwave|crater|chão|impact"),
    ("Orbit", r"orbit|spin|rotat|swirl|vortex"),
    ("Energy", r"energ|power|ki\b|chakra|aura|spirit|mana|plasma"),
    ("Beams", r"beam"),
    ("Trails", r"trail"),
]


def _norm_id(value) -> str | None:
    if not isinstance(value, str) or not value.strip():
        return None
    v = value.strip()
    if v.startswith("rbxasset://"):
        return None  # textura nativa do Roblox (não é asset externo)
    m = ID_RE.search(v)
    if m:
        return m.group(1) or m.group(2)
    return v[:120]


def _num(v, default=0.0) -> float:
    if isinstance(v, (int, float)) and not isinstance(v, bool):
        return float(v)
    if isinstance(v, list) and v and isinstance(v[-1], (int, float)):
        return float(v[-1])
    return default


def analyze(instances: list[dict], read_info: dict) -> dict:
    by_class: Counter = Counter(i["class"] for i in instances)
    children: dict[int | None, list[int]] = defaultdict(list)
    for idx, inst in enumerate(instances, start=1):
        children[inst.get("parent")].append(idx)

    def ancestors(idx: int):
        p = instances[idx - 1].get("parent")
        while p:
            yield p
            p = instances[p - 1].get("parent")

    def entry(inst: dict, extra: dict | None = None) -> dict:
        out = {"class": inst["class"], "name": inst["name"], "path": inst["path"]}
        if extra:
            out.update(extra)
        return out

    scripts, remotes, bindables, sounds, animations, movers, joints = [], [], [], [], [], [], []
    emitters, beams, trails, attachments, lights, surfaces, meshes, legacy, humanoids = [], [], [], [], [], [], [], [], []
    assets: dict[str, dict] = {}

    def add_asset(asset_id: str, kind: str, where: str) -> None:
        a = assets.setdefault(asset_id, {"id": asset_id, "types": [], "uses": 0, "paths": []})
        if kind not in a["types"]:
            a["types"].append(kind)
        a["uses"] += 1
        if where not in a["paths"]:
            a["paths"].append(where)

    for inst in instances:
        cls, props = inst["class"], inst.get("props", {})
        for prop, kind in ASSET_PROPS.items():
            aid = _norm_id(props.get(prop))
            if aid:
                add_asset(aid, kind, f"{inst['path']}.{prop}")
        if cls in EXEC:
            source = inst.get("source") or ""
            raw = source.encode("utf-8", errors="replace")
            flags = sorted(name for name, rx in CODE_FLAGS.items() if rx.search(source))
            code_ids = sorted({a or b or c for a, b, c in CODE_ID_RE.findall(source)})
            for aid in code_ids:
                add_asset(aid, "CodeRef", inst["path"] + " (texto do código)")
            disabled = props.get("Disabled")
            if disabled is None and isinstance(props.get("Enabled"), bool):
                disabled = not props["Enabled"]
            scripts.append(entry(inst, {
                "disabled": disabled, "runContext": props.get("RunContext"), "bytes": len(raw),
                "lines": source.count("\n") + (1 if source else 0), "sha256": hashlib.sha256(raw).hexdigest(),
                "flags": flags, "assetRefsInCode": code_ids, "trust": "UNTRUSTED",
            }))
        elif cls in REMOTES:
            remotes.append(entry(inst))
        elif cls in BINDABLES:
            bindables.append(entry(inst))
        elif cls == "Sound":
            sounds.append(entry(inst, {"soundId": props.get("SoundId") or props.get("AudioContent"), "looped": props.get("Looped"), "volume": props.get("Volume")}))
        elif cls in ("Animation", "Animator", "AnimationController"):
            animations.append(entry(inst, {"animationId": props.get("AnimationId") or props.get("AnimationContent")}))
        elif cls in MOVERS or "Constraint" in cls and cls != "WeldConstraint":
            movers.append(entry(inst))
        elif cls in JOINTS:
            joints.append(entry(inst, {"part0": props.get("Part0"), "part1": props.get("Part1")}))
        elif cls == "ParticleEmitter":
            rate = _num(props.get("Rate"))
            life = _num(props.get("Lifetime"))
            size = _num(props.get("Size"), 1.0)
            transp = min(max(_num(props.get("Transparency")), 0.0), 1.0)
            emitters.append(entry(inst, {
                "texture": props.get("Texture"), "rate": rate, "lifetime": props.get("Lifetime"), "size": props.get("Size"),
                "transparency": props.get("Transparency"), "speed": props.get("Speed"), "lightEmission": props.get("LightEmission"),
                "color": props.get("Color"), "lockedToPart": props.get("LockedToPart"), "enabled": props.get("Enabled"),
                "presence": round(rate * life * size * (1 - transp), 2),
            }))
        elif cls == "Beam":
            beams.append(entry(inst, {k: props.get(k) for k in ("Texture", "Width0", "Width1", "LightEmission", "Segments", "Attachment0", "Attachment1", "Color")}))
        elif cls == "Trail":
            trails.append(entry(inst, {k: props.get(k) for k in ("Texture", "Lifetime", "LightEmission", "WidthScale", "Attachment0", "Attachment1", "Color")}))
        elif cls == "Attachment":
            attachments.append(entry(inst, {"position": props.get("Position")}))
        elif cls in LIGHTS:
            lights.append(entry(inst, {"brightness": props.get("Brightness"), "range": props.get("Range"), "color": props.get("Color"), "shadows": props.get("Shadows")}))
        elif cls in SURFACES:
            surfaces.append(entry(inst, {"texture": props.get("Texture") or props.get("TextureContent")}))
        elif cls in MESHES:
            meshes.append(entry(inst, {"meshId": props.get("MeshId") or props.get("MeshContent"), "textureId": props.get("TextureID") or props.get("TextureId") or props.get("TextureContent")}))
        elif cls in LEGACY_VFX:
            legacy.append(entry(inst))
        elif cls == "Humanoid":
            humanoids.append(entry(inst))

    # ---------------- grupos de aura (estrutural: nomes + componentes) ----------------
    roots = children[None]
    group_roots: list[int] = []
    for r in roots:
        kids = children[r]
        # pack = 1 contêiner com várias auras dentro -> cada filho é uma aura
        if len(roots) == 1 and kids:
            group_roots.extend(kids)
        else:
            group_roots.append(r)

    def subtree(idx: int) -> list[int]:
        out, stack = [], [idx]
        while stack:
            n = stack.pop()
            out.append(n)
            stack.extend(children[n])
        return out

    groups = []
    for g in group_roots:
        nodes = subtree(g)
        cls_count = Counter(instances[n - 1]["class"] for n in nodes)
        names = " ".join(instances[n - 1]["name"] for n in nodes).lower()
        root_name = instances[g - 1]["name"]
        tags = [label for label, rx in GROUPS if re.search(rx, root_name.lower())]
        if not tags:
            tags = [label for label, rx in GROUPS if re.search(rx, names)]
        if cls_count["Beam"] and "Beams" not in tags and cls_count["Beam"] >= max(1, cls_count["ParticleEmitter"]):
            tags.append("Beams")
        if cls_count["Trail"] and "Trails" not in tags:
            tags.append("Trails")
        vfx = cls_count["ParticleEmitter"] + cls_count["Beam"] + cls_count["Trail"] + sum(cls_count[c] for c in LEGACY_VFX)
        textures = sorted({_norm_id(instances[n - 1].get("props", {}).get("Texture")) or "" for n in nodes if instances[n - 1]["class"] in ("ParticleEmitter", "Beam", "Trail", "Decal", "Texture")} - {""})
        n_scripts = sum(cls_count[c] for c in EXEC)
        n_net = sum(cls_count[c] for c in REMOTES | BINDABLES)
        n_movers = sum(v for c, v in cls_count.items() if c in MOVERS or ("Constraint" in c and c != "WeldConstraint"))
        deps = []
        if n_scripts:
            deps.append(f"{n_scripts} script(s)")
        if n_net:
            deps.append(f"{n_net} remote/bindable")
        if textures:
            deps.append(f"{len(textures)} textura(s) externa(s)")
        if cls_count["Sound"]:
            deps.append(f"{cls_count['Sound']} som(ns)")
        if cls_count["Humanoid"] or cls_count["Animator"]:
            deps.append("Humanoid/Animator")
        risk = "ALTO" if (n_scripts or n_net or n_movers) else ("MÉDIO" if textures or cls_count["Sound"] or cls_count["Humanoid"] else "BAIXO")
        if vfx == 0:
            continue  # sem efeito visual (script/remote solto, pasta vazia): fica nas outras seções
        groups.append({
            "name": root_name, "path": instances[g - 1]["path"], "class": instances[g - 1]["class"],
            "style": tags[0] if tags else "Não classificado", "tags": tags or ["Não classificado"],
            "instances": len(nodes), "emitters": cls_count["ParticleEmitter"], "attachments": cls_count["Attachment"],
            "beams": cls_count["Beam"], "trails": cls_count["Trail"], "lights": sum(cls_count[c] for c in LIGHTS),
            "textures": textures, "scripts": n_scripts, "remotesBindables": n_net, "movers": n_movers,
            "dependencies": deps, "risk": risk,
        })

    # ---------------- reutilizáveis × proibidos ----------------
    script_owners = set()
    for idx, inst in enumerate(instances, start=1):
        if inst["class"] in EXEC:
            script_owners.add(inst.get("parent"))
    reusable = sorted(
        [e for e in emitters] + [dict(b, presence=5) for b in beams] + [dict(t, presence=4) for t in trails],
        key=lambda e: -(e.get("presence") or 0),
    )
    forbidden = (
        [dict(s, motivo="código executável (UNTRUSTED)") for s in scripts]
        + [dict(r, motivo="remote: superfície de rede") for r in remotes]
        + [dict(b, motivo="bindable: acoplamento a scripts do pack") for b in bindables]
        + [dict(m, motivo="body mover/constraint: física/movimento") for m in movers]
        + [dict(h, motivo="Humanoid: pode afetar avatar/rig") for h in humanoids]
        + [dict(s, motivo="som: proveniência/direito de uso de áudio") for s in sounds]
    )

    risks = []
    if scripts:
        flagged = [s for s in scripts if s["flags"]]
        risks.append(f"{len(scripts)} script(s) no pack (UNTRUSTED). {len(flagged)} com padrões sensíveis: "
                     + (", ".join(sorted({f for s in flagged for f in s["flags"]})) or "nenhum"))
    if remotes or bindables:
        risks.append(f"{len(remotes)} remote(s) e {len(bindables)} bindable(s): superfície de rede/acoplamento — nunca integrar.")
    if movers:
        risks.append(f"{len(movers)} body mover(s)/constraint(s): podem mover o personagem — nunca integrar.")
    if humanoids:
        risks.append(f"{len(humanoids)} Humanoid(s): o pack foi feito para AVATAR; no Roll Legends aura é só de personagem colecionável.")
    if assets:
        risks.append(f"{len(assets)} asset ID(s) externos: proveniência/direito de uso NÃO verificados (nome do pack diz \"Not mine\").")
    if sounds:
        risks.append(f"{len(sounds)} som(ns): áudio de terceiros tem regras próprias de uso.")
    heavy = [e for e in emitters if e["rate"] > 100]
    if heavy:
        risks.append(f"{len(heavy)} emissor(es) com Rate > 100/s: acima do orçamento por aura do jogo (AuraConfig.Budget).")
    if read_info.get("structuralErrors"):
        risks.append("Corrupção estrutural detectada: " + "; ".join(read_info["structuralErrors"]))

    totals = {
        "instances": len(instances), "scripts": len(scripts), "remotes": len(remotes), "bindables": len(bindables),
        "particleEmitters": len(emitters), "beams": len(beams), "trails": len(trails), "attachments": len(attachments),
        "lights": len(lights), "sounds": len(sounds), "animations": len(animations), "moversConstraints": len(movers),
        "joints": len(joints), "meshes": len(meshes), "surfaces": len(surfaces), "legacyVfx": len(legacy),
        "humanoids": len(humanoids), "assetIds": len(assets), "groups": len(groups),
    }
    return {
        "read": read_info, "totals": totals, "classes": dict(sorted(by_class.items())),
        "catalog": {c: by_class.get(c, 0) for c in CATALOG},
        "scripts": scripts, "remotes": remotes, "bindables": bindables, "sounds": sounds, "animations": animations,
        "moversConstraints": movers, "joints": joints, "emitters": emitters, "beams": beams, "trails": trails,
        "attachments": attachments, "lights": lights, "surfaces": surfaces, "meshes": meshes, "legacyVfx": legacy,
        "assets": sorted(assets.values(), key=lambda a: (-a["uses"], a["id"])),
        "hierarchy": _hierarchy(instances, children),
        "groups": groups, "reusable": reusable, "forbidden": forbidden, "risks": risks,
        "verdict": {
            "safeTechnically": "PARCIAL: só parâmetros de ParticleEmitter/Beam/Trail/Attachment/Light, recriados pelo AuraBuilder com texturas nativas; scripts/remotes/movers/Humanoid nunca.",
            "provenanceVerified": False,
            "integrated": False,
        },
    }


def _hierarchy(instances: list[dict], children: dict, max_depth: int = 4, max_kids: int = 12) -> list[str]:
    lines: list[str] = []

    def walk(idx: int, depth: int) -> None:
        inst = instances[idx - 1]
        kids = children[idx]
        lines.append(f"{'  ' * depth}- {inst['name']} ({inst['class']})" + (f" [{len(kids)} filhos]" if kids and depth == max_depth else ""))
        if depth >= max_depth:
            return
        for k in kids[:max_kids]:
            walk(k, depth + 1)
        if len(kids) > max_kids:
            rest = Counter(instances[k - 1]["class"] for k in kids[max_kids:])
            lines.append(f"{'  ' * (depth + 1)}- … +{len(kids) - max_kids} ({', '.join(f'{c}×{n}' for c, n in rest.most_common())})")

    for r in children[None]:
        walk(r, 0)
    return lines


def _fmt(v) -> str:
    if v is None:
        return "—"
    if isinstance(v, float):
        return f"{v:.2f}"
    if isinstance(v, list):
        return "[" + ", ".join(_fmt(x) for x in v) + "]"
    return str(v).replace("|", "\\|")


def write_markdown(rep: dict, path: str, source_label: str) -> None:
    out: list[str] = []
    L = out.append
    read, totals = rep["read"], rep["totals"]

    def section(n: int, title: str) -> None:
        L("")
        L(f"## {n}. {title}")
        L("")

    def table(rows: list[dict], cols: list[tuple[str, str]], limit: int = 60) -> None:
        if not rows:
            L("Nenhum.")
            return
        L("| " + " | ".join(h for h, _ in cols) + " |")
        L("|" + "---|" * len(cols))
        for r in rows[:limit]:
            L("| " + " | ".join(_fmt(r.get(k)) for _, k in cols) + " |")
        if len(rows) > limit:
            L(f"\n… +{len(rows) - limit} (lista completa em `third_party/auras_pack_report.json`)")

    L("# Auditoria — Auras Pack (\"Not mine!\", Creator Store 15374038687)")
    L("")
    L(f"> Gerado por `python tools/audit_auras_pack.py` a partir de `{source_label}`, de forma 100% ESTÁTICA:")
    L("> nenhum script do pack foi executado ou requerido, nada foi baixado e o arquivo original não foi")
    L("> modificado (SHA-256 conferido antes/depois). O pack NÃO está integrado ao jogo nem ao build.")

    section(1, "Resultado da leitura")
    L(f"- Status: **{read['status']}**")
    L(f"- Arquivo: `{source_label}` ({read.get('bytes', 0)} bytes, formato {read.get('format')})")
    L(f"- SHA-256 antes: `{read.get('sha256Before')}`")
    L(f"- SHA-256 depois: `{read.get('sha256After')}` ({'inalterado' if read.get('sha256Before') == read.get('sha256After') else 'ALTERADO!'})")
    section(2, "Parser usado")
    L(f"- Leitor final: **{read['reader']}**")
    for a in read.get("attempts", []):
        L(f"- Tentativa: {a}")
    section(3, "Fallback utilizado")
    L(read.get("fallback") or "Nenhum: o Lune leu o arquivo original direto.")
    section(4, "Warnings")
    if read.get("warnings"):
        for w in read["warnings"]:
            L(f"- WARNING: {w}")
    else:
        L("Nenhum.")
    section(5, "Propriedades incompatíveis ignoradas")
    inc = read.get("incompatibleProperties") or []
    if inc:
        for p in inc:
            L(f"- `{p}` — metadado não usado pela auditoria (removido só da cópia temporária)")
    else:
        L("Nenhuma.")
    if read.get("tolerantSkipped"):
        L("")
        L("Propriedades que o leitor tolerante não decodifica (irrelevantes para a auditoria):")
        for k, v in sorted(read["tolerantSkipped"].items())[:40]:
            L(f"- {k} ×{v}")
    section(6, "Total de Instances")
    L(f"**{totals['instances']}** instâncias (leitor tolerante contou {read.get('tolerantCount', '—')}).")
    L("")
    L("| Categoria | Total |")
    L("|---|---|")
    for k, v in totals.items():
        L(f"| {k} | {v} |")
    section(7, "Classes encontradas")
    L("| Classe | Quantidade |")
    L("|---|---|")
    for c, n in sorted(rep["classes"].items(), key=lambda x: (-x[1], x[0])):
        L(f"| {c} | {n} |")
    L("")
    L("Catálogo pedido (0 = ausente): " + ", ".join(f"{c} {n}" for c, n in rep["catalog"].items()))
    section(8, "Scripts (UNTRUSTED — nunca executados; código não reproduzido)")
    table(rep["scripts"], [("Classe", "class"), ("Nome", "name"), ("Caminho", "path"), ("Disabled", "disabled"), ("Bytes", "bytes"), ("Linhas", "lines"), ("SHA-256", "sha256"), ("Padrões", "flags")])
    section(9, "RemoteEvents / RemoteFunctions")
    table(rep["remotes"], [("Classe", "class"), ("Caminho", "path")])
    section(10, "BindableEvents / BindableFunctions")
    table(rep["bindables"], [("Classe", "class"), ("Caminho", "path")])
    section(11, "Sounds")
    table(rep["sounds"], [("Caminho", "path"), ("SoundId", "soundId"), ("Looped", "looped"), ("Volume", "volume")])
    section(12, "Animations / Animator")
    table(rep["animations"], [("Classe", "class"), ("Caminho", "path"), ("AnimationId", "animationId")])
    section(13, "BodyMovers / Constraints")
    table(rep["moversConstraints"], [("Classe", "class"), ("Caminho", "path")])
    if rep["joints"]:
        L("")
        L(f"Welds/Motor6D (estruturais): {len(rep['joints'])}")
    section(14, "ParticleEmitters (presença = taxa × vida × tamanho × opacidade)")
    table(sorted(rep["emitters"], key=lambda e: -e["presence"]), [("Presença", "presence"), ("Caminho", "path"), ("Textura", "texture"), ("Rate", "rate"), ("Lifetime", "lifetime"), ("Size", "size"), ("LightEmission", "lightEmission"), ("Cor", "color")])
    section(15, "Beams")
    table(rep["beams"], [("Caminho", "path"), ("Textura", "Texture"), ("Width0", "Width0"), ("Width1", "Width1"), ("Segments", "Segments"), ("A0", "Attachment0"), ("A1", "Attachment1")])
    section(16, "Trails")
    table(rep["trails"], [("Caminho", "path"), ("Textura", "Texture"), ("Lifetime", "Lifetime"), ("A0", "Attachment0"), ("A1", "Attachment1")])
    section(17, "Attachments")
    table(rep["attachments"], [("Caminho", "path"), ("Posição", "position")], limit=40)
    section(18, "Lights")
    table(rep["lights"], [("Classe", "class"), ("Caminho", "path"), ("Brightness", "brightness"), ("Range", "range"), ("Shadows", "shadows")])
    section(19, "Textures / Decals")
    table(rep["surfaces"], [("Classe", "class"), ("Caminho", "path"), ("Textura", "texture")])
    section(20, "Meshes")
    table(rep["meshes"], [("Classe", "class"), ("Caminho", "path"), ("MeshId", "meshId"), ("TextureId", "textureId")])
    section(21, "Asset IDs referenciados (nada foi baixado)")
    rows = [dict(a, types=", ".join(a["types"]), first=a["paths"][0] if a["paths"] else "") for a in rep["assets"]]
    table(rows, [("ID", "id"), ("Tipo", "types"), ("Usos", "uses"), ("Primeiro caminho", "first")], limit=80)
    section(22, "Hierarquia (resumo até 4 níveis)")
    L("```")
    out.extend(rep["hierarchy"][:300])
    L("```")
    section(23, "Grupos de aura (classificação estrutural)")
    table(rep["groups"], [("Grupo", "name"), ("Estilo", "style"), ("Tags", "tags"), ("Inst.", "instances"), ("Emitters", "emitters"), ("Attach.", "attachments"), ("Beams", "beams"), ("Trails", "trails"), ("Lights", "lights"), ("Texturas", "textures"), ("Scripts", "scripts"), ("Dependências", "dependencies"), ("Risco", "risk")])
    section(24, "Componentes potencialmente reutilizáveis (como REFERÊNCIA de parâmetros)")
    L("Só os parâmetros (taxa, vida, tamanho, cor, direção, camadas) servem de referência para o")
    L("AuraConfig/AuraBuilder; os objetos do pack não são copiados.")
    L("")
    table(rep["reusable"], [("Classe", "class"), ("Caminho", "path"), ("Presença", "presence")], limit=30)
    section(25, "Componentes proibidos (nunca integrar)")
    table(rep["forbidden"], [("Classe", "class"), ("Caminho", "path"), ("Motivo", "motivo")])
    section(26, "Riscos")
    for r in rep["risks"] or ["Nenhum risco estrutural encontrado."]:
        L(f"- {r}")
    section(27, "Conclusão")
    v = rep["verdict"]
    L(f"- **SEGURO TECNICAMENTE:** {v['safeTechnically']}")
    L(f"- **PROVENIÊNCIA/IP VERIFICADOS:** {'SIM' if v['provenanceVerified'] else 'NÃO'} — o nome do asset diz \"Not mine!\"; nenhum uso de texturas/sons/malhas do pack até confirmar o direito de uso.")
    L(f"- **INTEGRADO AO JOGO:** {'SIM' if v['integrated'] else 'NÃO'} — o sistema de auras do jogo é AuraConfig/AuraBuilder/AuraController, com texturas nativas (rbxasset://), aplicado só a personagens colecionáveis, nunca ao avatar do jogador.")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")


def write_json(rep: dict, path: str) -> None:
    with open(path, "w", encoding="utf-8") as f:
        json.dump(rep, f, ensure_ascii=False, indent=1)
