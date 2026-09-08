#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
publicar.py — Sustituye datos.json en el repositorio y lo sube a GitHub.

Uso:
    python publicar.py                      # sube el datos.json que ya está en la carpeta
    python publicar.py ~/Downloads/datos.json   # copia ese fichero encima y lo sube
    python publicar.py --auto               # busca el datos.json más reciente en Descargas

Antes de nada, comprueba que el JSON es válido y que trae lo que debe traer:
si algo está mal, no sube nada, para no dejar la web del club en blanco.
"""

import json, os, shutil, subprocess, sys, time
from pathlib import Path

REPO = Path(__file__).resolve().parent
DESTINO = REPO / "datos.json"


def fin(msg, codigo=1):
    print(f"\n  {msg}\n")
    if os.name == "nt":
        input("  Pulsa Intro para cerrar... ")
    sys.exit(codigo)


def git(*args, permitir_fallo=False):
    r = subprocess.run(["git", *args], cwd=REPO, capture_output=True, text=True)
    if r.returncode and not permitir_fallo:
        fin(f"El comando «git {' '.join(args)}» ha fallado:\n\n{r.stderr.strip()}")
    return r.stdout.strip()


def descargas():
    for nombre in ("Downloads", "Descargas"):
        d = Path.home() / nombre
        if d.is_dir():
            yield d


def buscar_reciente():
    candidatos = []
    for d in descargas():
        candidatos += list(d.glob("datos*.json"))
    if not candidatos:
        fin("No encuentro ningún datos.json en tu carpeta de Descargas.\n"
            "  Pásame la ruta a mano:  python publicar.py /ruta/al/datos.json")
    return max(candidatos, key=lambda p: p.stat().st_mtime)


def validar(ruta):
    try:
        d = json.loads(ruta.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        fin(f"Ese fichero no es JSON válido: {e}\n  No subo nada, para no romper la web.")
    except UnicodeDecodeError:
        fin("El fichero no está en UTF-8. Vuelve a descargarlo sin abrirlo con Word ni similares.")

    if not isinstance(d.get("partidos"), list) or not d["partidos"]:
        fin('El JSON no tiene la lista "partidos". No subo nada.')
    if not isinstance(d.get("clasificacion"), list) or not d["clasificacion"]:
        fin('El JSON no tiene la lista "clasificacion". No subo nada.')
    if len(d["partidos"]) != 34:
        print(f"  AVISO: hay {len(d['partidos'])} partidos en vez de 34. Sigo, pero revísalo.")
    if len(d["clasificacion"]) != 18:
        print(f"  AVISO: hay {len(d['clasificacion'])} equipos en vez de 18. Sigo, pero revísalo.")

    jugados = sum(1 for p in d["partidos"] if isinstance(p.get("gf"), int))
    return d, jugados


def main():
    print("\n  CDC Moscardó · publicar datos\n")

    if not (REPO / ".git").is_dir():
        fin("Esta carpeta no es el repositorio de git.\n"
            "  Coloca publicar.py dentro de la carpeta moscardo-web que clonaste de GitHub.")

    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    auto = "--auto" in sys.argv

    if auto:
        origen = buscar_reciente()
        print(f"  · usando el más reciente de Descargas: {origen.name}")
    elif args:
        origen = Path(args[0]).expanduser()
        if not origen.exists():
            fin(f"No existe el fichero {origen}")
    else:
        origen = DESTINO
        if not origen.exists():
            fin("No hay datos.json en esta carpeta y no me has dicho cuál usar.")

    datos, jugados = validar(origen)
    print(f"  · JSON correcto: {len(datos['partidos'])} partidos, "
          f"{len(datos['clasificacion'])} equipos, {jugados} jornadas disputadas")

    if origen.resolve() != DESTINO.resolve():
        copia = DESTINO.with_suffix(".json.anterior")
        if DESTINO.exists():
            shutil.copy2(DESTINO, copia)
        shutil.copy2(origen, DESTINO)
        print(f"  · datos.json sustituido (copia de seguridad en {copia.name})")

    if not git("status", "--porcelain", "datos.json"):
        fin("El fichero es idéntico al que ya está publicado. No hay nada que subir.", 0)

    git("add", "datos.json")
    git("commit", "-m", f"Actualiza datos ({jugados} jornadas disputadas)")
    print("  · subiendo a GitHub")
    git("push")

    print(f"\n  Listo. En unos minutos la web del club mostrará los datos nuevos.")
    print(f"  Compruébalo en tu página de GitHub Pages.\n")
    if os.name == "nt":
        input("  Pulsa Intro para cerrar... ")


if __name__ == "__main__":
    main()
