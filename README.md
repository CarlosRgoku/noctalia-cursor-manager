# Noctalia Cursor Manager

Plugin de [Noctalia](https://noctalia.dev) que aplica **tema e tamanho** do ponteiro do mouse na inicialização e sempre que você mudar a configuração.

Funciona em **niri**, **Hyprland** e **Sway**, além de aplicar tema e tamanho via `gsettings` para aplicativos GTK.

Padrão: tema **macOS** (apple_cursor) com **48 px**.

## Por que existe

O niri não expõe tema nem tamanho do cursor via IPC: ele só lê `cursor { xcursor-theme "macOS"; xcursor-size 48 }` do `config.kdl`. Este plugin faz essa alteração de forma idempotente, com backup automático, e deixa o niri recarregar a configuração sozinho.

## Instalação

```bash
git clone https://github.com/CarlosRgoku/noctalia-cursor-manager.git
cd noctalia-cursor-manager
./install.sh
```

O script:

1. Copia o plugin para `~/.local/share/noctalia/plugins/cursor-manager/`
2. Baixa o tema `macOS` do [ful1e5/apple_cursor](https://github.com/ful1e5/apple_cursor) se ele ainda não existir em `~/.local/share/icons/`
3. Habilita o plugin com `noctalia msg plugins enable my-tools/cursor-manager`

Opções:

```bash
./install.sh --white      # instala o tema macOS-White
./install.sh --no-theme   # não baixa tema nenhum
```

Se preferir manualmente:

```bash
mkdir -p ~/.local/share/noctalia/plugins/cursor-manager
cp -r plugin.toml service.luau translations ~/.local/share/noctalia/plugins/cursor-manager/
noctalia msg plugins enable my-tools/cursor-manager
```

## Uso

Mudar pelo painel: **Settings → Plugins → Cursor Manager** (tema e tamanho).

Ou por IPC, sem reiniciar nada:

```bash
noctalia msg plugin my-tools/cursor-manager:service all set 64
noctalia msg plugin my-tools/cursor-manager:service all set-theme macOS
noctalia msg plugin my-tools/cursor-manager:service all apply
```

Verificar se está ativo:

```bash
noctalia msg plugins list | grep cursor
```

## O que ele altera

| Ambiente | Ação |
| --- | --- |
| niri | Reescreve `xcursor-theme` e `xcursor-size` em `~/.config/niri/config.kdl` |
| Hyprland | `hyprctl setcursor <tema> <tamanho>` |
| Sway | `swaymsg seat - xcursor_theme <tema> <tamanho>` |
| GTK (todos) | `gsettings set org.gnome.desktop.interface cursor-theme/cursor-size` |

A edição do `config.kdl` é feita pelo `apply-niri.sh`, que roda `niri validate` no arquivo gerado antes de gravar. Se o resultado for inválido, nada é alterado.

Antes da primeira alteração no niri, é criado um backup em:

```
~/.config/niri/config.kdl.bak-cursor-manager
```

## Tema macOS

O tema usado por padrão é o [apple_cursor](https://github.com/ful1e5/apple_cursor) v2.0.1, de **ful1e5**, licenciado sob **GPL-3.0**. Ele não é redistribuído neste repositório: o `install.sh` baixa o arquivo oficial `macOS.tar.xz` na sua máquina.

Se você já tem o tema em outro lugar, basta copiá-lo para `~/.local/share/icons/macOS/` e ajustar a opção **Cursor theme** para o nome da pasta.

## Desinstalar

```bash
noctalia msg plugins disable my-tools/cursor-manager
rm -rf ~/.local/share/noctalia/plugins/cursor-manager
```

Para restaurar o cursor original do niri:

```bash
cp ~/.config/niri/config.kdl.bak-cursor-manager ~/.config/niri/config.kdl
```

## Requisitos

- Noctalia v5 ou mais recente
- `plugin_api` 24 (suportado pelo Noctalia atual)
- niri, Hyprland ou Sway (GTK funciona em qualquer ambiente)
- `curl` e `tar` apenas para baixar o tema no `install.sh`

## Licença

Código do plugin: MIT.
Tema apple_cursor: GPL-3.0, © ful1e5.
