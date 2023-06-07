# godot-inspector-architect
 
A work-in-progress Godot addon to create inspector plug-ins.

Driving force, inspiration:
- During a hobby project (OpenStreetMap related), I am making a Resource type, where one can put together queries (Overpass) in the Inspector,
  which will result in a generated script (Overpass QL). (https://github.com/coderbloke/godot-osm)<br>
  I run into the situation that the inspector of that resource (which could contain sub-resources at deep level)
  became an inspector rabbit hole.<br>
  At some places I only need some additinoal control, or some more space, have more compact property editors, or exchange some fo them to custom ones.<br>
  When I need this, I don't want to change to coding inspector plug-in, swithcing to another code base with lots of bloilerplate codes.<br>
  I want ot make it more like a quick design process.  
- During debugging that above project and this one also, I already made addon, to ease myself, which turned into a plug-in usefull to anybody.
  (https://github.com/coderbloke/godot-debug-info-plugin)<br>
  Maybe this one will turn into similar.

First goal:
- Achieve something like this... Script snippets injected to the property parsing process, when Inspector is calling the InspectorPlugin.<br>
  All quickly specified in a resource editor:  
![Godot_v4 0 3-stable_win64_ZVkuuO1viY](https://github.com/coderbloke/godot-inspector-architect/assets/75695649/9763562f-6cbe-4171-8ad9-63af4fc5e7a7)
