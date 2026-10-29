# 비밀값

English: [../secrets.md](../secrets.md)

## 문제

에이전트가 어떤 서비스를 사용하게 하려면 보통 에이전트가 읽을 수 있는 위치에 키를 둡니다.
환경 변수, `.env` 파일, git remote URL 에 포함된 토큰이 그렇습니다.

문제는 읽는 동작 자체입니다. 에이전트가 키를 사용하기 위해 한 번 읽으면 전사본에 사본이
생깁니다. 원본을 삭제해도 사본은 남고, 사본은 폐기할 수 없습니다. git remote URL 에 포함된
토큰은 에이전트가 처음 `git remote -v` 를 실행하는 순간 전사본에 기록됩니다.

## 이 작업환경이 대신 하는 것

[ValetFS](https://github.com/WinM2M/valet-fs) 는 키를 폰에 보관합니다. 컨테이너의 데몬은
키를 디스크가 아니라 메모리로 받고, 폰이 허용하는 동안에만 유지합니다. 허가는 만료됩니다.

```sh
valetfs serve --join <연결 키>   # 이 기계를 폰과 연결합니다
valetfs status                   # 무엇이 얼마 동안 제공되는지 확인합니다
valetfs ls fs:/keys              # 이름만 표시하며 값은 표시하지 않습니다
```

비밀값을 사용하기 위해 읽지 않습니다. 필요한 명령에 전달합니다.

```sh
valetfs exec fs:/keys/aws.env -- aws s3 ls s3://bucket
valetfs exec --as API_KEY fs:/keys/openai.txt -- node script.mjs
valetfs exec --as-file KEYFILE fs:/keys/apple.p8 -- ./sign.sh
```

값은 자식 프로세스의 환경 변수로 전달되므로 셸 기록이나 에이전트의 컨텍스트에 나타나지
않습니다.

`valetfs cat` 은 비밀값을 그대로 출력합니다. 에이전트에서 실행하지 마십시오. 이 설정이
방지하려는 노출이 바로 그것입니다.

## 허가, 그리고 그것을 누가 내리는가

Claude Code 는 에이전트가 자체 설정을 수정하는 것과 자격 증명을 읽는 것을 기본적으로
차단합니다. 두 제한 모두 타당합니다. 에이전트가 스스로 금고를 열 수 있으면 디스크에 둔 키와
보호 수준이 크게 다르지 않습니다.

`valetfs setup-claude` 가 이를 허용하는 정식 방법입니다. 설정 파일에 규칙 세 개를
병합합니다.

```json
{"permissions":{"allow":["Bash(valetfs exec *)","Bash(valetfs ls *)","Bash(valetfs status)"]}}
```

`valetfs cat` 은 포함되지 않으며, `--allow-cat` 을 지정할 때만 추가됩니다.

`./bootstrap.sh` 는 컨테이너를 시작하기 전에 이를 묻고 답을 적용합니다. 에이전트가
스스로에게 권한을 주는 것이 아니라, 운영자가 스크립트를 실행하면서 허가 범위를 먼저 확인하는
구조입니다. 비대화형 실행은 `--grant-vault` 를 지정하지 않으면 접근을 허용하지 않습니다.

```sh
valetfs setup-claude --print     # 적용할 JSON 만 표시하고 변경하지 않습니다
valetfs setup-claude             # 컨테이너 안에서 나중에 허가합니다
./bootstrap.sh --no-grant-vault  # 묻지 않고 거절한 상태로 시작합니다
```

## 이것이 막아 주지 못하는 것

- 허가가 열려 있는 동안에는 컨테이너 안의 모든 프로세스가 데몬에 비밀값을 요청할 수
  있습니다. 탈취당한 프로세스도 마찬가지입니다. 허가 창의 길이가 이를 제한하는 수단입니다.
- `valetfs exec` 는 값이 프로세스에 전달될 때까지를 보호합니다. 그 프로그램이 값을 로그에
  기록한다면 그것은 프로그램 쪽 문제입니다.
- 「디스크가 아니라 메모리로」는 ValetFS 의 동작에 대한 설명입니다. 스왑이나 코어 덤프에
  대한 주장이 아닙니다.
- 화면 녹화와 스크린샷은 이와 무관합니다. 공개하기 전에 가려 주세요.

## ValetFS 를 안 쓴다면

`./bootstrap.sh --no-valetfs` 로 제외하면 나머지는 그대로 동작합니다. 그 경우 git remote
URL 과 `workspace/` 안에는 키를 두지 마십시오. `workspace/` 는 호스트에서 마운트되는
위치입니다.
