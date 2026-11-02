# Noctalia Cursor Manager

Plugin de [Noctalia](https://noctalia.dev) que aplica um tamanho maior para o ponteiro do mouse na inicialização e sempre que você mudar a configuração.

Funciona em **niri**, **Hyprland** e **Sway**, além de aplicar o tamanho via `gsettings` para aplicativos GTK.

## Por que existe

O niri não expõe o tamanho do cursor via IPC: ele só lê `cursor { xcursor-size N }` do `config.kdl`. Este plugin faz essa alteração de forma idempotente, com backup automático, e deixa o niri recarregar a configuração sozinho.

## Instalação

```bash
git clone https://github.com/CarlosRgoku/noctalia-cursor-manager.git
cd noctalia-cursor-manager
./install.sh
```

O script copia o plugin para `~/.local/share/noctalia/plugins/cursor-manager/` e tenta habilitá-lo com:

```bash
noctalia msg plugins enable my-tools/cursor-manager
```

Se preferir manualmente:

```bash
mkdir -p ~/.local/share/noctalia/plugins/cursor-manager
cp -r plugin.toml service.luau translations ~/.local/share/noctalia/plugins/cursor-manager/
noctalia msg plugins enable my-tools/cursor-manager
```

## Uso

Padrão: **48 px**.

Mudar pelo painel: **Settings → Plugins → Cursor Manager → Cursor size**.

Ou por IPC, sem reiniciar nada:

```bash
noctalia msg plugin my-tools/cursor-manager:service all set 64
noctalia msg plugin my-tools/cursor-manager:service all apply
```

Verificar se está ativo:

```bash
noctalia msg plugins list | grep cursor
```

## O que ele altera

| Ambiente | Ação |
| --- | --- |
| niri | Reescreve `xcursor-size` em `~/.config/niri/config.kdl` |
| Hyprland | `hyprctl setcursor <tema> <tamanho>` |
| Sway | `swaymsg seat - xcursor_theme <tema> <tamanho>` |
| GTK (todos) | `gsettings set org.gnome.desktop.interface cursor-size <tamanho>` |

Antes da primeira alteração no niri, é criado um backup em:

```
~/.config/niri/config.kdl.bak-cursor-manager
```

## Desinstalar

```bash
noctalia msg plugins disable my-tools/cursor-manager
rm -rf ~/.local/share/noctalia/plugins/cursor-manager
```

Para restaurar o tamanho original do niri:

```bash
cp ~/.config/niri/config.kdl.bak-cursor-manager ~/.config/niri/config.kdl
```

## Requisitos

- Noctalia v5 ou mais recente
- `plugin_api` 24 (suportado pelo Noctalia atual)
- niri, Hyprland ou Sway (GTK funciona em qualquer ambiente)

## Licença

MIT
