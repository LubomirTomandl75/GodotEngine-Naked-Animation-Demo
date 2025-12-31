# Naked Animation Demo
> Jednoduchá technická ukázka realizace pohybu 3D postavy z pohledu třetí osoby (TPS) v Godot Engine. Tento projekt demonstruje kompletní cestu od generování postavy přes rigging a animaci až po finální implementaci fyzikálního pohybu.

## Proces tvorby assetů
Workflow je rozdělen do tří hlavních fází s využitím specializovaných nástrojů:

### 1. MakeHuman Community (Modelace)
Prvním krokem bylo vytvoření základní anatomie postavy.

* **Výstup:** Export 3D modelu v základní pozici `T-Pose`.
* **Nastavení:** Exportováno do formátu `FBX` bez kostry (Rigging byl ponechán na Mixamo).
* **Web:** [makehumancommunity.org](Screenshothttp://www.makehumancommunity.org)

---

### 2. Adobe Mixamo (Rigging & Animace)
Online nástroj pro automatický rigging a aplikaci pohybových dat (MoCap).

* **Proces:** Import `FBX` modelu a následný export tří specifických souborů:
1. **Skin Model:** Postava v `T-Pose` (slouží jako základní síť).
2. **Idle Animation:** Animace postoje (exportováno bez textur – *Without Skin*).
3. **Walk Animation:** Animace chůze (exportováno bez textur – *Without Skin*).

* **Web:** [mixamo.com](Screenshothttps://www.mixamo.com)

---

### 3. Blender (Kompletace & Prostředí)

Finální úpravy a příprava scény pro herní engine.

* **Animace:** Spojení stažených animací k jednomu modelu a příprava pro export.
* **Level Design:** Vytvoření testovacího 3D světa.
* **Kolize:** Veškerá geometrie prostředí byla připravena s kolizními sítěmi pomocí vlastního Python skriptu. Objekty využívají standardní příponu `_col`, kterou Godot Engine automaticky rozpozná a převede na fyzikální kolize.
* **Web:** [blender.org](Screenshothttps://www.blender.org/)

---

### Klíčové vlastnosti projektu
* **Plynulý pohyb:** Využití `AnimationTree` a `BlendSpace1D` pro přechod mezi Idle a Walk.
* **Optimalizace:** Kolizní modely jsou odděleny od vizuálních pro lepší výkon.
* **Standardy:** Dodržení jmenných konvencí Godot Engine pro bezproblémový import.

---

## Python script pro generování kolizních sítí
> Vytvořil jsem script v **Pythonu pro Blender**, který automatizuje přípravu kolizních tvarů pro Godot Engine.

Tento skript výrazně urychluje workflow při exportu 3D modelů. Namísto ručního vytváření a přejmenovávání kolizních ploch stačí vybrat objekty a spustit skript.

### Jak to funguje a proč to používat?
Godot Engine používá při importu souborů (`.blend`, `.gltf` nebo `.obj`) tzv. **importní příznaky** (import hints). Pokud název objektu končí příponou `-col` nebo `-collision`, Godot automaticky:

1. Vytvoří pro daný objekt uzel `StaticBody3D`.
2. Vygeneruje příslušný `CollisionShape3D` na základě geometrie objektu.
3. Zajistí, že samotná kolizní síť nebude viditelná ve hře, ale bude plnit svou fyzikální funkci.

### Co skript konkrétně dělá:
* **Automatické třídění:** Vytvoří v Blenderu novou kolekci s názvem `Collision_col`, aby v projektu zůstal pořádek.
* **Duplikace geometrie:** Z vybraných objektů vytvoří nezávislé kopie, takže původní modely zůstanou nedotčeny.
* **Přejmenování:** Ke každému názvu přidá suffix `_col`. Godot díky tomu po importu okamžitě ví, že jde o kolizní data.
* **Vizuální optimalizace v Blenderu:** Nastaví kolizní objekty tak, aby se zobrazovaly pouze jako drátěné modely (`WIRE`) a nepoužívaly se při renderování v Blenderu. To usnadňuje práci na scéně.

### Použití v Blenderu:
1. Otevřete **Scripting tab** v Blenderu.
2. Vložte níže uvedený kód.
3. Vyberte v 3D pohledu všechny objekty, pro které chcete vytvořit kolize.
4. Klikněte na **Run Script**.
5. Exportujte scénu do Godotu.

```python
import bpy

# Název cílové kolekce pro kolizní objekty
target_collection_name = "Collision_col"

# Vytvoř kolekci, pokud neexistuje
if target_collection_name not in bpy.data.collections:
	target_collection = bpy.data.collections.new(target_collection_name)
	bpy.context.scene.collection.children.link(target_collection)
else:
	target_collection = bpy.data.collections[target_collection_name]

# Pro každý vybraný objekt vytvoř kopii s názvem končícím na "_col"
for obj in bpy.context.selected_objects:
	if obj.type != 'MESH':
		continue

	# Duplikace objektu
	col_obj = obj.copy()
	col_obj.data = obj.data.copy()
	col_obj.name = f"{obj.name}_col"

	# Přesun do cílové kolekce
	target_collection.objects.link(col_obj)

	# Skrytí pro vykreslování (volitelné)
	col_obj.hide_render = True
	col_obj.display_type = 'WIRE'

print("Kolizní MESH byly vytvořeny a přesunuty do kolekce 'Collision_col'.")
```

---

## Ovládání a Mechaniky Hráče

Tento projekt využívá **PlayerController.gd** pro ovládání postavy z pohledu třetí osoby (Third-Person). Systém kombinuje fyzikální pohyb, plynulou interpolaci a kameru navázanou na pohyb myši.

### Klávesnice, Myš a Gamepad
| Akce | Klávesnice a Myš | Gamepad | Popis |
| --- | --- | --- | --- |
| **Pohyb** | `W`, `A`, `S`, `D` / Šipky | `Levá páčka` / `D-Pad` | Pohyb postavy relativně k pohledu kamery. |
| **Pohled** | `Pohyb myši` | `Pravá páčka` | Otáčení kamery kolem postavy ve všech směrech. |
| **Kurzor** | `Automaticky` | `N/A` | Po spuštění je kurzor myši skryt a uzamčen (`CAPTURED`). |
| **Ukončení** | `ESC` | `Menu` / `Start`* | Okamžité vypnutí aplikace (vhodné pro testování). |

### Technické principy skriptu

* **Kamera (SpringArm3D):** Využívá `SpringArm3D` k zamezení kolizí s prostředím (kamera neprochází zdmi). Vertikální pohled je omezen (`clamp`) v rozsahu  ( až  radiánů), aby nedocházelo k převrácení obrazu.
* **Pohybová logika:** * Směr pohybu je kalkulován relativně k rotaci `SpringArmPivot`.
* Pro plynulost je použita funkce `lerp()`, která zajišťuje setrvačnost při rozjezdu a zastavování.
* Maximální rychlost je nastavena na **5.0 m/s**.

* **Rotace postavy:** Model postavy (`armature`) se automaticky natáčí ve směru pohybu pomocí funkce `lerp_angle` a matematické funkce `atan2` z vektoru rychlosti.
* **Animace:** Skript je propojen s `AnimationTree`. Hodnota `blend_position` v BlendSpace1D je dynamicky vypočítávána jako poměr aktuální rychlosti k maximální rychlosti ().

---

### Tip pro vývojáře

Pokud chceš změnit citlivost myši, hledej v metodě `_unhandled_input` násobitel u rotace (aktuálně nastaven na `0.005`). Pro změnu plynulosti pohybu uprav konstantu `LERP_VAL`.

---

## Klíčové prvky (PlayerController.gd):
1. **Interpolace (`lerp` a `lerp_angle`)**: Tohle je "tajná omáčka" plynulosti. Postava se neotočí a nezastaví okamžitě, což působí přirozeněji. Hodnota `0.15` znamená, že v každém snímku se objekt přiblíží o 15 % k cíli.
2. **Kamera a směr**: Výpočet `direction.rotated(Vector3.UP, spring_arm_pivot.rotation.y)` je zásadní. Bez něj by postava chodila "dopředu" vzhledem ke světu, nikoliv tam, kam se dívá kamera.
3. **AnimationTree**: Skript dynamicky mění `blend_position`. Pokud postava stojí, hodnota je `0`. Pokud běží na plno, hodnota je `1`. To plynule prolíná animaci stání do animace běhu.
4. **Optimalizace**: Použití `_unhandled_input` je správná praxe – dovoluje UI (např. inventáři nebo menu) "zachytit" vstup dříve, než s ním pohne kamera.
---
## Screenshot
![Make Human Community](ScreenshotMakeHuman.png)
---
![Mixamo](ScreenshotMixamo.png)
---
![Blender Naked Girl](ScreenshotBlenderNakedGirl.png)
---
![Blender World](ScreenshotBlenderWorld.png)
---
© Lubomír Tomandl - **Angry Developer Studio**
---
