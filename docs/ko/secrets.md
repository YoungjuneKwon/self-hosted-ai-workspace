# 비밀값

English: [../secrets.md](../secrets.md)

## 문제

에이전트가 어떤 서비스를 쓰게 하려면 보통 에이전트가 읽을 수 있는 자리에 키를 둔다.
환경 변수, `.env` 파일, git remote URL 에 박은 토큰.

문제는 읽는다는 것 자체다. 에이전트가 키를 쓰려고 읽으면 그 사본이 전사본에 남는다.
원본을 지워도 사본은 안 지워지고 폐기할 방법도 없다. 살아 있는 자격 증명이 있어서는 안
될 자리로 흘러가는 가장 흔한 경로이고, 내가 하나 잃은 방식이기도 하다
([why-this-exists.md](why-this-exists.md)).

## 이 작업환경이 대신 하는 것

[ValetFS](https://github.com/WinM2M/valet-fs) 는 키를 폰에 둔다. 컨테이너의 데몬이
그것을 디스크가 아니라 메모리로, 폰이 허용하는 동안만 받는다. 허가는 만료된다.

```sh
valetfs serve --join <연결 키>   # 이 기계를 폰과 연결한다
valetfs status                   # 무엇이 얼마 동안 제공되는가
valetfs ls fs:/keys              # 이름만 본다. 값은 안 본다
```

비밀값을 쓰려고 읽지 않는다. 필요한 명령에 넘긴다.

```sh
valetfs exec fs:/keys/aws.env -- aws s3 ls s3://bucket
valetfs exec --as API_KEY fs:/keys/openai.txt -- node script.mjs
valetfs exec --as-file KEYFILE fs:/keys/apple.p8 -- ./sign.sh
```

값은 자식 프로세스의 환경으로 들어가므로 셸 기록이나 에이전트의 컨텍스트에 남지 않는다.

`valetfs cat` 은 비밀값을 그대로 출력한다. 에이전트에서 부르지 않는다. 여기서 막으려는
게 바로 그 누출이다.

## 허가, 그리고 그걸 누가 내리는가

Claude Code 는 에이전트가 자기 설정을 고치는 것도, 기본적으로 자격 증명을 읽는 것도
막는다. 둘 다 맞다. 에이전트가 제 뜻대로 금고를 열 수 있으면 디스크에 둔 키와 별 차이가
없다.

`valetfs setup-claude` 가 그 통로다. 설정에 규칙 세 줄을 병합한다.

```json
{"permissions":{"allow":["Bash(valetfs exec *)","Bash(valetfs ls *)","Bash(valetfs status)"]}}
```

`valetfs cat` 은 그 목록에 없다. `--allow-cat` 을 붙여 그 의미를 받아들이지 않는 한
들어가지 않는다.

`./bootstrap.sh` 는 컨테이너를 띄우기 전에 이걸 물어보고 답을 적용한다. 에이전트가
스스로에게 권한을 주는 게 아니라, 사람이 자기 기계에서 스크립트를 돌리면서 무엇에
동의하는지 먼저 듣는 것이다. 비대화형 실행은 `--grant-vault` 를 주지 않는 한 거절한다.

```sh
valetfs setup-claude --print     # 넣을 JSON 만 보고 아무것도 쓰지 않는다
valetfs setup-claude             # 컨테이너 안에서 나중에 허가한다
./bootstrap.sh --no-grant-vault  # 묻지 않고 거절한 채로 시작한다
```

## 이게 막아 주지 못하는 것

- 허가가 열려 있는 동안에는 컨테이너 안에서 도는 것이면 무엇이든, 탈취당한 프로세스를
  포함해 데몬에 비밀값을 요청할 수 있다. 통제 수단은 허가 창의 길이다.
- `valetfs exec` 는 값이 프로세스에 닿는 지점까지를 지킨다. 그 프로그램이 값을 로그에
  적으면 그건 그 프로그램 문제다.
- 「디스크가 아니라 메모리로」는 ValetFS 가 하는 일에 대한 설명이다. 스왑이나 코어 덤프에
  대한 주장이 아니다.
- 화면 녹화와 스크린샷은 이 중 아무것도 지켜 주지 않는다. 공개 전에 가린다.

## ValetFS 를 안 쓴다면

`./bootstrap.sh --no-valetfs` 로 빼면 나머지는 돈다. 그 길로 간다면 최소한 git remote
URL 과 `workspace/` 안에서는 키를 빼는 게 좋다. `workspace/` 는 내 디스크에서 마운트되는
자리다.
