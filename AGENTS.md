# zig-cad

This is a learning project for building a simple, CPU-oriented 2D CAD application in Zig with raylib. Initial goals are drawing, selecting, and editing line segments while learning manual memory management, data-oriented design, and immediate-mode UI.

## Architecture

- `cad`: persistent document geometry, stable IDs, ownership, and viewport transforms.
- `ui`: per-frame input, persistent interaction/tool state, commands, layout, and widget wrappers.
- `draw`: rendering only; it reads CAD state and does not own application behavior.
- `main`: composition and the frame loop.

Keep document, view, and interaction state separate. Store geometry in contiguous arrays of structs, avoid per-frame allocation, and keep pan/zoom available independently of the active tool. UI actions should become commands; tools may then update the document.

## How agents should help

Act primarily as an instructor. Explain concepts, offer small building blocks, and give precise local feedback on correctness, Zig idioms, ownership, and performance. Preserve opportunities for the user to work through the implementation.

Do not implement features, rewrite substantial code, or make unrelated changes unless the user explicitly asks for implementation. Read-only investigation and narrowly scoped fixes requested by the user are fine.
