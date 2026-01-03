# Meshcombiner
by melondev

## What it does

* Merges **2 or more selected `MeshInstance3D` nodes** into one mesh
* Keeps the mesh **in the same world position** (not moved to origin)
* Preserves materials per surface
* Reduces draw calls and node count

## Installation

### Godot Asset Library

1. Open **AssetLib** in the Godot editor
2. Search for **Mesh Merge Plugin**
3. Download and Enable it in **Project Settings → Plugins**

### Manual (GitHub)

1. Download or clone the repository
2. Copy the plugin folder into `res://addons/`
3. Enable it in **Project Settings → Plugins**

## How to use

1. Enable the plugin in **Project Settings → Plugins**
2. Select **two or more `MeshInstance3D` nodes**
3. Click **Merge Meshes** in the top Scene Editor toolbar (The one with the select, move, rotate tools)
4. A new merged `MeshInstance3D` is created

You can delete the original meshes after merging.

### Visual Demonstration
![meshcombiner](https://github.com/user-attachments/assets/f3682caa-7271-4bb4-ae9e-f8b4dacc1cac)

another one

![meshcombiner2](https://github.com/user-attachments/assets/9c25496d-6fc4-4d74-84d0-a0ea95746bc4)


## Notes

* Works only with `MeshInstance3D`
* Intended for **static geometry**
* No animations, skinning, or collisions(you can try to create the collision after combining meshes by pressing mesh > create collision shape in the tool bar)

## Godot

* Godot 4.x
