# Rova-Emulator

Emuladores que o [Rova Games](https://github.com/JoaoP3droMM/i-can-play-everything) baixa, configura e abre
sozinho, sem a pessoa instalar ou abrir outro programa. Cada emulador fica numa pasta própria do Rova e não
mexe em emuladores que a pessoa já tenha instalados.

| Pasta | Console | Emulador | Licença |
|---|---|---|---|
| `switch/` | Switch | [Ryubing](https://git.ryujinx.app/projects/Ryubing) (continuação do Ryujinx) | MIT |

**O Rova-Emulator não fornece jogos, chaves, firmware nem BIOS.** Esses arquivos vêm do aparelho da própria
pessoa.

## Como as versões são feitas

Cada emulador tem um `versions.json` com a versão oficial e o hash SHA-256 de cada pacote. O processo
automático (`.github/workflows/switch.yml`) baixa o pacote oficial, confere o hash, empacota com o nome do
Rova junto com as licenças originais e, numa tag (`switch-v1.3.3`), publica no Release. O Rova baixa daqui e
confere o hash que o GitHub publica.

## Licenças

Os scripts deste repositório: MIT (`LICENSE`). Cada emulador mantém a licença dele, que vai dentro do pacote
(`LICENSE.txt`, `THIRDPARTY.md`).
