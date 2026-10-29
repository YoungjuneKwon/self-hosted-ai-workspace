# self-hosted-ai-workspace

AI 코딩 에이전트로 매일 일하기 위한 컨테이너를 스크립트 하나로 세운다.

English: [../../README.md](../../README.md)

---

비슷한 환경을 1년쯤 매일 써 왔다. 어떻게 꾸몄냐는 질문을 여러 번 받아서, 내 기계에서만
되는 부분을 빼고 공개한다.

왜 하냐면 — 클라우드 작업환경은 바로 열리고 매번 깨끗하다. 가끔 쓰는 사람에게는 그쪽이
맞다. 매일 들어가서 같은 도구와 파일과 권한을 계속 다시 세우게 되면 그때부터 안 맞는다.
호텔이냐 집이냐의 문제고, 대부분은 호텔이 맞다.

## 차이가 실제로 무엇인가

2026년 10월 기준 내 판단이다. 공급자 기능은 바뀌니 중요한 줄은 직접 확인하는 게 좋다.

| | 오픈AI 클라우드 | 앤트로픽 클라우드 | 이 작업환경 |
|---|:---:|:---:|:---:|
| 내가 통제하는 하드웨어에서 실행 | X | X | O |
| 세션이 끝나도 맥락이 남는다 | △ | △ | O |
| 데스크톱·브라우저 제어 | △ | △ | O |
| 자격 증명과 권한 | X | △ | O |
| 작업 중에 UI 를 만들어 붙인다 | X | △ | O |
| **내가 자는 동안에도 돈다** | **O** | **O** | **X** |
| 데이터가 둔 자리에 남는다 | X | X | O |
| 비용을 예측할 수 있다 | △ | △ | O |

`O` 직접 지원 · `△` 부분적이거나 제약이 있음 · `X` 불가

굵은 줄은 클라우드가 이긴다. 내 전기와 공유기와 노트북이 꺼져도 호스팅 에이전트는 돈다.
나는 켜 두는 기계에 cron 과 재시작 정책을 걸어 쓰는데 그래도 같지 않다. 놓치면 안 되는
예약 작업은 클라우드에 둔다. 둘 다 쓴다.

각 줄의 근거: [why-this-exists.md](why-this-exists.md)

## 무엇이 들어 있나

재시작해도 홈 디렉터리가 남는 데비안 컨테이너다.

- Node 22, Python 3.11, git, gh, ripgrep, jq
- Claude Code. 원하면 opencode 와 Codex CLI 도.
- [ValetFS](https://github.com/WinM2M/valet-fs). 비밀값을 컨테이너에 저장하지 않고
  명령 하나에만 건네준다. 설치할 때 공개된 SHA-256 을 확인한다. 그 확인이 무엇을
  보장하고 무엇을 보장하지 않는지는 아래에 적었다.
- `workspace/` 는 내 디스크에서 바인드 마운트된다. 코드가 컨테이너 안에 없으니
  컨테이너는 버려도 된다.

## 빠른 시작

도커가 필요하다. 윈도우면 WSL2 백엔드를 켠 Docker Desktop.

```sh
git clone https://github.com/YoungjuneKwon/self-hosted-ai-workspace
cd self-hosted-ai-workspace
./bootstrap.sh
```

스크립트는 필요한 도구가 있는지 보고, 도커 이미지와 홈 디렉터리용 이름 붙은 볼륨,
컨테이너를 만든다. 도커 밖에서는 실행한 디렉터리에 `workspace/` 만 만든다.

```sh
./bootstrap.sh --help         # 전체 옵션
./bootstrap.sh --no-valetfs   # 금고 없이
./bootstrap.sh --grant-vault  # 아래 허가 질문에 미리 답하고 시작
./bootstrap.sh --shell        # 이미 만든 작업환경에 셸로 들어가기
```

안에서 `claude` 를 한 번 돌려 로그인하면 세션이 볼륨에 남는다.

## 부트스트랩이 묻는 것

컨테이너를 띄우기 전에, 에이전트가 매번 묻지 않고 `valetfs exec` 를 불러도 되는지
물어본다. 허가 범위도 같이 보여 준다 — `exec`·`ls`·`status`, `cat` 은 제외.

묻는 이유는 이게 권한 결정이고 권한 결정은 쓰는 사람 몫이어야 해서다. 나중에 명령을
치라고 떠넘기지 않는 이유는, 사람 몫이어야 하는 게 결정이지 타자가 아니어서다.
스크립트로 돌릴 때는 `--grant-vault` 나 `--no-grant-vault` 로 미리 답한다.
비대화형 실행은 기본으로 거절한다.

나중에 바꾸려면 컨테이너 안에서 `valetfs setup-claude` 를 돌리거나
`~/.claude/settings.json` 을 고치면 된다.

비밀값이 에이전트에게 읽히지 않고 명령에 닿는 방법, 그리고 그게 막아 주지 못하는 것은
[secrets.md](secrets.md) 에 적었다.

## 체크섬에 대해

설치기는 SHA-256 을 바이너리와 **같은 깃헙 릴리스**에서 받아 온다. 다운로드가 깨지거나
잘린 것은 잡지만 출처를 증명하지는 못한다. 한쪽 파일을 바꿀 수 있는 공격자는 다른 쪽도
바꿀 수 있기 때문이다.

ValetFS 릴리스는 cosign(keyless)으로 서명돼 있고 그쪽이 진짜 신뢰 경로다. 이미지를
가볍게 두려고 cosign 을 넣지 않았다. 더 강하게 확인하려면 빌드 전에 직접 돌리면 된다.

```sh
cosign verify-blob \
  --certificate SHA256SUMS.pem \
  --signature   SHA256SUMS.sig \
  --certificate-identity-regexp 'https://github.com/WinM2M/valet-fs/.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  SHA256SUMS
```

## 이것이 아닌 것

- **클라우드 대체재가 아니다.** 위의 굵은 줄을 보면 된다.
- **GPU 장비가 아니다.** 호스팅 모델을 부르는 에이전트용 작업환경이고 로컬 추론은
  구성하지 않는다.
- **내 기계 전부가 아니다.** 실제 환경에는 에이전트가 모는 브라우저와 터널, 호스트에
  묶인 설정이 더 있다. 옮길 수 없는 것들이라 여기 없다.
- **나 말고 아무도 감사하지 않았다.** 제3자 보안 검토는 받은 적이 없다. 돌리기 전에
  `docker/Dockerfile` 과 `bootstrap.sh` 를 읽어 보는 게 좋다.

## 라이선스

MIT. [LICENSE](../../LICENSE)
