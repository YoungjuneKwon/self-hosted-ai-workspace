# 비밀값

English: [../secrets.md](../secrets.md)

## 문제

에이전트가 어떤 서비스를 쓰게 하려면 보통 에이전트가 읽을 수 있는 자리에 키를 둡니다.
환경 변수, `.env` 파일, git remote URL 에 박은 토큰 같은 것들입니다.

문제는 읽는다는 것 자체입니다. 에이전트가 키를 쓰려고 한 번 읽으면 그 사본이 전사본에
남습니다. 원본을 지워도 사본은 지워지지 않고, 폐기할 수도 없습니다. git remote URL 에
박힌 토큰은 `git remote -v` 한 번에 전사본으로 넘어갑니다.

## 이 작업환경이 대신 하는 것

[ValetFS](https://github.com/WinM2M/valet-fs) 는 키를 폰에 둡니다. 컨테이너의 데몬이
그것을 디스크가 아니라 메모리로, 폰이 허용하는 동안만 받습니다. 허가는 만료됩니다.

```sh
valetfs serve --join <연결 키>   # 이 기계를 폰과 연결합니다
valetfs status                   # 무엇이 얼마 동안 제공되는지 봅니다
valetfs ls fs:/keys              # 이름만 봅니다. 값은 보지 않습니다
```

비밀값을 쓰려고 읽지 않습니다. 필요한 명령에 넘깁니다.

```sh
valetfs exec fs:/keys/aws.env -- aws s3 ls s3://bucket
valetfs exec --as API_KEY fs:/keys/openai.txt -- node script.mjs
valetfs exec --as-file KEYFILE fs:/keys/apple.p8 -- ./sign.sh
```

값은 자식 프로세스의 환경으로 들어가므로 셸 기록이나 에이전트의 컨텍스트에 나타나지
않습니다.

`valetfs cat` 은 비밀값을 그대로 출력합니다. 에이전트에서 부르면 안 됩니다. 여기서
막으려는 것이 바로 그 누출입니다.

## 허가, 그리고 그것을 누가 내리는가

Claude Code 는 에이전트가 자기 설정을 고치는 것도, 기본적으로 자격 증명을 읽는 것도
막습니다. 둘 다 맞습니다. 에이전트가 제 뜻대로 금고를 열 수 있으면 디스크에 둔 키와 별
차이가 없습니다.

`valetfs setup-claude` 가 그 통로입니다. 설정 파일에 규칙 세 줄을 병합합니다.

```json
{"permissions":{"allow":["Bash(valetfs exec *)","Bash(valetfs ls *)","Bash(valetfs status)"]}}
```

`valetfs cat` 은 그 목록에 없습니다. `--allow-cat` 을 붙여 그 의미를 받아들이지 않는 한
들어가지 않습니다.

`./bootstrap.sh` 는 컨테이너를 띄우기 전에 이것을 물어보고 답을 적용합니다. 에이전트가
스스로에게 권한을 주는 것이 아니라, 운영자가 자기 기계에서 스크립트를 돌리면서 무엇에
동의하는지 먼저 듣는 것입니다. 비대화형 실행은 `--grant-vault` 가 없으면 거절합니다.

```sh
valetfs setup-claude --print     # 넣을 JSON 만 보고 아무것도 쓰지 않습니다
valetfs setup-claude             # 컨테이너 안에서 나중에 허가합니다
./bootstrap.sh --no-grant-vault  # 묻지 않고 거절한 채로 시작합니다
```

## 이것이 막아 주지 못하는 것

- 허가가 열려 있는 동안에는 컨테이너 안에서 도는 것이면 무엇이든, 탈취당한 프로세스를
  포함해 데몬에 비밀값을 요청할 수 있습니다. 통제 수단은 허가 창의 길이입니다.
- `valetfs exec` 는 값이 프로세스에 닿는 지점까지를 지킵니다. 그 프로그램이 값을 로그에
  적는다면 그것은 그 프로그램의 문제입니다.
- 「디스크가 아니라 메모리로」는 ValetFS 가 하는 일에 대한 설명입니다. 스왑이나 코어
  덤프에 대한 주장이 아닙니다.
- 화면 녹화와 스크린샷은 이 중 아무것도 지켜 주지 않습니다. 공개 전에 가리십시오.

## ValetFS 를 안 쓴다면

`./bootstrap.sh --no-valetfs` 로 빼면 나머지는 돕니다. 그 경우 최소한 git remote URL 과
`workspace/` 안에서는 키를 빼시는 편이 좋습니다. `workspace/` 는 호스트에서 마운트되는
자리입니다.
