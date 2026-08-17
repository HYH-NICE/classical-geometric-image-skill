# Classical Geometric Image Skill

Private Codex Skill for turning user-supplied photographs and design references into culturally coherent classical, geometric, painterly editorial posters.

For normal use, attach an image and request a style. The installed Skill generates the artwork directly; it does not require project planning, TDD, Git, subagents, or repository setup unless you explicitly ask to develop or publish the Skill itself.

## Install with Codex

Ask Codex to install the Skill from:

`https://github.com/HYH-NICE/classical-geometric-image-skill/tree/main/skills/generate-classical-geometric-images`

### Windows PowerShell

```powershell
python "$env:USERPROFILE\.codex\skills\.system\skill-installer\scripts\install-skill-from-github.py" --repo HYH-NICE/classical-geometric-image-skill --path skills/generate-classical-geometric-images
```

### macOS / Linux

```bash
python "${CODEX_HOME:-$HOME/.codex}/skills/.system/skill-installer/scripts/install-skill-from-github.py" --repo HYH-NICE/classical-geometric-image-skill --path skills/generate-classical-geometric-images
```

Restart Codex or begin a new turn after installation. For a private repository, authenticate Git or provide `GITHUB_TOKEN`/`GH_TOKEN` in the local environment; never paste a token into chat.

## Update

Remove or rename the existing local `generate-classical-geometric-images` directory, then repeat the installation command. The installer intentionally refuses to overwrite an existing Skill.

## Invoke

Attach a photograph or design reference and ask:

`Use generate-classical-geometric-images to create a Chinese classical mineral-pigment poster while preserving the subject.`

The runtime Skill is under `skills/generate-classical-geometric-images`. Generic release checks are under `tests`.
