# 바깥과 연결하기

English: [../connect.md](../connect.md)

나갈 길이 없는 컨테이너는 잘 만든 모래상자일 뿐 작업환경이 아닙니다. 이 문서는 환경을
쓸모 있게 만드는 연결들과, 각 연결이 상태를 어디에 저장하는지 다룹니다.

여기 나오는 설정은 모두 홈 볼륨에 남습니다. 세션마다가 아니라 작업환경마다 한 번씩만
하면 됩니다.

## 이미 설치된 것

| | |
|---|---|
| `git`, `gh` | 깃헙, HTTPS 경유 |
| `ssh`, `rsync` | 원격 기계, 파일 동기화 |
| `curl`, `wget`, `openssl` | HTTP, 인증서 |
| `tmux` | 셸을 닫은 뒤에도 프로세스를 살려 둡니다 |
| `claude` | Claude Code, 리모트 컨트롤 포함 |
| `valetfs` | 비밀값. [secrets.md](secrets.md) 참고 |
| `cloudflared` | `./bootstrap.sh --with-cloudflared` 를 줄 때만 |

나가는 HTTPS 는 도커 기본 브리지로 동작합니다. 들어오는 포트는 `--port` 를 지정하지
않는 한 하나도 열리지 않습니다.

## 깃헙

```sh
gh auth login
```

자격 증명은 홈 볼륨에 있는 `~/.config/gh` 에 저장됩니다. 이후 HTTPS `git push` 가
remote URL 에 토큰을 박지 않고도 동작합니다. 이 차이가 중요합니다. remote URL 에 들어간
토큰은 무엇이든 `git remote -v` 를 실행하는 순간 에이전트의 전사본으로 넘어갑니다.

SSH remote 를 쓴다면 키를 디스크가 아니라 금고에 두십시오.

```sh
valetfs exec --as-file KEY fs:/keys/id_ed25519 -- \
  sh -c 'GIT_SSH_COMMAND="ssh -i $KEY" git push'
```

## Claude Code

```sh
claude
```

한 번 로그인하면 됩니다. 세션은 볼륨의 `~/.claude` 에 저장되므로 `docker rm` 이나 이미지
재빌드 후에도 남습니다.

## Claude 리모트 컨트롤

리모트 컨트롤을 쓰면 claude.ai/code 나 모바일 앱에서 이 컨테이너의 세션을 조작할 수
있습니다. 프로세스 하나가 디렉터리 하나를 담당합니다.

```sh
claude remote-control
```

이 프로세스는 계속 살아 있어야 하는데, 띄운 셸이 닫히면 같이 죽습니다. tmux 를 씁니다.

```sh
tmux new -d -s rc 'cd /workspace && claude remote-control --name my-workspace'
tmux ls                 # 살아 있는지 확인합니다
tmux attach -t rc       # 들여다봅니다. Ctrl-b d 로 띄워 둔 채 빠져나옵니다
```

컨테이너 자체도 계속 떠 있어야 합니다. `bootstrap.sh` 는 `docker run --rm` 을 쓰므로
셸을 나가면 멈춥니다. 자리를 비운 동안에도 접속할 작업환경이라면 분리 모드로 띄우십시오.

```sh
docker run -d --restart unless-stopped \
  --name ai-workspace \
  -v ai-workspace-home:/home/agent \
  -v "$PWD/workspace:/workspace" \
  -w /workspace \
  ai-workspace:latest \
  tmux new -s rc -d 'claude remote-control --name my-workspace' \; wait
```

확인한 범위: 설치된 CLI 에 `claude remote-control` 이 존재합니다. 실제 리스너 기동은
본인 Claude 계정이 있어야 하므로, 의지하기 전에 직접 시험해 보십시오.

## MCP 커넥터

구글 드라이브, 슬랙, 데이터베이스, 직접 만든 서버 같은 것들은 컨테이너에 도구를 설치하는
방식이 아니라 **MCP** 로 Claude Code 에 붙습니다.

```sh
claude mcp add --help
claude mcp list
```

설정은 `~/.claude` 아래에 쓰이므로 나머지와 함께 유지됩니다. 키가 필요한 커넥터는 이미지에
구워 넣은 환경 변수가 아니라 `valetfs exec` 로 읽게 하십시오.

## 공개 URL

`--with-cloudflared` 를 주면 빠른 터널을 명령 하나로 열 수 있고 클라우드플레어 계정도
필요 없습니다.

```sh
cloudflared tunnel --url http://localhost:5173
```

컨테이너로 연결되는 `trycloudflare.com` 주소를 출력합니다. 이 주소는 무작위이고
일시적이며, **주소를 아는 누구에게나 공개됩니다.** 보호되지 않은 관리 화면을 그 뒤에 두지
마십시오.

보유한 도메인에 고정 호스트명을 붙이려면 `cloudflared tunnel login` 으로 이름 있는 터널을
만듭니다. 그때 생기는 자격 증명은 이미지가 아니라 금고에 두십시오.

## 터널 없이 개발 서버에 접속하기

```sh
./bootstrap.sh --port 5173
```

호스트에서 `http://localhost:5173` 으로 들어갑니다. 지정하지 않으면 아무것도 열리지 않고,
`--port` 는 여러 번 쓸 수 있습니다.

## 통과하지 않는 것

- **호스트의 SSH 에이전트.** 전달되지 않습니다. 금고에 둔 키를 쓰십시오.
- **호스트의 브라우저 세션.** 컨테이너 안의 어떤 것도 내 기계 브라우저와 쿠키를 공유하지
  않습니다.
- **GUI 애플리케이션.** X 나 Wayland 소켓을 마운트하지 않습니다.
