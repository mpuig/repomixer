================================================================
Files
================================================================

================
File: docs/ko/models/index.md
================
---
search:
  exclude: true
---
# 모델

Agents SDK 는 OpenAI 모델을 두 가지 방식으로 즉시 사용할 수 있도록 지원합니다:

-   **권장**: 새로운 [Responses API](https://platform.openai.com/docs/api-reference/responses)를 사용해 OpenAI API 를 호출하는 [`OpenAIResponsesModel`][agents.models.openai_responses.OpenAIResponsesModel]
-   [Chat Completions API](https://platform.openai.com/docs/api-reference/chat)를 사용해 OpenAI API 를 호출하는 [`OpenAIChatCompletionsModel`][agents.models.openai_chatcompletions.OpenAIChatCompletionsModel]

## 모델 설정 선택

설정에 따라 다음 순서로 이 페이지를 활용하세요:

| 목표 | 시작 지점 |
| --- | --- |
| SDK 기본값으로 OpenAI 호스팅 모델 사용 | [OpenAI 모델](#openai-models) |
| websocket 전송으로 OpenAI Responses API 사용 | [Responses WebSocket 전송](#responses-websocket-transport) |
| OpenAI 이외 제공자 사용 | [OpenAI 이외 모델](#non-openai-models) |
| 하나의 워크플로에서 모델/제공자 혼합 | [고급 모델 선택 및 혼합](#advanced-model-selection-and-mixing) 및 [제공자 간 모델 혼합](#mixing-models-across-providers) |
| 제공자 호환성 문제 디버깅 | [OpenAI 이외 제공자 문제 해결](#troubleshooting-non-openai-providers) |

## OpenAI 모델

`Agent` 를 초기화할 때 모델을 지정하지 않으면 기본 모델이 사용됩니다. 현재 기본값은 호환성과 낮은 지연 시간을 위해 [`gpt-4.1`](https://platform.openai.com/docs/models/gpt-4.1)입니다. 접근 권한이 있다면, 명시적인 `model_settings` 를 유지하면서 더 높은 품질을 위해 에이전트를 [`gpt-5.2`](https://platform.openai.com/docs/models/gpt-5.2)로 설정할 것을 권장합니다.

[`gpt-5.2`](https://platform.openai.com/docs/models/gpt-5.2) 같은 다른 모델로 전환하려면, 에이전트를 설정하는 방법이 두 가지 있습니다.

### 기본 모델

첫째, 커스텀 모델을 설정하지 않은 모든 에이전트에서 특정 모델을 일관되게 사용하려면, 에이전트를 실행하기 전에 `OPENAI_DEFAULT_MODEL` 환경 변수를 설정하세요.

```bash
export OPENAI_DEFAULT_MODEL=gpt-5.2
python3 my_awesome_agent.py
```

둘째, `RunConfig` 를 통해 실행 단위 기본 모델을 설정할 수 있습니다. 에이전트에 모델을 설정하지 않으면 이 실행의 모델이 사용됩니다.

```python
from agents import Agent, RunConfig, Runner

agent = Agent(
    name="Assistant",
    instructions="You're a helpful agent.",
)

result = await Runner.run(
    agent,
    "Hello",
    run_config=RunConfig(model="gpt-5.2"),
)
```

#### GPT-5.x 모델

이 방식으로 [`gpt-5.2`](https://platform.openai.com/docs/models/gpt-5.2) 같은 GPT-5.x 모델을 사용하면 SDK 가 기본 `ModelSettings` 를 적용합니다. 대부분의 사용 사례에 가장 잘 맞는 설정이 적용됩니다. 기본 모델의 추론 강도를 조정하려면 사용자 정의 `ModelSettings` 를 전달하세요:

```python
from openai.types.shared import Reasoning
from agents import Agent, ModelSettings

my_agent = Agent(
    name="My Agent",
    instructions="You're a helpful agent.",
    # If OPENAI_DEFAULT_MODEL=gpt-5.2 is set, passing only model_settings works.
    # It's also fine to pass a GPT-5.x model name explicitly:
    model="gpt-5.2",
    model_settings=ModelSettings(reasoning=Reasoning(effort="high"), verbosity="low")
)
```

더 낮은 지연 시간을 위해 `gpt-5.2` 에서 `reasoning.effort="none"` 사용을 권장합니다. gpt-4.1 계열( mini 및 nano 변형 포함)도 대화형 에이전트 앱 구축에 여전히 훌륭한 선택지입니다.

#### GPT-5 이외 모델

사용자 정의 `model_settings` 없이 GPT-5 이외 모델 이름을 전달하면, SDK 는 모든 모델과 호환되는 일반 `ModelSettings` 로 되돌아갑니다.

### Responses WebSocket 전송

기본적으로 OpenAI Responses API 요청은 HTTP 전송을 사용합니다. OpenAI 기반 모델 사용 시 websocket 전송을 선택할 수 있습니다.

```python
from agents import set_default_openai_responses_transport

set_default_openai_responses_transport("websocket")
```

이는 기본 OpenAI 제공자에서 해석되는 OpenAI Responses 모델( `"gpt-5.2"` 같은 문자열 모델 이름 포함)에 영향을 줍니다.

전송 방식 선택은 SDK 가 모델 이름을 모델 인스턴스로 해석할 때 이루어집니다. 구체적인 [`Model`][agents.models.interface.Model] 객체를 전달하면 전송 방식은 이미 고정됩니다: [`OpenAIResponsesWSModel`][agents.models.openai_responses.OpenAIResponsesWSModel]은 websocket 을 사용하고, [`OpenAIResponsesModel`][agents.models.openai_responses.OpenAIResponsesModel]은 HTTP 를 사용하며, [`OpenAIChatCompletionsModel`][agents.models.openai_chatcompletions.OpenAIChatCompletionsModel]은 Chat Completions 를 유지합니다. `RunConfig(model_provider=...)` 를 전달하면 전역 기본값 대신 해당 제공자가 전송 방식 선택을 제어합니다.

제공자별 또는 실행별로 websocket 전송을 설정할 수도 있습니다:

```python
from agents import Agent, OpenAIProvider, RunConfig, Runner

provider = OpenAIProvider(
    use_responses_websocket=True,
    # Optional; if omitted, OPENAI_WEBSOCKET_BASE_URL is used when set.
    websocket_base_url="wss://your-proxy.example/v1",
)

agent = Agent(name="Assistant")
result = await Runner.run(
    agent,
    "Hello",
    run_config=RunConfig(model_provider=provider),
)
```

모델 이름 접두사 기반 라우팅(예: 한 번의 실행에서 `openai/...` 와 `litellm/...` 혼합)이 필요하면, [`MultiProvider`][agents.MultiProvider] 를 사용하고 대신 `openai_use_responses_websocket=True` 를 설정하세요.

사용자 정의 OpenAI 호환 엔드포인트나 프록시를 사용하는 경우, websocket 전송에도 호환되는 websocket `/responses` 엔드포인트가 필요합니다. 이런 설정에서는 `websocket_base_url` 을 명시적으로 설정해야 할 수 있습니다.

참고:

-   이는 websocket 전송 기반 Responses API 이며, [Realtime API](../realtime/guide.md)가 아닙니다. Chat Completions 또는 Responses websocket `/responses` 엔드포인트를 지원하지 않는 OpenAI 이외 제공자에는 적용되지 않습니다
-   환경에 아직 없다면 `websockets` 패키지를 설치하세요
-   websocket 전송을 활성화한 후 [`Runner.run_streamed()`][agents.run.Runner.run_streamed] 를 직접 사용할 수 있습니다. 여러 턴 워크플로에서 같은 websocket 연결을 턴 간(중첩된 agent-as-tool 호출 포함) 재사용하려면 [`responses_websocket_session()`][agents.responses_websocket_session] 헬퍼 사용을 권장합니다. [에이전트 실행](../running_agents.md) 가이드와 [`examples/basic/stream_ws.py`](https://github.com/openai/openai-agents-python/tree/main/examples/basic/stream_ws.py)를 참고하세요

## OpenAI 이외 모델

대부분의 OpenAI 이외 모델은 [LiteLLM 통합](./litellm.md)을 통해 사용할 수 있습니다. 먼저 litellm 의존성 그룹을 설치하세요:

```bash
pip install "openai-agents[litellm]"
```

그다음 `litellm/` 접두사를 사용해 [지원되는 모델](https://docs.litellm.ai/docs/providers) 중 아무 것이나 사용할 수 있습니다:

```python
claude_agent = Agent(model="litellm/anthropic/claude-3-5-sonnet-20240620", ...)
gemini_agent = Agent(model="litellm/gemini/gemini-2.5-flash-preview-04-17", ...)
```

### OpenAI 이외 모델 사용의 다른 방법

다음 3 가지 방법으로도 다른 LLM 제공자를 통합할 수 있습니다(코드 예제는 [여기](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/) 참고):

1. [`set_default_openai_client`][agents.set_default_openai_client] 는 `AsyncOpenAI` 인스턴스를 LLM 클라이언트로 전역 사용하고 싶을 때 유용합니다. LLM 제공자가 OpenAI 호환 API 엔드포인트를 제공하고 `base_url` 및 `api_key` 를 설정할 수 있는 경우에 해당합니다. 설정 가능한 예시는 [examples/model_providers/custom_example_global.py](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/custom_example_global.py) 를 참고하세요
2. [`ModelProvider`][agents.models.interface.ModelProvider] 는 `Runner.run` 수준에서 사용합니다. 이를 통해 "이 실행의 모든 에이전트에 커스텀 모델 제공자를 사용"하도록 지정할 수 있습니다. 설정 가능한 예시는 [examples/model_providers/custom_example_provider.py](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/custom_example_provider.py) 를 참고하세요
3. [`Agent.model`][agents.agent.Agent.model] 을 사용하면 특정 Agent 인스턴스에 모델을 지정할 수 있습니다. 이를 통해 서로 다른 에이전트에 서로 다른 제공자를 혼합해 사용할 수 있습니다. 설정 가능한 예시는 [examples/model_providers/custom_example_agent.py](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/custom_example_agent.py) 를 참고하세요. 사용 가능한 대부분의 모델을 쉽게 사용하는 방법은 [LiteLLM 통합](./litellm.md)입니다

`platform.openai.com` 의 API 키가 없는 경우에는 `set_tracing_disabled()` 로 트레이싱을 비활성화하거나, [다른 트레이싱 프로세서](../tracing.md)를 설정하는 것을 권장합니다.

!!! note

    이 예시들에서는 대부분의 LLM 제공자가 아직 Responses API 를 지원하지 않기 때문에 Chat Completions API/model 을 사용합니다. LLM 제공자가 이를 지원한다면 Responses 사용을 권장합니다

## 고급 모델 선택 및 혼합

단일 워크플로 내에서 에이전트별로 서로 다른 모델을 사용하고 싶을 수 있습니다. 예를 들어 분류에는 더 작고 빠른 모델을, 복잡한 작업에는 더 크고 성능이 높은 모델을 사용할 수 있습니다. [`Agent`][agents.Agent] 를 구성할 때 다음 중 하나로 특정 모델을 선택할 수 있습니다:

1. 모델 이름 전달
2. 모델 이름 + 해당 이름을 Model 인스턴스로 매핑할 수 있는 [`ModelProvider`][agents.models.interface.ModelProvider] 전달
3. [`Model`][agents.models.interface.Model] 구현을 직접 제공

!!!note

    SDK 는 [`OpenAIResponsesModel`][agents.models.openai_responses.OpenAIResponsesModel] 과 [`OpenAIChatCompletionsModel`][agents.models.openai_chatcompletions.OpenAIChatCompletionsModel] 형태를 모두 지원하지만, 두 형태가 지원하는 기능 및 도구 집합이 다르므로 워크플로마다 단일 모델 형태 사용을 권장합니다. 워크플로에서 모델 형태 혼합이 필요하다면, 사용하는 모든 기능이 양쪽 모두에서 제공되는지 확인하세요

```python
from agents import Agent, Runner, AsyncOpenAI, OpenAIChatCompletionsModel
import asyncio

spanish_agent = Agent(
    name="Spanish agent",
    instructions="You only speak Spanish.",
    model="gpt-5-mini", # (1)!
)

english_agent = Agent(
    name="English agent",
    instructions="You only speak English",
    model=OpenAIChatCompletionsModel( # (2)!
        model="gpt-5-nano",
        openai_client=AsyncOpenAI()
    ),
)

triage_agent = Agent(
    name="Triage agent",
    instructions="Handoff to the appropriate agent based on the language of the request.",
    handoffs=[spanish_agent, english_agent],
    model="gpt-5",
)

async def main():
    result = await Runner.run(triage_agent, input="Hola, ¿cómo estás?")
    print(result.final_output)
```

1.  OpenAI 모델 이름을 직접 설정합니다
2.  [`Model`][agents.models.interface.Model] 구현을 제공합니다

에이전트에 사용되는 모델을 더 세부적으로 구성하려면, temperature 같은 선택적 모델 구성 매개변수를 제공하는 [`ModelSettings`][agents.models.interface.ModelSettings] 를 전달할 수 있습니다.

```python
from agents import Agent, ModelSettings

english_agent = Agent(
    name="English agent",
    instructions="You only speak English",
    model="gpt-4.1",
    model_settings=ModelSettings(temperature=0.1),
)
```

#### 일반적인 고급 `ModelSettings` 옵션

OpenAI Responses API 를 사용할 때는 여러 요청 필드에 이미 직접 대응되는 `ModelSettings` 필드가 있으므로, 해당 경우 `extra_args` 가 필요하지 않습니다.

| 필드 | 용도 |
| --- | --- |
| `parallel_tool_calls` | 같은 턴에서 여러 도구 호출을 허용하거나 금지 |
| `truncation` | 컨텍스트 초과 시 실패 대신 Responses API 가 가장 오래된 대화 항목을 삭제하도록 `"auto"` 설정 |
| `prompt_cache_retention` | 예: `"24h"` 처럼 캐시된 프롬프트 접두사 유지 시간을 늘림 |
| `response_include` | `web_search_call.action.sources`, `file_search_call.results`, `reasoning.encrypted_content` 같은 더 풍부한 응답 페이로드 요청 |
| `top_logprobs` | 출력 텍스트의 상위 토큰 logprobs 요청. SDK 는 `message.output_text.logprobs` 도 자동 추가 |

```python
from agents import Agent, ModelSettings

research_agent = Agent(
    name="Research agent",
    model="gpt-5.2",
    model_settings=ModelSettings(
        parallel_tool_calls=False,
        truncation="auto",
        prompt_cache_retention="24h",
        response_include=["web_search_call.action.sources"],
        top_logprobs=5,
    ),
)
```

SDK 가 아직 최상위에서 직접 노출하지 않는 제공자별 또는 신규 요청 필드가 필요할 때는 `extra_args` 를 사용하세요.

또한 OpenAI 의 Responses API 를 사용할 때 [다른 선택적 매개변수 몇 가지](https://platform.openai.com/docs/api-reference/responses/create)(예: `user`, `service_tier` 등)가 있습니다. 이들이 최상위에 없다면 `extra_args` 로 전달할 수 있습니다.

```python
from agents import Agent, ModelSettings

english_agent = Agent(
    name="English agent",
    instructions="You only speak English",
    model="gpt-4.1",
    model_settings=ModelSettings(
        temperature=0.1,
        extra_args={"service_tier": "flex", "user": "user_12345"},
    ),
)
```

## OpenAI 이외 제공자 문제 해결

### 트레이싱 클라이언트 오류 401

트레이싱 관련 오류가 발생하는 경우, 트레이스가 OpenAI 서버로 업로드되는데 OpenAI API 키가 없기 때문입니다. 해결 방법은 세 가지입니다:

1. 트레이싱 완전 비활성화: [`set_tracing_disabled(True)`][agents.set_tracing_disabled]
2. 트레이싱용 OpenAI 키 설정: [`set_tracing_export_api_key(...)`][agents.set_tracing_export_api_key]. 이 API 키는 트레이스 업로드에만 사용되며 [platform.openai.com](https://platform.openai.com/) 발급 키여야 합니다
3. OpenAI 이외 트레이스 프로세서 사용. [트레이싱 문서](../tracing.md#custom-tracing-processors) 참고

### Responses API 지원

SDK 는 기본적으로 Responses API 를 사용하지만, 대부분의 다른 LLM 제공자는 아직 이를 지원하지 않습니다. 그 결과 404 또는 유사한 이슈가 발생할 수 있습니다. 해결 방법은 두 가지입니다:

1. [`set_default_openai_api("chat_completions")`][agents.set_default_openai_api] 호출. 이 방법은 환경 변수로 `OPENAI_API_KEY` 와 `OPENAI_BASE_URL` 을 설정하는 경우 동작합니다
2. [`OpenAIChatCompletionsModel`][agents.models.openai_chatcompletions.OpenAIChatCompletionsModel] 사용. 예시는 [여기](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/)에 있습니다

### structured outputs 지원

일부 모델 제공자는 [structured outputs](https://platform.openai.com/docs/guides/structured-outputs)를 지원하지 않습니다. 이 경우 때때로 다음과 같은 오류가 발생합니다:

```

BadRequestError: Error code: 400 - {'error': {'message': "'response_format.type' : value is not one of the allowed values ['text','json_object']", 'type': 'invalid_request_error'}}

```

이는 일부 모델 제공자의 한계입니다. JSON 출력은 지원하지만 출력에 사용할 `json_schema` 지정은 허용하지 않습니다. 이 문제는 현재 수정 작업 중이지만, JSON schema 출력을 지원하는 제공자 사용을 권장합니다. 그렇지 않으면 잘못된 JSON 때문에 앱이 자주 중단될 수 있습니다.

## 제공자 간 모델 혼합

모델 제공자 간 기능 차이를 인지하지 못하면 오류가 발생할 수 있습니다. 예를 들어 OpenAI 는 structured outputs, 멀티모달 입력, 호스팅 파일 검색 및 웹 검색을 지원하지만 많은 다른 제공자는 이를 지원하지 않습니다. 다음 제한 사항에 유의하세요:

-   지원하지 않는 제공자에는 해당 `tools` 를 보내지 마세요
-   텍스트 전용 모델 호출 전에 멀티모달 입력을 필터링하세요
-   structured JSON 출력을 지원하지 않는 제공자는 가끔 유효하지 않은 JSON 을 생성할 수 있다는 점에 유의하세요

================
File: docs/ko/models/litellm.md
================
---
search:
  exclude: true
---
# LiteLLM를 통한 임의 모델 사용

!!! note

    LiteLLM 통합은 베타 단계입니다. 특히 소규모 모델 제공업체에서 문제가 발생할 수 있습니다. 문제가 있으면 [GitHub 이슈](https://github.com/openai/openai-agents-python/issues)로 보고해 주세요. 신속히 수정하겠습니다.

[LiteLLM](https://docs.litellm.ai/docs/)은 단일 인터페이스로 100개 이상의 모델을 사용할 수 있게 해주는 라이브러리입니다. Agents SDK에서 어떤 AI 모델이든 사용할 수 있도록 LiteLLM 통합을 추가했습니다.

## 설정

`litellm`이 사용 가능한지 확인해야 합니다. 선택적 `litellm` 종속성 그룹을 설치하여 진행할 수 있습니다:

```bash
pip install "openai-agents[litellm]"
```

설치가 완료되면, 어떤 에이전트에서도 [`LitellmModel`][agents.extensions.models.litellm_model.LitellmModel]을 사용할 수 있습니다.

## 예제

다음은 완전하게 동작하는 예제입니다. 실행하면 모델 이름과 API 키를 입력하라는 메시지가 표시됩니다. 예를 들어 다음과 같이 입력할 수 있습니다:

- `openai/gpt-4.1` 모델과 OpenAI API 키
- `anthropic/claude-3-5-sonnet-20240620` 모델과 Anthropic API 키
- 등

LiteLLM에서 지원하는 전체 모델 목록은 [litellm providers 문서](https://docs.litellm.ai/docs/providers)를 참고하세요.

```python
from __future__ import annotations

import asyncio

from agents import Agent, Runner, function_tool, set_tracing_disabled
from agents.extensions.models.litellm_model import LitellmModel

@function_tool
def get_weather(city: str):
    print(f"[debug] getting weather for {city}")
    return f"The weather in {city} is sunny."


async def main(model: str, api_key: str):
    agent = Agent(
        name="Assistant",
        instructions="You only respond in haikus.",
        model=LitellmModel(model=model, api_key=api_key),
        tools=[get_weather],
    )

    result = await Runner.run(agent, "What's the weather in Tokyo?")
    print(result.final_output)


if __name__ == "__main__":
    # First try to get model/api key from args
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--model", type=str, required=False)
    parser.add_argument("--api-key", type=str, required=False)
    args = parser.parse_args()

    model = args.model
    if not model:
        model = input("Enter a model name for Litellm: ")

    api_key = args.api_key
    if not api_key:
        api_key = input("Enter an API key for Litellm: ")

    asyncio.run(main(model, api_key))
```

## 사용량 데이터 추적

LiteLLM 응답으로 Agents SDK 사용량 메트릭을 채우려면, 에이전트를 생성할 때 `ModelSettings(include_usage=True)`를 전달하세요.

```python
from agents import Agent, ModelSettings
from agents.extensions.models.litellm_model import LitellmModel

agent = Agent(
    name="Assistant",
    model=LitellmModel(model="your/model", api_key="..."),
    model_settings=ModelSettings(include_usage=True),
)
```

`include_usage=True`를 사용하면, LiteLLM 요청은 기본 제공 OpenAI 모델과 마찬가지로 `result.context_wrapper.usage`를 통해 토큰 및 요청 수를 보고합니다.

## 문제 해결

LiteLLM 응답에서 Pydantic 직렬화 경고가 보이는 경우, 다음 설정으로 작은 호환성 패치를 활성화하세요:

```bash
export OPENAI_AGENTS_ENABLE_LITELLM_SERIALIZER_PATCH=true
```

이 옵트인 플래그는 알려진 LiteLLM 직렬화 경고를 억제하면서 정상 동작을 유지합니다. 필요하지 않다면 끄세요(설정 해제 또는 `false`).

================
File: docs/ko/realtime/guide.md
================
---
search:
  exclude: true
---
# 실시간 에이전트 가이드

이 가이드는 OpenAI Agents SDK 의 실시간 레이어가 OpenAI Realtime API 에 어떻게 매핑되는지와, 그 위에 Python SDK 가 추가하는 동작을 설명합니다

!!! warning "베타 기능"

    실시간 에이전트는 베타입니다. 구현을 개선하는 과정에서 일부 호환성이 깨지는 변경이 있을 수 있습니다.

!!! note "여기서 시작"

    기본 Python 경로를 원하시면 먼저 [quickstart](quickstart.md)를 읽어보세요. 앱에서 서버 측 WebSocket 또는 SIP 중 무엇을 사용할지 결정 중이라면 [Realtime transport](transport.md)를 읽어보세요. 브라우저 WebRTC 전송은 Python SDK 범위에 포함되지 않습니다.

## 개요

실시간 에이전트는 Realtime API 와의 장기 연결을 유지하여, 모델이 텍스트와 오디오를 점진적으로 처리하고, 오디오 출력을 스트리밍하고, 도구를 호출하고, 매 턴마다 새 요청을 다시 시작하지 않고 인터럽션(중단 처리)을 처리할 수 있게 합니다.

주요 SDK 구성 요소는 다음과 같습니다:

-   **RealtimeAgent**: 하나의 실시간 전문 에이전트에 대한 instructions, tools, 출력 가드레일, 핸드오프
-   **RealtimeRunner**: 시작 에이전트를 실시간 전송에 연결하는 세션 팩토리
-   **RealtimeSession**: 입력을 전송하고, 이벤트를 수신하고, 히스토리를 추적하고, 도구를 실행하는 라이브 세션
-   **RealtimeModel**: 전송 추상화입니다. 기본값은 OpenAI 의 서버 측 WebSocket 구현입니다.

## 세션 수명 주기

일반적인 실시간 세션은 다음과 같습니다:

1. 하나 이상의 `RealtimeAgent`를 생성합니다.
2. 시작 에이전트로 `RealtimeRunner`를 생성합니다.
3. `await runner.run()`을 호출하여 `RealtimeSession`을 가져옵니다.
4. `async with session:` 또는 `await session.enter()`로 세션에 진입합니다.
5. `send_message()` 또는 `send_audio()`로 사용자 입력을 전송합니다.
6. 대화가 끝날 때까지 세션 이벤트를 순회합니다.

텍스트 전용 실행과 달리 `runner.run()`은 즉시 최종 결과를 생성하지 않습니다. 대신 전송 레이어와 동기화된 로컬 히스토리, 백그라운드 도구 실행, 가드레일 상태, 활성 에이전트 구성을 유지하는 라이브 세션 객체를 반환합니다.

기본적으로 `RealtimeRunner`는 `OpenAIRealtimeWebSocketModel`을 사용하므로, 기본 Python 경로는 Realtime API 에 대한 서버 측 WebSocket 연결입니다. 다른 `RealtimeModel`을 전달해도 동일한 세션 수명 주기와 에이전트 기능이 적용되며, 연결 메커니즘만 달라질 수 있습니다.

## 에이전트 및 세션 구성

`RealtimeAgent`는 일반 `Agent` 타입보다 의도적으로 범위가 좁습니다:

-   모델 선택은 에이전트별이 아니라 세션 수준에서 구성됩니다.
-   structured outputs는 지원되지 않습니다.
-   음성은 구성할 수 있지만, 세션이 이미 음성 오디오를 생성한 이후에는 변경할 수 없습니다.
-   instructions, 함수 도구, 핸드오프, 훅, 출력 가드레일은 모두 계속 동작합니다.

`RealtimeSessionModelSettings`는 더 새로운 중첩형 `audio` 구성과 이전의 평면 별칭을 모두 지원합니다. 새 코드에서는 중첩형을 권장합니다:

```python
runner = RealtimeRunner(
    starting_agent=agent,
    config={
        "model_settings": {
            "model_name": "gpt-realtime",
            "audio": {
                "input": {
                    "format": "pcm16",
                    "transcription": {"model": "gpt-4o-mini-transcribe"},
                    "turn_detection": {"type": "semantic_vad", "interrupt_response": True},
                },
                "output": {"format": "pcm16", "voice": "ash"},
            },
            "tool_choice": "auto",
        }
    },
)
```

유용한 세션 수준 설정은 다음과 같습니다:

-   `audio.input.format`, `audio.output.format`
-   `audio.input.transcription`
-   `audio.input.noise_reduction`
-   `audio.input.turn_detection`
-   `audio.output.voice`, `audio.output.speed`
-   `output_modalities`
-   `tool_choice`
-   `prompt`
-   `tracing`

`RealtimeRunner(config=...)`의 유용한 실행 수준 설정은 다음과 같습니다:

-   `async_tool_calls`
-   `output_guardrails`
-   `guardrails_settings.debounce_text_length`
-   `tool_error_formatter`
-   `tracing_disabled`

전체 타입 표면은 [`RealtimeRunConfig`][agents.realtime.config.RealtimeRunConfig] 및 [`RealtimeSessionModelSettings`][agents.realtime.config.RealtimeSessionModelSettings]를 참고하세요.

## 입력 및 출력

### 텍스트 및 구조화된 사용자 메시지

일반 텍스트 또는 구조화된 실시간 메시지에는 [`session.send_message()`][agents.realtime.session.RealtimeSession.send_message]를 사용하세요.

```python
from agents.realtime import RealtimeUserInputMessage

await session.send_message("Summarize what we discussed so far.")

message: RealtimeUserInputMessage = {
    "type": "message",
    "role": "user",
    "content": [
        {"type": "input_text", "text": "Describe this image."},
        {"type": "input_image", "image_url": image_data_url, "detail": "high"},
    ],
}
await session.send_message(message)
```

구조화된 메시지는 실시간 대화에 이미지 입력을 포함하는 주요 방법입니다. [`examples/realtime/app/server.py`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/app/server.py)의 예제 웹 데모는 이 방식으로 `input_image` 메시지를 전달합니다.

### 오디오 입력

원시 오디오 바이트를 스트리밍하려면 [`session.send_audio()`][agents.realtime.session.RealtimeSession.send_audio]를 사용하세요:

```python
await session.send_audio(audio_bytes)
```

서버 측 턴 감지가 비활성화된 경우, 턴 경계를 표시하는 책임은 사용자에게 있습니다. 고수준 편의 방식은 다음과 같습니다:

```python
await session.send_audio(audio_bytes, commit=True)
```

더 낮은 수준의 제어가 필요하면, 기본 모델 전송을 통해 `input_audio_buffer.commit` 같은 원시 클라이언트 이벤트를 보낼 수도 있습니다.

### 수동 응답 제어

`session.send_message()`는 고수준 경로를 사용해 사용자 입력을 전송하고 응답을 자동으로 시작합니다. 원시 오디오 버퍼링은 모든 구성에서 동일하게 자동 처리되지는 **않습니다**.

Realtime API 수준에서 수동 턴 제어는 원시 `session.update`로 `turn_detection`을 비운 다음, `input_audio_buffer.commit`과 `response.create`를 직접 보내는 것을 의미합니다.

턴을 수동으로 관리하는 경우, 모델 전송을 통해 원시 클라이언트 이벤트를 전송할 수 있습니다:

```python
from agents.realtime.model_inputs import RealtimeModelSendRawMessage

await session.model.send_event(
    RealtimeModelSendRawMessage(
        message={
            "type": "response.create",
        }
    )
)
```

이 패턴은 다음과 같은 경우에 유용합니다:

-   `turn_detection`이 비활성화되어 있고 모델이 언제 응답할지 직접 결정하고 싶은 경우
-   응답 트리거 전에 사용자 입력을 검사하거나 제한하고 싶은 경우
-   대역 외 응답에 사용자 지정 프롬프트가 필요한 경우

[`examples/realtime/twilio_sip/server.py`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/twilio_sip/server.py)의 SIP 예제는 시작 인사를 강제로 보내기 위해 원시 `response.create`를 사용합니다.

## 이벤트, 히스토리 및 인터럽션(중단 처리)

`RealtimeSession`은 고수준 SDK 이벤트를 내보내면서, 필요할 때 원시 모델 이벤트도 계속 전달합니다.

가치가 높은 세션 이벤트는 다음과 같습니다:

-   `audio`, `audio_end`, `audio_interrupted`
-   `agent_start`, `agent_end`
-   `tool_start`, `tool_end`, `tool_approval_required`
-   `handoff`
-   `history_added`, `history_updated`
-   `guardrail_tripped`
-   `input_audio_timeout_triggered`
-   `error`
-   `raw_model_event`

UI 상태에 가장 유용한 이벤트는 보통 `history_added`와 `history_updated`입니다. 이 이벤트는 사용자 메시지, 어시스턴트 메시지, 도구 호출을 포함한 세션의 로컬 히스토리를 `RealtimeItem` 객체로 노출합니다.

### 인터럽션(중단 처리) 및 재생 추적

사용자가 어시스턴트를 중단하면 세션은 `audio_interrupted`를 내보내고, 사용자가 실제로 들은 내용과 서버 측 대화가 정렬되도록 히스토리를 업데이트합니다.

저지연 로컬 재생에서는 기본 재생 추적기만으로 충분한 경우가 많습니다. 원격 또는 지연 재생 시나리오, 특히 전화 통신에서는 [`RealtimePlaybackTracker`][agents.realtime.model.RealtimePlaybackTracker]를 사용하세요. 이렇게 하면 모든 생성 오디오가 이미 재생되었다고 가정하는 대신 실제 재생 진행 상황을 기준으로 인터럽션 절단이 수행됩니다.

[`examples/realtime/twilio/twilio_handler.py`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/twilio/twilio_handler.py)의 Twilio 예제가 이 패턴을 보여줍니다.

## 도구, 승인, 핸드오프 및 가드레일

### 함수 도구

실시간 에이전트는 라이브 대화 중 함수 도구를 지원합니다:

```python
from agents import function_tool


@function_tool
def get_weather(city: str) -> str:
    """Get current weather for a city."""
    return f"The weather in {city} is sunny, 72F."


agent = RealtimeAgent(
    name="Assistant",
    instructions="You can answer weather questions.",
    tools=[get_weather],
)
```

### 도구 승인

함수 도구는 실행 전에 사람의 승인을 요구할 수 있습니다. 이 경우 세션은 `tool_approval_required`를 내보내고, `approve_tool_call()` 또는 `reject_tool_call()`을 호출할 때까지 도구 실행을 일시 중지합니다.

```python
async for event in session:
    if event.type == "tool_approval_required":
        await session.approve_tool_call(event.call_id)
```

구체적인 서버 측 승인 루프는 [`examples/realtime/app/server.py`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/app/server.py)를 참고하세요. 휴먼인더루프 (HITL) 문서도 [Human in the loop](../human_in_the_loop.md)에서 이 흐름을 다시 안내합니다.

### 핸드오프

실시간 핸드오프를 사용하면 한 에이전트가 라이브 대화를 다른 전문 에이전트로 넘길 수 있습니다:

```python
from agents.realtime import RealtimeAgent, realtime_handoff

billing_agent = RealtimeAgent(
    name="Billing Support",
    instructions="You specialize in billing issues.",
)

main_agent = RealtimeAgent(
    name="Customer Service",
    instructions="Triage the request and hand off when needed.",
    handoffs=[realtime_handoff(billing_agent, tool_description="Transfer to billing support")],
)
```

기본 `RealtimeAgent` 핸드오프는 자동 래핑되며, `realtime_handoff(...)`를 사용하면 이름, 설명, 검증, 콜백, 가용성을 사용자 지정할 수 있습니다. 실시간 핸드오프는 일반 핸드오프의 `input_filter`를 지원하지 **않습니다**.

### 가드레일

실시간 에이전트에서는 출력 가드레일만 지원됩니다. 이 가드레일은 매 부분 토큰마다가 아니라 디바운스된 전사 누적 기준으로 실행되며, 예외를 발생시키는 대신 `guardrail_tripped`를 내보냅니다.

```python
from agents.guardrail import GuardrailFunctionOutput, OutputGuardrail


def sensitive_data_check(context, agent, output):
    return GuardrailFunctionOutput(
        tripwire_triggered="password" in output,
        output_info=None,
    )


agent = RealtimeAgent(
    name="Assistant",
    instructions="...",
    output_guardrails=[OutputGuardrail(guardrail_function=sensitive_data_check)],
)
```

## SIP 및 전화 통신

Python SDK 는 [`OpenAIRealtimeSIPModel`][agents.realtime.openai_realtime.OpenAIRealtimeSIPModel]을 통한 일급 SIP 연결 플로우를 포함합니다.

Realtime Calls API 를 통해 통화가 들어오고, 결과 `call_id`에 에이전트 세션을 연결하려는 경우 이를 사용하세요:

```python
from agents.realtime import RealtimeRunner
from agents.realtime.openai_realtime import OpenAIRealtimeSIPModel

runner = RealtimeRunner(starting_agent=agent, model=OpenAIRealtimeSIPModel())

async with await runner.run(
    model_config={
        "call_id": call_id_from_webhook,
    }
) as session:
    async for event in session:
        ...
```

먼저 통화를 수락해야 하고, 수락 페이로드를 에이전트 파생 세션 구성과 일치시키려면 `OpenAIRealtimeSIPModel.build_initial_session_payload(...)`를 사용하세요. 전체 플로우는 [`examples/realtime/twilio_sip/server.py`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/twilio_sip/server.py)에 나와 있습니다.

## 저수준 접근 및 사용자 지정 엔드포인트

`session.model`을 통해 기본 전송 객체에 접근할 수 있습니다.

다음이 필요한 경우 이 방법을 사용하세요:

-   `session.model.add_listener(...)`를 통한 사용자 지정 리스너
-   `response.create` 또는 `session.update` 같은 원시 클라이언트 이벤트
-   `model_config`를 통한 사용자 지정 `url`, `headers`, `api_key` 처리
-   기존 실시간 통화에 `call_id` 연결

`RealtimeModelConfig`는 다음을 지원합니다:

-   `api_key`
-   `url`
-   `headers`
-   `initial_model_settings`
-   `playback_tracker`
-   `call_id`

이 리포지토리에 포함된 `call_id` 예제는 SIP 입니다. 더 넓은 Realtime API 에서도 일부 서버 측 제어 플로우에 `call_id`를 사용하지만, 여기에는 Python 예제로 패키징되어 있지 않습니다.

Azure OpenAI 에 연결할 때는 GA Realtime 엔드포인트 URL 과 명시적 헤더를 전달하세요. 예:

```python
session = await runner.run(
    model_config={
        "url": "wss://<your-resource>.openai.azure.com/openai/v1/realtime?model=<deployment-name>",
        "headers": {"api-key": "<your-azure-api-key>"},
    }
)
```

토큰 기반 인증의 경우 `headers`에 bearer 토큰을 사용하세요:

```python
session = await runner.run(
    model_config={
        "url": "wss://<your-resource>.openai.azure.com/openai/v1/realtime?model=<deployment-name>",
        "headers": {"authorization": f"Bearer {token}"},
    }
)
```

`headers`를 전달하면 SDK 는 `Authorization`을 자동으로 추가하지 않습니다. 실시간 에이전트에서는 레거시 베타 경로(`/openai/realtime?api-version=...`)를 피하세요.

## 추가 읽을거리

-   [Realtime transport](transport.md)
-   [Quickstart](quickstart.md)
-   [OpenAI Realtime conversations](https://developers.openai.com/api/docs/guides/realtime-conversations/)
-   [OpenAI Realtime server-side controls](https://developers.openai.com/api/docs/guides/realtime-server-controls/)
-   [`examples/realtime`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime)

================
File: docs/ko/realtime/quickstart.md
================
---
search:
  exclude: true
---
# 빠른 시작

Python SDK 의 실시간 에이전트는 WebSocket 전송을 통해 OpenAI Realtime API 위에서 구축된 서버 측 저지연 에이전트입니다

!!! warning "베타 기능"

    실시간 에이전트는 베타입니다. 구현이 개선되는 동안 일부 호환성이 깨지는 변경이 있을 수 있습니다

!!! note "Python SDK 범위"

    Python SDK 는 브라우저 WebRTC 전송을 **제공하지 않습니다**. 이 페이지는 서버 측 WebSocket 을 통한 Python 관리 실시간 세션만 다룹니다. 이 SDK 는 서버 측 오케스트레이션, 도구, 승인, 전화 통합에 사용하세요. [실시간 전송](transport.md)도 참고하세요

## 사전 요구 사항

-   Python 3.10 이상
-   OpenAI API 키
-   OpenAI Agents SDK 기본 사용 경험

## 설치

아직 설치하지 않았다면 OpenAI Agents SDK 를 설치하세요:

```bash
pip install openai-agents
```

## 서버 측 실시간 세션 생성

### 1. 실시간 구성 요소 가져오기

```python
import asyncio

from agents.realtime import RealtimeAgent, RealtimeRunner
```

### 2. 시작 에이전트 정의

```python
agent = RealtimeAgent(
    name="Assistant",
    instructions="You are a helpful voice assistant. Keep responses short and conversational.",
)
```

### 3. 러너 구성

새 코드에서는 중첩된 `audio.input` / `audio.output` 세션 설정 형식을 권장합니다

```python
runner = RealtimeRunner(
    starting_agent=agent,
    config={
        "model_settings": {
            "model_name": "gpt-realtime",
            "audio": {
                "input": {
                    "format": "pcm16",
                    "transcription": {"model": "gpt-4o-mini-transcribe"},
                    "turn_detection": {
                        "type": "semantic_vad",
                        "interrupt_response": True,
                    },
                },
                "output": {
                    "format": "pcm16",
                    "voice": "ash",
                },
            },
        }
    },
)
```

### 4. 세션 시작 및 입력 전송

`runner.run()` 은 `RealtimeSession` 을 반환합니다. 세션 컨텍스트에 진입하면 연결이 열립니다

```python
async def main() -> None:
    session = await runner.run()

    async with session:
        await session.send_message("Say hello in one short sentence.")

        async for event in session:
            if event.type == "audio":
                # Forward or play event.audio.data.
                pass
            elif event.type == "history_added":
                print(event.item)
            elif event.type == "agent_end":
                # One assistant turn finished.
                break
            elif event.type == "error":
                print(f"Error: {event.error}")


if __name__ == "__main__":
    asyncio.run(main())
```

`session.send_message()` 는 일반 문자열 또는 구조화된 실시간 메시지를 받을 수 있습니다. 원문 오디오 청크에는 [`session.send_audio()`][agents.realtime.session.RealtimeSession.send_audio]를 사용하세요

## 이 빠른 시작에 포함되지 않는 내용

-   마이크 캡처 및 스피커 재생 코드. [`examples/realtime`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime)의 실시간 예제를 참고하세요
-   SIP / 전화 연결 플로우. [실시간 전송](transport.md) 및 [SIP 섹션](guide.md#sip-and-telephony)을 참고하세요

## 주요 설정

기본 세션이 동작하면, 다음으로 가장 많이 사용하는 설정은 다음과 같습니다:

-   `model_name`
-   `audio.input.format`, `audio.output.format`
-   `audio.input.transcription`
-   `audio.input.noise_reduction`
-   자동 턴 감지를 위한 `audio.input.turn_detection`
-   `audio.output.voice`
-   `tool_choice`, `prompt`, `tracing`
-   `async_tool_calls`, `guardrails_settings.debounce_text_length`, `tool_error_formatter`

`input_audio_format`, `output_audio_format`, `input_audio_transcription`, `turn_detection` 같은 이전 평면 별칭도 여전히 동작하지만, 새 코드에서는 중첩된 `audio` 설정을 권장합니다

수동 턴 제어에는 [실시간 에이전트 가이드](guide.md#manual-response-control)에 설명된 원문 `session.update` / `input_audio_buffer.commit` / `response.create` 플로우를 사용하세요

전체 스키마는 [`RealtimeRunConfig`][agents.realtime.config.RealtimeRunConfig] 및 [`RealtimeSessionModelSettings`][agents.realtime.config.RealtimeSessionModelSettings]를 참고하세요

## 연결 옵션

환경 변수에 API 키를 설정하세요:

```bash
export OPENAI_API_KEY="your-api-key-here"
```

또는 세션 시작 시 직접 전달하세요:

```python
session = await runner.run(model_config={"api_key": "your-api-key"})
```

`model_config` 는 다음도 지원합니다:

-   `url`: 사용자 지정 WebSocket 엔드포인트
-   `headers`: 사용자 지정 요청 헤더
-   `call_id`: 기존 실시간 호출에 연결. 이 리포지토리에서 문서화된 연결 플로우는 SIP 입니다
-   `playback_tracker`: 사용자가 실제로 들은 오디오 양을 보고

`headers` 를 명시적으로 전달하면 SDK 는 `Authorization` 헤더를 **자동으로 주입하지 않습니다**

Azure OpenAI 에 연결할 때는 `model_config["url"]` 에 GA Realtime 엔드포인트 URL 과 명시적 헤더를 전달하세요. 실시간 에이전트에서는 레거시 베타 경로(`/openai/realtime?api-version=...`)를 피하세요. 자세한 내용은 [실시간 에이전트 가이드](guide.md#low-level-access-and-custom-endpoints)를 참고하세요

## 다음 단계

-   서버 측 WebSocket 과 SIP 중 선택하려면 [실시간 전송](transport.md)을 읽어보세요
-   라이프사이클, 구조화된 입력, 승인, 핸드오프, 가드레일, 저수준 제어는 [실시간 에이전트 가이드](guide.md)를 읽어보세요
-   [`examples/realtime`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime)의 예제를 살펴보세요

================
File: docs/ko/realtime/transport.md
================
---
search:
  exclude: true
---
# 실시간 전송

이 페이지를 사용해 실시간 에이전트가 Python 애플리케이션에 어떻게 맞는지 결정하세요

!!! note "Python SDK 경계"

    Python SDK에는 브라우저 WebRTC 전송이 **포함되지 않습니다**. 이 페이지는 Python SDK 전송 선택지만 다룹니다: 서버 측 WebSocket 및 SIP 연결 플로우. 브라우저 WebRTC는 별도의 플랫폼 주제이며, 공식 [WebRTC와 함께하는 Realtime API](https://developers.openai.com/api/docs/guides/realtime-webrtc/) 가이드에 문서화되어 있습니다.

## 결정 가이드

| 목표 | 시작점 | 이유 |
| --- | --- | --- |
| 서버에서 관리하는 실시간 앱 구축 | [빠른 시작](quickstart.md) | 기본 Python 경로는 `RealtimeRunner`가 관리하는 서버 측 WebSocket 세션입니다. |
| 어떤 전송 및 배포 형태를 선택할지 이해 | 이 페이지 | 전송 또는 배포 형태를 확정하기 전에 이 페이지를 사용하세요. |
| 전화 또는 SIP 통화에 에이전트 연결 | [실시간 가이드](guide.md) 및 [`examples/realtime/twilio_sip`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/twilio_sip) | 이 저장소는 `call_id`로 구동되는 SIP 연결 플로우를 제공합니다. |

## 서버 측 WebSocket 기본 Python 경로

`RealtimeRunner`는 사용자 정의 `RealtimeModel`을 전달하지 않는 한 `OpenAIRealtimeWebSocketModel`을 사용합니다.

즉, 표준 Python 토폴로지는 다음과 같습니다:

1. Python 서비스가 `RealtimeRunner`를 생성합니다.
2. `await runner.run()`이 `RealtimeSession`을 반환합니다.
3. 세션에 진입하고 텍스트, structured outputs 메시지 또는 오디오를 전송합니다.
4. `RealtimeSessionEvent` 항목을 소비하고 오디오 또는 전사본을 애플리케이션으로 전달합니다.

이 토폴로지는 핵심 데모 앱, CLI 예제, Twilio Media Streams 예제에서 사용됩니다:

-   [`examples/realtime/app`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/app)
-   [`examples/realtime/cli`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/cli)
-   [`examples/realtime/twilio`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/twilio)

서버가 오디오 파이프라인, 도구 실행, 승인 플로우, 히스토리 처리를 소유하는 경우 이 경로를 사용하세요.

## SIP 연결 전화 통신 경로

이 저장소에 문서화된 전화 통신 플로우에서는 Python SDK가 `call_id`를 통해 기존 실시간 통화에 연결됩니다.

이 토폴로지는 다음과 같습니다:

1. OpenAI가 `realtime.call.incoming` 같은 webhook을 서비스로 보냅니다.
2. 서비스가 Realtime Calls API를 통해 통화를 수락합니다.
3. Python 서비스가 `RealtimeRunner(..., model=OpenAIRealtimeSIPModel())`를 시작합니다.
4. 세션이 `model_config={"call_id": ...}`로 연결된 뒤, 다른 실시간 세션과 동일하게 이벤트를 처리합니다.

이 토폴로지는 [`examples/realtime/twilio_sip`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/twilio_sip)에 나와 있습니다.

더 넓은 Realtime API도 일부 서버 측 제어 패턴에 `call_id`를 사용하지만, 이 저장소에서 제공되는 연결 예제는 SIP입니다.

## 이 SDK 범위 외 브라우저 WebRTC

앱의 기본 클라이언트가 Realtime WebRTC를 사용하는 브라우저인 경우:

-   이 저장소의 Python SDK 문서 범위 밖으로 간주하세요
-   클라이언트 측 플로우와 이벤트 모델은 공식 [WebRTC와 함께하는 Realtime API](https://developers.openai.com/api/docs/guides/realtime-webrtc/) 및 [Realtime conversations](https://developers.openai.com/api/docs/guides/realtime-conversations/) 문서를 사용하세요
-   브라우저 WebRTC 클라이언트 위에 사이드밴드 서버 연결이 필요하면 공식 [Realtime server-side controls](https://developers.openai.com/api/docs/guides/realtime-server-controls/) 가이드를 사용하세요
-   이 저장소에서 브라우저 측 `RTCPeerConnection` 추상화나 즉시 사용 가능한 브라우저 WebRTC 샘플을 제공한다고 기대하지 마세요

또한 이 저장소는 현재 브라우저 WebRTC와 Python 사이드밴드를 함께 사용하는 예제를 제공하지 않습니다.

## 사용자 정의 엔드포인트 및 연결 지점

[`RealtimeModelConfig`][agents.realtime.model.RealtimeModelConfig]의 전송 구성 표면을 통해 기본 경로를 조정할 수 있습니다:

-   `url`: WebSocket 엔드포인트 재정의
-   `headers`: Azure 인증 헤더 같은 명시적 헤더 제공
-   `api_key`: API 키를 직접 또는 콜백을 통해 전달
-   `call_id`: 기존 실시간 통화에 연결. 이 저장소에서 문서화된 예제는 SIP입니다
-   `playback_tracker`: 인터럽션(중단 처리)을 위해 실제 재생 진행 상황 보고

토폴로지를 선택한 후 자세한 수명 주기 및 기능 표면은 [실시간 에이전트 가이드](guide.md)를 참조하세요.

================
File: docs/ko/sessions/advanced_sqlite_session.md
================
---
search:
  exclude: true
---
# 고급 SQLite 세션

`AdvancedSQLiteSession`은 기본 `SQLiteSession`의 향상된 버전으로, 대화 브랜칭, 상세 사용량 분석, 구조화된 대화 쿼리를 포함한 고급 대화 관리 기능을 제공합니다

## 기능

- **대화 브랜칭**: 모든 사용자 메시지에서 대체 대화 경로 생성
- **사용량 추적**: 전체 JSON 세부 내역과 함께 턴별 상세 토큰 사용량 분석
- **구조화된 쿼리**: 턴별 대화, 도구 사용 통계 등 조회
- **브랜치 관리**: 독립적인 브랜치 전환 및 관리
- **메시지 구조 메타데이터**: 메시지 유형, 도구 사용, 대화 흐름 추적

## 빠른 시작

```python
from agents import Agent, Runner
from agents.extensions.memory import AdvancedSQLiteSession

# Create agent
agent = Agent(
    name="Assistant",
    instructions="Reply very concisely.",
)

# Create an advanced session
session = AdvancedSQLiteSession(
    session_id="conversation_123",
    db_path="conversations.db",
    create_tables=True
)

# First conversation turn
result = await Runner.run(
    agent,
    "What city is the Golden Gate Bridge in?",
    session=session
)
print(result.final_output)  # "San Francisco"

# IMPORTANT: Store usage data
await session.store_run_usage(result)

# Continue conversation
result = await Runner.run(
    agent,
    "What state is it in?",
    session=session
)
print(result.final_output)  # "California"
await session.store_run_usage(result)
```

## 초기화

```python
from agents.extensions.memory import AdvancedSQLiteSession

# Basic initialization
session = AdvancedSQLiteSession(
    session_id="my_conversation",
    create_tables=True  # Auto-create advanced tables
)

# With persistent storage
session = AdvancedSQLiteSession(
    session_id="user_123",
    db_path="path/to/conversations.db",
    create_tables=True
)

# With custom logger
import logging
logger = logging.getLogger("my_app")
session = AdvancedSQLiteSession(
    session_id="session_456",
    create_tables=True,
    logger=logger
)
```

### 매개변수

- `session_id` (str): 대화 세션의 고유 식별자
- `db_path` (str | Path): SQLite 데이터베이스 파일 경로. 기본값은 인메모리 저장을 위한 `:memory:`
- `create_tables` (bool): 고급 테이블을 자동으로 생성할지 여부. 기본값은 `False`
- `logger` (logging.Logger | None): 세션용 사용자 지정 로거. 기본값은 모듈 로거

## 사용량 추적

AdvancedSQLiteSession은 대화 턴별 토큰 사용량 데이터를 저장하여 상세 사용량 분석을 제공합니다. **이는 각 에이전트 실행 후 `store_run_usage` 메서드가 호출되는지에 전적으로 의존합니다.**

### 사용량 데이터 저장

```python
# After each agent run, store the usage data
result = await Runner.run(agent, "Hello", session=session)
await session.store_run_usage(result)

# This stores:
# - Total tokens used
# - Input/output token breakdown
# - Request count
# - Detailed JSON token information (if available)
```

### 사용량 통계 조회

```python
# Get session-level usage (all branches)
session_usage = await session.get_session_usage()
if session_usage:
    print(f"Total requests: {session_usage['requests']}")
    print(f"Total tokens: {session_usage['total_tokens']}")
    print(f"Input tokens: {session_usage['input_tokens']}")
    print(f"Output tokens: {session_usage['output_tokens']}")
    print(f"Total turns: {session_usage['total_turns']}")

# Get usage for specific branch
branch_usage = await session.get_session_usage(branch_id="main")

# Get usage by turn
turn_usage = await session.get_turn_usage()
for turn_data in turn_usage:
    print(f"Turn {turn_data['user_turn_number']}: {turn_data['total_tokens']} tokens")
    if turn_data['input_tokens_details']:
        print(f"  Input details: {turn_data['input_tokens_details']}")
    if turn_data['output_tokens_details']:
        print(f"  Output details: {turn_data['output_tokens_details']}")

# Get usage for specific turn
turn_2_usage = await session.get_turn_usage(user_turn_number=2)
```

## 대화 브랜칭

AdvancedSQLiteSession의 핵심 기능 중 하나는 모든 사용자 메시지에서 대화 브랜치를 생성할 수 있다는 점이며, 이를 통해 대체 대화 경로를 탐색할 수 있습니다.

### 브랜치 생성

```python
# Get available turns for branching
turns = await session.get_conversation_turns()
for turn in turns:
    print(f"Turn {turn['turn']}: {turn['content']}")
    print(f"Can branch: {turn['can_branch']}")

# Create a branch from turn 2
branch_id = await session.create_branch_from_turn(2)
print(f"Created branch: {branch_id}")

# Create a branch with custom name
branch_id = await session.create_branch_from_turn(
    2, 
    branch_name="alternative_path"
)

# Create branch by searching for content
branch_id = await session.create_branch_from_content(
    "weather", 
    branch_name="weather_focus"
)
```

### 브랜치 관리

```python
# List all branches
branches = await session.list_branches()
for branch in branches:
    current = " (current)" if branch["is_current"] else ""
    print(f"{branch['branch_id']}: {branch['user_turns']} turns, {branch['message_count']} messages{current}")

# Switch between branches
await session.switch_to_branch("main")
await session.switch_to_branch(branch_id)

# Delete a branch
await session.delete_branch(branch_id, force=True)  # force=True allows deleting current branch
```

### 브랜치 워크플로 예제

```python
# Original conversation
result = await Runner.run(agent, "What's the capital of France?", session=session)
await session.store_run_usage(result)

result = await Runner.run(agent, "What's the weather like there?", session=session)
await session.store_run_usage(result)

# Create branch from turn 2 (weather question)
branch_id = await session.create_branch_from_turn(2, "weather_focus")

# Continue in new branch with different question
result = await Runner.run(
    agent, 
    "What are the main tourist attractions in Paris?", 
    session=session
)
await session.store_run_usage(result)

# Switch back to main branch
await session.switch_to_branch("main")

# Continue original conversation
result = await Runner.run(
    agent, 
    "How expensive is it to visit?", 
    session=session
)
await session.store_run_usage(result)
```

## 구조화된 쿼리

AdvancedSQLiteSession은 대화 구조와 내용을 분석하기 위한 여러 메서드를 제공합니다.

### 대화 분석

```python
# Get conversation organized by turns
conversation_by_turns = await session.get_conversation_by_turns()
for turn_num, items in conversation_by_turns.items():
    print(f"Turn {turn_num}: {len(items)} items")
    for item in items:
        if item["tool_name"]:
            print(f"  - {item['type']} (tool: {item['tool_name']})")
        else:
            print(f"  - {item['type']}")

# Get tool usage statistics
tool_usage = await session.get_tool_usage()
for tool_name, count, turn in tool_usage:
    print(f"{tool_name}: used {count} times in turn {turn}")

# Find turns by content
matching_turns = await session.find_turns_by_content("weather")
for turn in matching_turns:
    print(f"Turn {turn['turn']}: {turn['content']}")
```

### 메시지 구조

세션은 다음을 포함한 메시지 구조를 자동으로 추적합니다:

- 메시지 유형(user, assistant, tool_call 등)
- 도구 호출의 도구 이름
- 턴 번호 및 시퀀스 번호
- 브랜치 연결
- 타임스탬프

## 데이터베이스 스키마

AdvancedSQLiteSession은 기본 SQLite 스키마를 두 개의 추가 테이블로 확장합니다:

### message_structure 테이블

```sql
CREATE TABLE message_structure (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    message_id INTEGER NOT NULL,
    branch_id TEXT NOT NULL DEFAULT 'main',
    message_type TEXT NOT NULL,
    sequence_number INTEGER NOT NULL,
    user_turn_number INTEGER,
    branch_turn_number INTEGER,
    tool_name TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES agent_sessions(session_id) ON DELETE CASCADE,
    FOREIGN KEY (message_id) REFERENCES agent_messages(id) ON DELETE CASCADE
);
```

### turn_usage 테이블

```sql
CREATE TABLE turn_usage (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    branch_id TEXT NOT NULL DEFAULT 'main',
    user_turn_number INTEGER NOT NULL,
    requests INTEGER DEFAULT 0,
    input_tokens INTEGER DEFAULT 0,
    output_tokens INTEGER DEFAULT 0,
    total_tokens INTEGER DEFAULT 0,
    input_tokens_details JSON,
    output_tokens_details JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES agent_sessions(session_id) ON DELETE CASCADE,
    UNIQUE(session_id, branch_id, user_turn_number)
);
```

## 전체 예제

모든 기능을 종합적으로 시연하는 [전체 예제](https://github.com/openai/openai-agents-python/tree/main/examples/memory/advanced_sqlite_session_example.py)를 확인하세요


## API 참조

- [`AdvancedSQLiteSession`][agents.extensions.memory.advanced_sqlite_session.AdvancedSQLiteSession] - 메인 클래스
- [`Session`][agents.memory.session.Session] - 기본 세션 프로토콜

================
File: docs/ko/sessions/encrypted_session.md
================
---
search:
  exclude: true
---
# 암호화된 세션

`EncryptedSession`은 모든 세션 구현에 대해 투명한 암호화를 제공하며, 오래된 항목의 자동 만료로 대화 데이터를 안전하게 보호합니다.

## 기능

- **투명한 암호화**: Fernet 암호화로 모든 세션을 래핑합니다
- **세션별 키**: 세션마다 고유한 암호화를 위해 HKDF 키 파생을 사용합니다
- **자동 만료**: TTL이 만료되면 오래된 항목을 자동으로 건너뜁니다
- **즉시 교체 가능**: 기존의 모든 세션 구현과 함께 작동합니다

## 설치

암호화된 세션을 사용하려면 `encrypt` extra가 필요합니다:

```bash
pip install openai-agents[encrypt]
```

## 빠른 시작

```python
import asyncio
from agents import Agent, Runner
from agents.extensions.memory import EncryptedSession, SQLAlchemySession

async def main():
    agent = Agent("Assistant")
    
    # Create underlying session
    underlying_session = SQLAlchemySession.from_url(
        "user-123",
        url="sqlite+aiosqlite:///:memory:",
        create_tables=True
    )
    
    # Wrap with encryption
    session = EncryptedSession(
        session_id="user-123",
        underlying_session=underlying_session,
        encryption_key="your-secret-key-here",
        ttl=600  # 10 minutes
    )
    
    result = await Runner.run(agent, "Hello", session=session)
    print(result.final_output)

if __name__ == "__main__":
    asyncio.run(main())
```

## 구성

### 암호화 키

암호화 키는 Fernet 키 또는 임의의 문자열이 될 수 있습니다:

```python
from agents.extensions.memory import EncryptedSession

# Using a Fernet key (base64-encoded)
session = EncryptedSession(
    session_id="user-123",
    underlying_session=underlying_session,
    encryption_key="your-fernet-key-here",
    ttl=600
)

# Using a raw string (will be derived to a key)
session = EncryptedSession(
    session_id="user-123", 
    underlying_session=underlying_session,
    encryption_key="my-secret-password",
    ttl=600
)
```

### TTL (유효 기간)

암호화된 항목이 유효하게 유지되는 시간을 설정합니다:

```python
# Items expire after 1 hour
session = EncryptedSession(
    session_id="user-123",
    underlying_session=underlying_session,
    encryption_key="secret",
    ttl=3600  # 1 hour in seconds
)

# Items expire after 1 day
session = EncryptedSession(
    session_id="user-123",
    underlying_session=underlying_session,
    encryption_key="secret", 
    ttl=86400  # 24 hours in seconds
)
```

## 다양한 세션 유형과의 사용

### SQLite 세션과 함께 사용

```python
from agents import SQLiteSession
from agents.extensions.memory import EncryptedSession

# Create encrypted SQLite session
underlying = SQLiteSession("user-123", "conversations.db")

session = EncryptedSession(
    session_id="user-123",
    underlying_session=underlying,
    encryption_key="secret-key"
)
```

### SQLAlchemy 세션과 함께 사용

```python
from agents.extensions.memory import EncryptedSession, SQLAlchemySession

# Create encrypted SQLAlchemy session
underlying = SQLAlchemySession.from_url(
    "user-123",
    url="postgresql+asyncpg://user:pass@localhost/db",
    create_tables=True
)

session = EncryptedSession(
    session_id="user-123",
    underlying_session=underlying,
    encryption_key="secret-key"
)
```

!!! warning "고급 세션 기능"

    `AdvancedSQLiteSession` 같은 고급 세션 구현과 `EncryptedSession`을 함께 사용할 때는 다음을 유의하세요:

    - 메시지 콘텐츠가 암호화되므로 `find_turns_by_content()` 같은 메서드는 효과적으로 작동하지 않습니다
    - 콘텐츠 기반 검색은 암호화된 데이터에서 수행되므로 효과가 제한됩니다



## 키 파생

EncryptedSession은 세션별 고유 암호화 키를 파생하기 위해 HKDF(HMAC 기반 키 파생 함수)를 사용합니다:

- **마스터 키**: 제공한 암호화 키
- **세션 솔트**: 세션 ID
- **정보 문자열**: `"agents.session-store.hkdf.v1"`
- **출력**: 32바이트 Fernet 키

이를 통해 다음이 보장됩니다:
- 각 세션은 고유한 암호화 키를 가집니다
- 마스터 키 없이는 키를 파생할 수 없습니다
- 세션 데이터는 서로 다른 세션 간에 복호화할 수 없습니다

## 자동 만료

항목이 TTL을 초과하면 조회 중 자동으로 건너뜁니다:

```python
# Items older than TTL are silently ignored
items = await session.get_items()  # Only returns non-expired items

# Expired items don't affect session behavior
result = await Runner.run(agent, "Continue conversation", session=session)
```

## API 참조

- [`EncryptedSession`][agents.extensions.memory.encrypt_session.EncryptedSession] - 주요 클래스
- [`Session`][agents.memory.session.Session] - 기본 세션 프로토콜

================
File: docs/ko/sessions/index.md
================
---
search:
  exclude: true
---
# 세션

Agents SDK 는 내장 세션 메모리를 제공하여 여러 에이전트 실행에 걸쳐 대화 기록을 자동으로 유지하며, 턴 사이에 `.to_input_list()` 를 수동으로 처리할 필요를 없애줍니다

Sessions 는 특정 세션의 대화 기록을 저장하여, 명시적인 수동 메모리 관리 없이도 에이전트가 컨텍스트를 유지할 수 있게 합니다. 이는 에이전트가 이전 상호작용을 기억하길 원하는 채팅 애플리케이션이나 멀티턴 대화를 구축할 때 특히 유용합니다

SDK 가 클라이언트 측 메모리를 대신 관리하길 원할 때 sessions 를 사용하세요. Sessions 는 동일 실행에서 `conversation_id`, `previous_response_id`, `auto_previous_response_id` 와 함께 사용할 수 없습니다. 대신 OpenAI 서버 관리형 continuation 을 원한다면, 세션을 덧씌우기보다 해당 메커니즘 중 하나를 선택하세요

## 빠른 시작

```python
from agents import Agent, Runner, SQLiteSession

# Create agent
agent = Agent(
    name="Assistant",
    instructions="Reply very concisely.",
)

# Create a session instance with a session ID
session = SQLiteSession("conversation_123")

# First turn
result = await Runner.run(
    agent,
    "What city is the Golden Gate Bridge in?",
    session=session
)
print(result.final_output)  # "San Francisco"

# Second turn - agent automatically remembers previous context
result = await Runner.run(
    agent,
    "What state is it in?",
    session=session
)
print(result.final_output)  # "California"

# Also works with synchronous runner
result = Runner.run_sync(
    agent,
    "What's the population?",
    session=session
)
print(result.final_output)  # "Approximately 39 million"
```

## 동일 세션으로 인터럽트된 실행 재개

실행이 승인 대기 상태로 일시 중지되면, 동일한 세션 인스턴스(또는 동일한 백킹 스토어를 가리키는 다른 세션 인스턴스)로 재개하여 재개된 턴이 동일한 저장 대화 기록을 이어가도록 하세요

```python
result = await Runner.run(agent, "Delete temporary files that are no longer needed.", session=session)

if result.interruptions:
    state = result.to_state()
    for interruption in result.interruptions:
        state.approve(interruption)
    result = await Runner.run(agent, state, session=session)
```

## 핵심 세션 동작

세션 메모리가 활성화되면:

1. **각 실행 전**: runner 가 세션의 대화 기록을 자동으로 가져와 입력 항목 앞에 추가합니다
2. **각 실행 후**: 실행 중 생성된 모든 새 항목(사용자 입력, 어시스턴트 응답, 도구 호출 등)이 세션에 자동 저장됩니다
3. **컨텍스트 보존**: 동일한 세션으로 이후 실행할 때마다 전체 대화 기록이 포함되어, 에이전트가 컨텍스트를 유지할 수 있습니다

이로써 실행 사이에 `.to_input_list()` 를 수동 호출하고 대화 상태를 관리할 필요가 없어집니다

## 기록과 새 입력 병합 제어

세션을 전달하면, runner 는 일반적으로 다음과 같이 모델 입력을 준비합니다:

1. 세션 기록(`session.get_items(...)` 에서 조회)
2. 새 턴 입력

모델 호출 전에 이 병합 단계를 사용자 지정하려면 [`RunConfig.session_input_callback`][agents.run.RunConfig.session_input_callback] 을 사용하세요. 콜백은 두 개의 리스트를 받습니다:

-   `history`: 조회된 세션 기록(이미 입력 항목 형식으로 정규화됨)
-   `new_input`: 현재 턴의 새 입력 항목

모델에 전송할 최종 입력 항목 리스트를 반환하세요

콜백은 두 리스트의 복사본을 받으므로 안전하게 변경할 수 있습니다. 반환된 리스트는 해당 턴의 모델 입력을 제어하지만, SDK 는 여전히 새 턴에 속한 항목만 저장합니다. 따라서 이전 기록을 재정렬하거나 필터링해도 오래된 세션 항목이 새 입력으로 다시 저장되지는 않습니다

```python
from agents import Agent, RunConfig, Runner, SQLiteSession


def keep_recent_history(history, new_input):
    # Keep only the last 10 history items, then append the new turn.
    return history[-10:] + new_input


agent = Agent(name="Assistant")
session = SQLiteSession("conversation_123")

result = await Runner.run(
    agent,
    "Continue from the latest updates only.",
    session=session,
    run_config=RunConfig(session_input_callback=keep_recent_history),
)
```

세션이 항목을 저장하는 방식을 바꾸지 않고 사용자 지정 가지치기, 재정렬, 선택적 기록 포함이 필요할 때 이를 사용하세요. 모델 호출 직전에 더 늦은 최종 패스가 필요하면 [running agents guide](../running_agents.md) 의 [`call_model_input_filter`][agents.run.RunConfig.call_model_input_filter] 를 사용하세요

## 조회 기록 제한

각 실행 전에 가져올 기록 양을 제어하려면 [`SessionSettings`][agents.memory.SessionSettings] 를 사용하세요

-   `SessionSettings(limit=None)` (기본값): 사용 가능한 모든 세션 항목 조회
-   `SessionSettings(limit=N)`: 가장 최근 `N` 개 항목만 조회

[`RunConfig.session_settings`][agents.run.RunConfig.session_settings] 로 실행 단위로 적용할 수 있습니다:

```python
from agents import Agent, RunConfig, Runner, SessionSettings, SQLiteSession

agent = Agent(name="Assistant")
session = SQLiteSession("conversation_123")

result = await Runner.run(
    agent,
    "Summarize our recent discussion.",
    session=session,
    run_config=RunConfig(session_settings=SessionSettings(limit=50)),
)
```

세션 구현이 기본 세션 설정을 제공하는 경우, `RunConfig.session_settings` 는 해당 실행에서 `None` 이 아닌 값을 우선 적용합니다. 이는 긴 대화에서 세션의 기본 동작을 변경하지 않고 조회 크기를 제한하고 싶을 때 유용합니다

## 메모리 작업

### 기본 작업

Sessions 는 대화 기록 관리를 위한 여러 작업을 지원합니다:

```python
from agents import SQLiteSession

session = SQLiteSession("user_123", "conversations.db")

# Get all items in a session
items = await session.get_items()

# Add new items to a session
new_items = [
    {"role": "user", "content": "Hello"},
    {"role": "assistant", "content": "Hi there!"}
]
await session.add_items(new_items)

# Remove and return the most recent item
last_item = await session.pop_item()
print(last_item)  # {"role": "assistant", "content": "Hi there!"}

# Clear all items from a session
await session.clear_session()
```

### 수정용 pop_item 사용

`pop_item` 메서드는 대화의 마지막 항목을 되돌리거나 수정하려 할 때 특히 유용합니다:

```python
from agents import Agent, Runner, SQLiteSession

agent = Agent(name="Assistant")
session = SQLiteSession("correction_example")

# Initial conversation
result = await Runner.run(
    agent,
    "What's 2 + 2?",
    session=session
)
print(f"Agent: {result.final_output}")

# User wants to correct their question
assistant_item = await session.pop_item()  # Remove agent's response
user_item = await session.pop_item()  # Remove user's question

# Ask a corrected question
result = await Runner.run(
    agent,
    "What's 2 + 3?",
    session=session
)
print(f"Agent: {result.final_output}")
```

## 내장 세션 구현

SDK 는 다양한 사용 사례를 위한 여러 세션 구현을 제공합니다:

### 내장 세션 구현 선택

아래의 상세 예시를 읽기 전에 시작점을 선택하려면 이 표를 사용하세요

| Session type | Best for | Notes |
| --- | --- | --- |
| `SQLiteSession` | 로컬 개발 및 단순 앱 | 내장형, 경량, 파일 기반 또는 인메모리 |
| `AsyncSQLiteSession` | `aiosqlite` 를 사용하는 비동기 SQLite | 비동기 드라이버 지원 확장 백엔드 |
| `RedisSession` | 워커/서비스 간 공유 메모리 | 저지연 분산 배포에 적합 |
| `SQLAlchemySession` | 기존 데이터베이스가 있는 프로덕션 앱 | SQLAlchemy 가 지원하는 데이터베이스에서 동작 |
| `DaprSession` | Dapr 사이드카 기반 클라우드 네이티브 배포 | TTL 및 일관성 제어와 함께 여러 state store 지원 |
| `OpenAIConversationsSession` | OpenAI 의 서버 관리형 스토리지 | OpenAI Conversations API 기반 기록 |
| `OpenAIResponsesCompactionSession` | 자동 컴팩션이 필요한 긴 대화 | 다른 세션 백엔드를 감싸는 래퍼 |
| `AdvancedSQLiteSession` | 브랜칭/분석이 포함된 SQLite | 기능이 더 많음, 전용 페이지 참조 |
| `EncryptedSession` | 다른 세션 위의 암호화 + TTL | 래퍼, 먼저 기반 백엔드 선택 필요 |

일부 구현에는 추가 세부 정보를 담은 전용 페이지가 있으며, 해당 하위 섹션에 인라인 링크되어 있습니다

### OpenAI Conversations API 세션

`OpenAIConversationsSession` 을 통해 [OpenAI's Conversations API](https://platform.openai.com/docs/api-reference/conversations) 를 사용하세요

```python
from agents import Agent, Runner, OpenAIConversationsSession

# Create agent
agent = Agent(
    name="Assistant",
    instructions="Reply very concisely.",
)

# Create a new conversation
session = OpenAIConversationsSession()

# Optionally resume a previous conversation by passing a conversation ID
# session = OpenAIConversationsSession(conversation_id="conv_123")

# Start conversation
result = await Runner.run(
    agent,
    "What city is the Golden Gate Bridge in?",
    session=session
)
print(result.final_output)  # "San Francisco"

# Continue the conversation
result = await Runner.run(
    agent,
    "What state is it in?",
    session=session
)
print(result.final_output)  # "California"
```

### OpenAI Responses 컴팩션 세션

Responses API(`responses.compact`)로 저장된 대화 기록을 컴팩트하려면 `OpenAIResponsesCompactionSession` 을 사용하세요. 이는 기반 세션을 감싸며 `should_trigger_compaction` 에 따라 각 턴 후 자동 컴팩션할 수 있습니다. `OpenAIConversationsSession` 을 이것으로 감싸지 마세요. 두 기능은 기록을 서로 다른 방식으로 관리합니다

#### 일반적인 사용법(자동 컴팩션)

```python
from agents import Agent, Runner, SQLiteSession
from agents.memory import OpenAIResponsesCompactionSession

underlying = SQLiteSession("conversation_123")
session = OpenAIResponsesCompactionSession(
    session_id="conversation_123",
    underlying_session=underlying,
)

agent = Agent(name="Assistant")
result = await Runner.run(agent, "Hello", session=session)
print(result.final_output)
```

기본적으로 컴팩션은 후보 임곗값에 도달하면 각 턴 후 실행됩니다

`compaction_mode="previous_response_id"` 는 이미 Responses API 응답 ID 로 턴을 체이닝하고 있을 때 가장 잘 작동합니다. `compaction_mode="input"` 은 대신 현재 세션 항목으로 컴팩션 요청을 재구성하며, 응답 체인을 사용할 수 없거나 세션 콘텐츠를 신뢰 가능한 단일 소스로 삼고 싶을 때 유용합니다. 기본값 `"auto"` 는 사용 가능한 가장 안전한 옵션을 선택합니다

#### 자동 컴팩션은 스트리밍을 지연시킬 수 있음

컴팩션은 세션 기록을 지우고 다시 작성하므로, SDK 는 실행 완료로 간주하기 전에 컴팩션이 끝날 때까지 기다립니다. 스트리밍 모드에서는 컴팩션이 무거울 경우 마지막 출력 토큰 이후에도 `run.stream_events()` 가 몇 초간 열린 상태로 남을 수 있습니다

저지연 스트리밍이나 빠른 턴 전환이 필요하다면 자동 컴팩션을 비활성화하고 턴 사이(또는 유휴 시간)에 `run_compaction()` 을 직접 호출하세요. 자체 기준에 따라 컴팩션 강제 시점을 결정할 수 있습니다

```python
from agents import Agent, Runner, SQLiteSession
from agents.memory import OpenAIResponsesCompactionSession

underlying = SQLiteSession("conversation_123")
session = OpenAIResponsesCompactionSession(
    session_id="conversation_123",
    underlying_session=underlying,
    # Disable triggering the auto compaction
    should_trigger_compaction=lambda _: False,
)

agent = Agent(name="Assistant")
result = await Runner.run(agent, "Hello", session=session)

# Decide when to compact (e.g., on idle, every N turns, or size thresholds).
await session.run_compaction({"force": True})
```

### SQLite 세션

SQLite 를 사용하는 기본 경량 세션 구현:

```python
from agents import SQLiteSession

# In-memory database (lost when process ends)
session = SQLiteSession("user_123")

# Persistent file-based database
session = SQLiteSession("user_123", "conversations.db")

# Use the session
result = await Runner.run(
    agent,
    "Hello",
    session=session
)
```

### 비동기 SQLite 세션

`aiosqlite` 기반 SQLite 영속성이 필요하면 `AsyncSQLiteSession` 을 사용하세요

```bash
pip install aiosqlite
```

```python
from agents import Agent, Runner
from agents.extensions.memory import AsyncSQLiteSession

agent = Agent(name="Assistant")
session = AsyncSQLiteSession("user_123", db_path="conversations.db")
result = await Runner.run(agent, "Hello", session=session)
```

### Redis 세션

여러 워커 또는 서비스 간 공유 세션 메모리가 필요하면 `RedisSession` 을 사용하세요

```bash
pip install openai-agents[redis]
```

```python
from agents import Agent, Runner
from agents.extensions.memory import RedisSession

agent = Agent(name="Assistant")
session = RedisSession.from_url(
    "user_123",
    url="redis://localhost:6379/0",
)
result = await Runner.run(agent, "Hello", session=session)
```

### SQLAlchemy 세션

SQLAlchemy 가 지원하는 모든 데이터베이스를 사용하는 프로덕션 준비 세션:

```python
from agents.extensions.memory import SQLAlchemySession

# Using database URL
session = SQLAlchemySession.from_url(
    "user_123",
    url="postgresql+asyncpg://user:pass@localhost/db",
    create_tables=True
)

# Using existing engine
from sqlalchemy.ext.asyncio import create_async_engine
engine = create_async_engine("postgresql+asyncpg://user:pass@localhost/db")
session = SQLAlchemySession("user_123", engine=engine, create_tables=True)
```

자세한 문서는 [SQLAlchemy Sessions](sqlalchemy_session.md) 를 참고하세요

### Dapr 세션

이미 Dapr 사이드카를 운영 중이거나, 에이전트 코드를 바꾸지 않고 서로 다른 state-store 백엔드 간 이동 가능한 세션 스토리지를 원하면 `DaprSession` 을 사용하세요

```bash
pip install openai-agents[dapr]
```

```python
from agents import Agent, Runner
from agents.extensions.memory import DaprSession

agent = Agent(name="Assistant")

async with DaprSession.from_address(
    "user_123",
    state_store_name="statestore",
    dapr_address="localhost:50001",
) as session:
    result = await Runner.run(agent, "Hello", session=session)
    print(result.final_output)
```

참고:

-   `from_address(...)` 는 Dapr 클라이언트를 생성하고 소유합니다. 앱이 이미 클라이언트를 관리한다면 `dapr_client=...` 와 함께 `DaprSession(...)` 을 직접 생성하세요
-   백킹 state store 가 TTL 을 지원할 때 오래된 세션 데이터가 자동 만료되도록 `ttl=...` 을 전달하세요
-   더 강한 read-after-write 보장이 필요하면 `consistency=DAPR_CONSISTENCY_STRONG` 을 전달하세요
-   Dapr Python SDK 는 HTTP 사이드카 엔드포인트도 확인합니다. 로컬 개발에서는 `dapr_address` 에 사용하는 gRPC 포트와 함께 `--dapr-http-port 3500` 으로 Dapr 를 시작하세요
-   로컬 컴포넌트 및 문제 해결을 포함한 전체 설정 안내는 [`examples/memory/dapr_session_example.py`](https://github.com/openai/openai-agents-python/tree/main/examples/memory/dapr_session_example.py) 를 참고하세요


### 고급 SQLite 세션

대화 브랜칭, 사용량 분석, 구조화 쿼리를 포함한 향상된 SQLite 세션:

```python
from agents.extensions.memory import AdvancedSQLiteSession

# Create with advanced features
session = AdvancedSQLiteSession(
    session_id="user_123",
    db_path="conversations.db",
    create_tables=True
)

# Automatic usage tracking
result = await Runner.run(agent, "Hello", session=session)
await session.store_run_usage(result)  # Track token usage

# Conversation branching
await session.create_branch_from_turn(2)  # Branch from turn 2
```

자세한 문서는 [Advanced SQLite Sessions](advanced_sqlite_session.md) 를 참고하세요

### 암호화 세션

모든 세션 구현을 위한 투명 암호화 래퍼:

```python
from agents.extensions.memory import EncryptedSession, SQLAlchemySession

# Create underlying session
underlying_session = SQLAlchemySession.from_url(
    "user_123",
    url="sqlite+aiosqlite:///conversations.db",
    create_tables=True
)

# Wrap with encryption and TTL
session = EncryptedSession(
    session_id="user_123",
    underlying_session=underlying_session,
    encryption_key="your-secret-key",
    ttl=600  # 10 minutes
)

result = await Runner.run(agent, "Hello", session=session)
```

자세한 문서는 [Encrypted Sessions](encrypted_session.md) 를 참고하세요

### 기타 세션 유형

추가 내장 옵션이 몇 가지 더 있습니다. `examples/memory/` 및 `extensions/memory/` 아래 소스 코드를 참고하세요

## 운영 패턴

### 세션 ID 명명

대화 정리에 도움이 되는 의미 있는 세션 ID 를 사용하세요:

-   사용자 기반: `"user_12345"`
-   스레드 기반: `"thread_abc123"`
-   컨텍스트 기반: `"support_ticket_456"`

### 메모리 영속성

-   임시 대화에는 인메모리 SQLite (`SQLiteSession("session_id")`) 사용
-   영구 대화에는 파일 기반 SQLite (`SQLiteSession("session_id", "path/to/db.sqlite")`) 사용
-   `aiosqlite` 기반 구현이 필요할 때 비동기 SQLite (`AsyncSQLiteSession("session_id", db_path="...")`) 사용
-   공유형 저지연 세션 메모리에는 Redis 기반 세션(`RedisSession.from_url("session_id", url="redis://...")`) 사용
-   SQLAlchemy 가 지원하는 기존 데이터베이스를 갖춘 프로덕션 시스템에는 SQLAlchemy 기반 세션(`SQLAlchemySession("session_id", engine=engine, create_tables=True)`) 사용
-   내장 텔레메트리, 트레이싱, 데이터 격리와 함께 30개 이상의 데이터베이스 백엔드를 지원하는 프로덕션 클라우드 네이티브 배포에는 Dapr state store 세션(`DaprSession.from_address("session_id", state_store_name="statestore", dapr_address="localhost:50001")`) 사용
-   기록을 OpenAI Conversations API 에 저장하려면 OpenAI 호스트하는 도구 스토리지(`OpenAIConversationsSession()`) 사용
-   모든 세션을 투명 암호화 및 TTL 기반 만료로 감싸려면 암호화 세션(`EncryptedSession(session_id, underlying_session, encryption_key)`) 사용
-   고급 사용 사례에서는 다른 프로덕션 시스템(예: Django)을 위한 사용자 정의 세션 백엔드 구현 고려

### 다중 세션

```python
from agents import Agent, Runner, SQLiteSession

agent = Agent(name="Assistant")

# Different sessions maintain separate conversation histories
session_1 = SQLiteSession("user_123", "conversations.db")
session_2 = SQLiteSession("user_456", "conversations.db")

result1 = await Runner.run(
    agent,
    "Help me with my account",
    session=session_1
)
result2 = await Runner.run(
    agent,
    "What are my charges?",
    session=session_2
)
```

### 세션 공유

```python
# Different agents can share the same session
support_agent = Agent(name="Support")
billing_agent = Agent(name="Billing")
session = SQLiteSession("user_123")

# Both agents will see the same conversation history
result1 = await Runner.run(
    support_agent,
    "Help me with my account",
    session=session
)
result2 = await Runner.run(
    billing_agent,
    "What are my charges?",
    session=session
)
```

## 전체 예제

세션 메모리 동작을 보여주는 전체 예제입니다:

```python
import asyncio
from agents import Agent, Runner, SQLiteSession


async def main():
    # Create an agent
    agent = Agent(
        name="Assistant",
        instructions="Reply very concisely.",
    )

    # Create a session instance that will persist across runs
    session = SQLiteSession("conversation_123", "conversation_history.db")

    print("=== Sessions Example ===")
    print("The agent will remember previous messages automatically.\n")

    # First turn
    print("First turn:")
    print("User: What city is the Golden Gate Bridge in?")
    result = await Runner.run(
        agent,
        "What city is the Golden Gate Bridge in?",
        session=session
    )
    print(f"Assistant: {result.final_output}")
    print()

    # Second turn - the agent will remember the previous conversation
    print("Second turn:")
    print("User: What state is it in?")
    result = await Runner.run(
        agent,
        "What state is it in?",
        session=session
    )
    print(f"Assistant: {result.final_output}")
    print()

    # Third turn - continuing the conversation
    print("Third turn:")
    print("User: What's the population of that state?")
    result = await Runner.run(
        agent,
        "What's the population of that state?",
        session=session
    )
    print(f"Assistant: {result.final_output}")
    print()

    print("=== Conversation Complete ===")
    print("Notice how the agent remembered the context from previous turns!")
    print("Sessions automatically handles conversation history.")


if __name__ == "__main__":
    asyncio.run(main())
```

## 사용자 정의 세션 구현

[`Session`][agents.memory.session.Session] 프로토콜을 따르는 클래스를 만들어 자체 세션 메모리를 구현할 수 있습니다:

```python
from agents.memory.session import SessionABC
from agents.items import TResponseInputItem
from typing import List

class MyCustomSession(SessionABC):
    """Custom session implementation following the Session protocol."""

    def __init__(self, session_id: str):
        self.session_id = session_id
        # Your initialization here

    async def get_items(self, limit: int | None = None) -> List[TResponseInputItem]:
        """Retrieve conversation history for this session."""
        # Your implementation here
        pass

    async def add_items(self, items: List[TResponseInputItem]) -> None:
        """Store new items for this session."""
        # Your implementation here
        pass

    async def pop_item(self) -> TResponseInputItem | None:
        """Remove and return the most recent item from this session."""
        # Your implementation here
        pass

    async def clear_session(self) -> None:
        """Clear all items for this session."""
        # Your implementation here
        pass

# Use your custom session
agent = Agent(name="Assistant")
result = await Runner.run(
    agent,
    "Hello",
    session=MyCustomSession("my_session")
)
```

## 커뮤니티 세션 구현

커뮤니티에서 추가 세션 구현을 개발했습니다:

| Package | Description |
|---------|-------------|
| [openai-django-sessions](https://pypi.org/project/openai-django-sessions/) | Django 가 지원하는 모든 데이터베이스(PostgreSQL, MySQL, SQLite 등)를 위한 Django ORM 기반 세션 |

세션 구현을 만들었다면, 여기에 추가할 수 있도록 문서 PR 제출을 환영합니다!

## API 레퍼런스

자세한 API 문서는 다음을 참고하세요:

-   [`Session`][agents.memory.session.Session] - 프로토콜 인터페이스
-   [`OpenAIConversationsSession`][agents.memory.OpenAIConversationsSession] - OpenAI Conversations API 구현
-   [`OpenAIResponsesCompactionSession`][agents.memory.openai_responses_compaction_session.OpenAIResponsesCompactionSession] - Responses API 컴팩션 래퍼
-   [`SQLiteSession`][agents.memory.sqlite_session.SQLiteSession] - 기본 SQLite 구현
-   [`AsyncSQLiteSession`][agents.extensions.memory.async_sqlite_session.AsyncSQLiteSession] - `aiosqlite` 기반 비동기 SQLite 구현
-   [`RedisSession`][agents.extensions.memory.redis_session.RedisSession] - Redis 기반 세션 구현
-   [`SQLAlchemySession`][agents.extensions.memory.sqlalchemy_session.SQLAlchemySession] - SQLAlchemy 기반 구현
-   [`DaprSession`][agents.extensions.memory.dapr_session.DaprSession] - Dapr state store 구현
-   [`AdvancedSQLiteSession`][agents.extensions.memory.advanced_sqlite_session.AdvancedSQLiteSession] - 브랜칭 및 분석이 포함된 향상된 SQLite
-   [`EncryptedSession`][agents.extensions.memory.encrypt_session.EncryptedSession] - 모든 세션을 위한 암호화 래퍼

================
File: docs/ko/sessions/sqlalchemy_session.md
================
---
search:
  exclude: true
---
# SQLAlchemy 세션

`SQLAlchemySession`은 SQLAlchemy를 사용하여 프로덕션 준비가 된 세션 구현을 제공하며, 세션 저장소에 SQLAlchemy가 지원하는 모든 데이터베이스(PostgreSQL, MySQL, SQLite 등)를 사용할 수 있게 해줍니다

## 설치

SQLAlchemy 세션에는 `sqlalchemy` extra가 필요합니다:

```bash
pip install openai-agents[sqlalchemy]
```

## 빠른 시작

### 데이터베이스 URL 사용

시작하는 가장 간단한 방법입니다:

```python
import asyncio
from agents import Agent, Runner
from agents.extensions.memory import SQLAlchemySession

async def main():
    agent = Agent("Assistant")
    
    # Create session using database URL
    session = SQLAlchemySession.from_url(
        "user-123",
        url="sqlite+aiosqlite:///:memory:",
        create_tables=True
    )
    
    result = await Runner.run(agent, "Hello", session=session)
    print(result.final_output)

if __name__ == "__main__":
    asyncio.run(main())
```

### 기존 엔진 사용

기존 SQLAlchemy 엔진이 있는 애플리케이션의 경우:

```python
import asyncio
from agents import Agent, Runner
from agents.extensions.memory import SQLAlchemySession
from sqlalchemy.ext.asyncio import create_async_engine

async def main():
    # Create your database engine
    engine = create_async_engine("postgresql+asyncpg://user:pass@localhost/db")
    
    agent = Agent("Assistant")
    session = SQLAlchemySession(
        "user-456",
        engine=engine,
        create_tables=True
    )
    
    result = await Runner.run(agent, "Hello", session=session)
    print(result.final_output)
    
    # Clean up
    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(main())
```


## API 참조

- [`SQLAlchemySession`][agents.extensions.memory.sqlalchemy_session.SQLAlchemySession] - 메인 클래스
- [`Session`][agents.memory.session.Session] - 기본 세션 프로토콜

================
File: docs/ko/voice/pipeline.md
================
---
search:
  exclude: true
---
# 파이프라인과 워크플로

[`VoicePipeline`][agents.voice.pipeline.VoicePipeline]은 에이전트 워크플로를 음성 앱으로 쉽게 전환할 수 있게 해주는 클래스입니다. 실행할 워크플로를 전달하면, 파이프라인이 입력 오디오 전사, 오디오 종료 시점 감지, 적절한 타이밍에 워크플로 호출, 그리고 워크플로 출력의 오디오 변환까지 처리합니다.

```mermaid
graph LR
    %% Input
    A["🎤 Audio Input"]

    %% Voice Pipeline
    subgraph Voice_Pipeline [Voice Pipeline]
        direction TB
        B["Transcribe (speech-to-text)"]
        C["Your Code"]:::highlight
        D["Text-to-speech"]
        B --> C --> D
    end

    %% Output
    E["🎧 Audio Output"]

    %% Flow
    A --> Voice_Pipeline
    Voice_Pipeline --> E

    %% Custom styling
    classDef highlight fill:#ffcc66,stroke:#333,stroke-width:1px,font-weight:700;

```

## 파이프라인 구성

파이프라인을 생성할 때 몇 가지를 설정할 수 있습니다:

1. [`workflow`][agents.voice.workflow.VoiceWorkflowBase]: 새 오디오가 전사될 때마다 실행되는 코드입니다
2. 사용되는 [`speech-to-text`][agents.voice.model.STTModel] 및 [`text-to-speech`][agents.voice.model.TTSModel] 모델
3. [`config`][agents.voice.pipeline_config.VoicePipelineConfig]: 다음과 같은 항목을 구성할 수 있습니다
    - 모델 제공자: 모델 이름을 모델에 매핑할 수 있습니다
    - 트레이싱: 트레이싱 비활성화 여부, 오디오 파일 업로드 여부, 워크플로 이름, trace ID 등
    - TTS 및 STT 모델 설정: 프롬프트, 언어, 사용되는 데이터 타입 등

## 파이프라인 실행

[`run()`][agents.voice.pipeline.VoicePipeline.run] 메서드로 파이프라인을 실행할 수 있으며, 오디오 입력을 두 가지 형태로 전달할 수 있습니다:

1. [`AudioInput`][agents.voice.input.AudioInput]: 전체 오디오 전사본이 있고, 이에 대한 결과만 생성하고 싶을 때 사용합니다. 화자가 말하기를 끝냈는지 감지할 필요가 없는 경우에 유용합니다. 예를 들어, 사전 녹음된 오디오가 있거나 사용자가 말하기를 끝낸 시점이 명확한 푸시-투-토크 앱에서 사용할 수 있습니다
2. [`StreamedAudioInput`][agents.voice.input.StreamedAudioInput]: 사용자가 말하기를 끝냈는지 감지해야 할 수 있을 때 사용합니다. 감지되는 대로 오디오 청크를 푸시할 수 있으며, 음성 파이프라인은 "activity detection"이라는 프로세스를 통해 적절한 시점에 에이전트 워크플로를 자동으로 실행합니다

## 결과

음성 파이프라인 실행 결과는 [`StreamedAudioResult`][agents.voice.result.StreamedAudioResult]입니다. 이는 이벤트가 발생하는 대로 스트리밍할 수 있게 해주는 객체입니다. 몇 가지 유형의 [`VoiceStreamEvent`][agents.voice.events.VoiceStreamEvent]가 있으며, 예시는 다음과 같습니다:

1. [`VoiceStreamEventAudio`][agents.voice.events.VoiceStreamEventAudio]: 오디오 청크를 포함합니다
2. [`VoiceStreamEventLifecycle`][agents.voice.events.VoiceStreamEventLifecycle]: 턴 시작/종료 같은 라이프사이클 이벤트를 알려줍니다
3. [`VoiceStreamEventError`][agents.voice.events.VoiceStreamEventError]: 오류 이벤트입니다

```python

result = await pipeline.run(input)

async for event in result.stream():
    if event.type == "voice_stream_event_audio":
        # play audio
    elif event.type == "voice_stream_event_lifecycle":
        # lifecycle
    elif event.type == "voice_stream_event_error":
        # error
    ...
```

## 모범 사례

### 인터럽션(중단 처리)

Agents SDK는 현재 [`StreamedAudioInput`][agents.voice.input.StreamedAudioInput]에 대해 기본 제공 인터럽션(중단 처리) 지원을 제공하지 않습니다. 대신 감지된 각 턴마다 워크플로가 별도로 실행되도록 트리거합니다. 애플리케이션 내부에서 인터럽션(중단 처리)을 처리하려면 [`VoiceStreamEventLifecycle`][agents.voice.events.VoiceStreamEventLifecycle] 이벤트를 수신하면 됩니다. `turn_started`는 새 턴이 전사되었고 처리가 시작됨을 나타냅니다. `turn_ended`는 해당 턴에 대해 모든 오디오가 디스패치된 후 트리거됩니다. 이 이벤트를 사용해 모델이 턴을 시작할 때 화자의 마이크를 음소거하고, 해당 턴과 관련된 모든 오디오를 플러시한 뒤 음소거를 해제할 수 있습니다

================
File: docs/ko/voice/quickstart.md
================
---
search:
  exclude: true
---
# 빠른 시작

## 사전 준비

Agents SDK의 기본 [빠른 시작 안내](../quickstart.md)를 따라 가상 환경을 설정했는지 확인하세요. 그런 다음, SDK에서 제공하는 선택적 음성 관련 종속성을 설치하세요:

```bash
pip install 'openai-agents[voice]'
```

## 개념

핵심 개념은 [`VoicePipeline`][agents.voice.pipeline.VoicePipeline]이며, 3단계 프로세스입니다:

1. 음성을 텍스트로 변환하기 위해 음성-텍스트 모델을 실행합니다.
2. 보통 에이전트형 워크플로인 여러분의 코드를 실행해 결과를 생성합니다.
3. 결과 텍스트를 다시 음성으로 변환하기 위해 텍스트-음성 모델을 실행합니다.

```mermaid
graph LR
    %% Input
    A["🎤 Audio Input"]

    %% Voice Pipeline
    subgraph Voice_Pipeline [Voice Pipeline]
        direction TB
        B["Transcribe (speech-to-text)"]
        C["Your Code"]:::highlight
        D["Text-to-speech"]
        B --> C --> D
    end

    %% Output
    E["🎧 Audio Output"]

    %% Flow
    A --> Voice_Pipeline
    Voice_Pipeline --> E

    %% Custom styling
    classDef highlight fill:#ffcc66,stroke:#333,stroke-width:1px,font-weight:700;

```

## 에이전트

먼저 에이전트를 설정해 봅시다. 이 SDK로 에이전트를 만들어 본 적 있다면 익숙할 것입니다. 에이전트 몇 개와 핸드오프, 그리고 도구를 사용합니다.

```python
import asyncio
import random

from agents import (
    Agent,
    function_tool,
)
from agents.extensions.handoff_prompt import prompt_with_handoff_instructions



@function_tool
def get_weather(city: str) -> str:
    """Get the weather for a given city."""
    print(f"[debug] get_weather called with city: {city}")
    choices = ["sunny", "cloudy", "rainy", "snowy"]
    return f"The weather in {city} is {random.choice(choices)}."


spanish_agent = Agent(
    name="Spanish",
    handoff_description="A spanish speaking agent.",
    instructions=prompt_with_handoff_instructions(
        "You're speaking to a human, so be polite and concise. Speak in Spanish.",
    ),
    model="gpt-5.2",
)

agent = Agent(
    name="Assistant",
    instructions=prompt_with_handoff_instructions(
        "You're speaking to a human, so be polite and concise. If the user speaks in Spanish, handoff to the spanish agent.",
    ),
    model="gpt-5.2",
    handoffs=[spanish_agent],
    tools=[get_weather],
)
```

## 음성 파이프라인

워크플로로 [`SingleAgentVoiceWorkflow`][agents.voice.workflow.SingleAgentVoiceWorkflow]를 사용해 간단한 음성 파이프라인을 설정합니다.

```python
from agents.voice import SingleAgentVoiceWorkflow, VoicePipeline
pipeline = VoicePipeline(workflow=SingleAgentVoiceWorkflow(agent))
```

## 파이프라인 실행

```python
import numpy as np
import sounddevice as sd
from agents.voice import AudioInput

# For simplicity, we'll just create 3 seconds of silence
# In reality, you'd get microphone data
buffer = np.zeros(24000 * 3, dtype=np.int16)
audio_input = AudioInput(buffer=buffer)

result = await pipeline.run(audio_input)

# Create an audio player using `sounddevice`
player = sd.OutputStream(samplerate=24000, channels=1, dtype=np.int16)
player.start()

# Play the audio stream as it comes in
async for event in result.stream():
    if event.type == "voice_stream_event_audio":
        player.write(event.data)

```

## 모두 합치기

```python
import asyncio
import random

import numpy as np
import sounddevice as sd

from agents import (
    Agent,
    function_tool,
    set_tracing_disabled,
)
from agents.voice import (
    AudioInput,
    SingleAgentVoiceWorkflow,
    VoicePipeline,
)
from agents.extensions.handoff_prompt import prompt_with_handoff_instructions


@function_tool
def get_weather(city: str) -> str:
    """Get the weather for a given city."""
    print(f"[debug] get_weather called with city: {city}")
    choices = ["sunny", "cloudy", "rainy", "snowy"]
    return f"The weather in {city} is {random.choice(choices)}."


spanish_agent = Agent(
    name="Spanish",
    handoff_description="A spanish speaking agent.",
    instructions=prompt_with_handoff_instructions(
        "You're speaking to a human, so be polite and concise. Speak in Spanish.",
    ),
    model="gpt-5.2",
)

agent = Agent(
    name="Assistant",
    instructions=prompt_with_handoff_instructions(
        "You're speaking to a human, so be polite and concise. If the user speaks in Spanish, handoff to the spanish agent.",
    ),
    model="gpt-5.2",
    handoffs=[spanish_agent],
    tools=[get_weather],
)


async def main():
    pipeline = VoicePipeline(workflow=SingleAgentVoiceWorkflow(agent))
    buffer = np.zeros(24000 * 3, dtype=np.int16)
    audio_input = AudioInput(buffer=buffer)

    result = await pipeline.run(audio_input)

    # Create an audio player using `sounddevice`
    player = sd.OutputStream(samplerate=24000, channels=1, dtype=np.int16)
    player.start()

    # Play the audio stream as it comes in
    async for event in result.stream():
        if event.type == "voice_stream_event_audio":
            player.write(event.data)


if __name__ == "__main__":
    asyncio.run(main())
```

이 예제를 실행하면 에이전트가 여러분에게 말합니다! 직접 에이전트와 대화할 수 있는 데모는 [examples/voice/static](https://github.com/openai/openai-agents-python/tree/main/examples/voice/static)에서 확인하세요.

================
File: docs/ko/voice/tracing.md
================
---
search:
  exclude: true
---
# 트레이싱

[에이전트가 트레이싱되는](../tracing.md) 방식과 마찬가지로, 음성 파이프라인도 자동으로 트레이싱됩니다.

기본적인 트레이싱 정보는 위의 트레이싱 문서를 참고하시면 되며, 추가로 [`VoicePipelineConfig`][agents.voice.pipeline_config.VoicePipelineConfig]를 통해 파이프라인의 트레이싱을 구성할 수 있습니다.

트레이싱 관련 핵심 필드는 다음과 같습니다:

-   [`tracing_disabled`][agents.voice.pipeline_config.VoicePipelineConfig.tracing_disabled]: 트레이싱을 비활성화할지 여부를 제어합니다. 기본값은 트레이싱 활성화입니다.
-   [`trace_include_sensitive_data`][agents.voice.pipeline_config.VoicePipelineConfig.trace_include_sensitive_data]: 오디오 전사본과 같은 잠재적으로 민감한 데이터를 트레이스에 포함할지 여부를 제어합니다. 이는 음성 파이프라인에만 해당하며, Workflow 내부에서 발생하는 모든 것에는 적용되지 않습니다.
-   [`trace_include_sensitive_audio_data`][agents.voice.pipeline_config.VoicePipelineConfig.trace_include_sensitive_audio_data]: 트레이스에 오디오 데이터를 포함할지 여부를 제어합니다.
-   [`workflow_name`][agents.voice.pipeline_config.VoicePipelineConfig.workflow_name]: 트레이스 워크플로의 이름입니다.
-   [`group_id`][agents.voice.pipeline_config.VoicePipelineConfig.group_id]: 트레이스의 `group_id`로, 여러 트레이스를 연결할 수 있습니다.
-   [`trace_metadata`][agents.voice.pipeline_config.VoicePipelineConfig.trace_metadata]: 트레이스에 포함할 추가 메타데이터입니다.

================
File: docs/ko/agents.md
================
---
search:
  exclude: true
---
# 에이전트

에이전트는 앱의 핵심 구성 요소입니다. 에이전트는 instructions, tools, 그리고 핸드오프, 가드레일, structured outputs 같은 선택적 런타임 동작으로 구성된 대규모 언어 모델 (LLM) 입니다.

이 페이지는 단일 에이전트를 정의하거나 사용자 지정하려는 경우에 사용합니다. 여러 에이전트가 어떻게 협업해야 하는지 결정하는 중이라면 [에이전트 오케스트레이션](multi_agent.md)을 읽어보세요.

## 다음 가이드 선택

이 페이지를 에이전트 정의의 허브로 사용하세요. 다음으로 내려야 할 결정에 맞는 인접 가이드로 이동하세요.

| 다음을 원한다면... | 다음으로 읽기 |
| --- | --- |
| 모델 또는 provider 설정 선택 | [모델](models/index.md) |
| 에이전트에 기능 추가 | [도구](tools.md) |
| manager 스타일 오케스트레이션과 핸드오프 중 선택 | [에이전트 오케스트레이션](multi_agent.md) |
| 핸드오프 동작 구성 | [핸드오프](handoffs.md) |
| 턴 실행, 이벤트 스트리밍, 또는 대화 상태 관리 | [에이전트 실행](running_agents.md) |
| 최종 출력, 실행 항목, 또는 재개 가능한 상태 확인 | [결과](results.md) |
| 로컬 의존성과 런타임 상태 공유 | [컨텍스트 관리](context.md) |

## 기본 구성

에이전트의 가장 일반적인 속성은 다음과 같습니다:

| 속성 | 필수 | 설명 |
| --- | --- | --- |
| `name` | 예 | 사람이 읽을 수 있는 에이전트 이름 |
| `instructions` | 예 | 시스템 프롬프트 또는 동적 instructions 콜백입니다. [동적 instructions](#dynamic-instructions)을 참조하세요 |
| `prompt` | 아니요 | OpenAI Responses API 프롬프트 구성입니다. 정적 프롬프트 객체 또는 함수를 받을 수 있습니다. [프롬프트 템플릿](#prompt-templates)을 참조하세요 |
| `handoff_description` | 아니요 | 이 에이전트가 핸드오프 대상으로 제공될 때 노출되는 짧은 설명 |
| `handoffs` | 아니요 | 대화를 전문 에이전트에게 위임합니다. [핸드오프](handoffs.md)를 참조하세요 |
| `model` | 아니요 | 사용할 LLM입니다. [모델](models/index.md)을 참조하세요 |
| `model_settings` | 아니요 | `temperature`, `top_p`, `tool_choice` 같은 모델 튜닝 매개변수 |
| `tools` | 아니요 | 에이전트가 호출할 수 있는 도구입니다. [도구](tools.md)를 참조하세요 |
| `mcp_servers` | 아니요 | 에이전트를 위한 MCP 기반 도구입니다. [MCP 가이드](mcp.md)를 참조하세요 |
| `input_guardrails` | 아니요 | 이 에이전트 체인의 첫 사용자 입력에서 실행되는 가드레일입니다. [가드레일](guardrails.md)을 참조하세요 |
| `output_guardrails` | 아니요 | 이 에이전트의 최종 출력에서 실행되는 가드레일입니다. [가드레일](guardrails.md)을 참조하세요 |
| `output_type` | 아니요 | 일반 텍스트 대신 구조화된 출력 타입입니다. [출력 타입](#output-types)을 참조하세요 |
| `tool_use_behavior` | 아니요 | 도구 결과를 모델로 다시 순환시킬지 실행을 종료할지 제어합니다. [도구 사용 동작](#tool-use-behavior)을 참조하세요 |
| `reset_tool_choice` | 아니요 | 도구 사용 루프를 방지하기 위해 도구 호출 후 `tool_choice`를 재설정합니다 (기본값: `True`). [도구 사용 강제](#forcing-tool-use)를 참조하세요 |

```python
from agents import Agent, ModelSettings, function_tool

@function_tool
def get_weather(city: str) -> str:
    """returns weather info for the specified city."""
    return f"The weather in {city} is sunny"

agent = Agent(
    name="Haiku agent",
    instructions="Always respond in haiku form",
    model="gpt-5-nano",
    tools=[get_weather],
)
```

## 프롬프트 템플릿

`prompt`를 설정하면 OpenAI 플랫폼에서 만든 프롬프트 템플릿을 참조할 수 있습니다. 이는 Responses API를 사용하는 OpenAI 모델에서 동작합니다.

사용 방법은 다음과 같습니다:

1. https://platform.openai.com/playground/prompts 로 이동합니다
2. 새 프롬프트 변수 `poem_style`를 만듭니다
3. 다음 내용을 가진 시스템 프롬프트를 만듭니다:

    ```
    Write a poem in {{poem_style}}
    ```

4. `--prompt-id` 플래그로 예제를 실행합니다

```python
from agents import Agent

agent = Agent(
    name="Prompted assistant",
    prompt={
        "id": "pmpt_123",
        "version": "1",
        "variables": {"poem_style": "haiku"},
    },
)
```

런타임에 프롬프트를 동적으로 생성할 수도 있습니다:

```python
from dataclasses import dataclass

from agents import Agent, GenerateDynamicPromptData, Runner

@dataclass
class PromptContext:
    prompt_id: str
    poem_style: str


async def build_prompt(data: GenerateDynamicPromptData):
    ctx: PromptContext = data.context.context
    return {
        "id": ctx.prompt_id,
        "version": "1",
        "variables": {"poem_style": ctx.poem_style},
    }


agent = Agent(name="Prompted assistant", prompt=build_prompt)
result = await Runner.run(
    agent,
    "Say hello",
    context=PromptContext(prompt_id="pmpt_123", poem_style="limerick"),
)
```

## 컨텍스트

에이전트는 `context` 타입에 대해 제네릭입니다. 컨텍스트는 의존성 주입 도구입니다: 사용자가 생성해 `Runner.run()`에 전달하는 객체로, 모든 에이전트, 도구, 핸드오프 등에 전달되며 에이전트 실행을 위한 의존성과 상태를 담는 컨테이너 역할을 합니다. 컨텍스트로는 어떤 Python 객체든 제공할 수 있습니다.

전체 `RunContextWrapper` 표면, 공유 사용량 추적, 중첩 `tool_input`, 직렬화 관련 주의사항은 [컨텍스트 가이드](context.md)를 읽어보세요.

```python
@dataclass
class UserContext:
    name: str
    uid: str
    is_pro_user: bool

    async def fetch_purchases() -> list[Purchase]:
        return ...

agent = Agent[UserContext](
    ...,
)
```

## 출력 타입

기본적으로 에이전트는 일반 텍스트 (즉 `str`) 출력을 생성합니다. 에이전트가 특정 타입의 출력을 생성하도록 하려면 `output_type` 매개변수를 사용할 수 있습니다. 일반적으로 [Pydantic](https://docs.pydantic.dev/) 객체를 많이 사용하지만, Pydantic [TypeAdapter](https://docs.pydantic.dev/latest/api/type_adapter/)로 감쌀 수 있는 모든 타입을 지원합니다 - dataclasses, lists, TypedDict 등.

```python
from pydantic import BaseModel
from agents import Agent


class CalendarEvent(BaseModel):
    name: str
    date: str
    participants: list[str]

agent = Agent(
    name="Calendar extractor",
    instructions="Extract calendar events from text",
    output_type=CalendarEvent,
)
```

!!! note

    `output_type`를 전달하면, 모델은 일반 일반 텍스트 응답 대신 [structured outputs](https://platform.openai.com/docs/guides/structured-outputs)을 사용하게 됩니다

## 멀티 에이전트 시스템 설계 패턴

멀티 에이전트 시스템을 설계하는 방법은 다양하지만, 일반적으로 폭넓게 적용 가능한 두 가지 패턴이 자주 사용됩니다:

1. Manager (Agents as tools): 중앙 manager/orchestrator가 전문 하위 에이전트를 도구로 호출하고 대화 제어를 유지합니다
2. 핸드오프: 동등한 에이전트가 제어권을 전문 에이전트로 넘기고, 해당 에이전트가 대화를 이어받습니다. 이는 분산형 방식입니다

자세한 내용은 [에이전트 구축 실전 가이드](https://cdn.openai.com/business-guides-and-resources/a-practical-guide-to-building-agents.pdf)를 참고하세요.

### Manager (Agents as tools)

`customer_facing_agent`는 모든 사용자 상호작용을 처리하고, 도구로 노출된 전문 하위 에이전트를 호출합니다. 자세한 내용은 [도구](tools.md#agents-as-tools) 문서를 참고하세요.

```python
from agents import Agent

booking_agent = Agent(...)
refund_agent = Agent(...)

customer_facing_agent = Agent(
    name="Customer-facing agent",
    instructions=(
        "Handle all direct user communication. "
        "Call the relevant tools when specialized expertise is needed."
    ),
    tools=[
        booking_agent.as_tool(
            tool_name="booking_expert",
            tool_description="Handles booking questions and requests.",
        ),
        refund_agent.as_tool(
            tool_name="refund_expert",
            tool_description="Handles refund questions and requests.",
        )
    ],
)
```

### 핸드오프

핸드오프는 에이전트가 위임할 수 있는 하위 에이전트입니다. 핸드오프가 발생하면 위임된 에이전트가 대화 기록을 전달받아 대화를 이어받습니다. 이 패턴은 단일 작업에 특화된 모듈형 에이전트를 가능하게 합니다. 자세한 내용은 [핸드오프](handoffs.md) 문서를 참고하세요.

```python
from agents import Agent

booking_agent = Agent(...)
refund_agent = Agent(...)

triage_agent = Agent(
    name="Triage agent",
    instructions=(
        "Help the user with their questions. "
        "If they ask about booking, hand off to the booking agent. "
        "If they ask about refunds, hand off to the refund agent."
    ),
    handoffs=[booking_agent, refund_agent],
)
```

## 동적 instructions

대부분의 경우 에이전트 생성 시 instructions를 제공할 수 있습니다. 하지만 함수를 통해 동적 instructions를 제공할 수도 있습니다. 이 함수는 에이전트와 컨텍스트를 받아 프롬프트를 반환해야 합니다. 일반 함수와 `async` 함수 모두 지원됩니다.

```python
def dynamic_instructions(
    context: RunContextWrapper[UserContext], agent: Agent[UserContext]
) -> str:
    return f"The user's name is {context.context.name}. Help them with their questions."


agent = Agent[UserContext](
    name="Triage agent",
    instructions=dynamic_instructions,
)
```

## 라이프사이클 이벤트 (hooks)

경우에 따라 에이전트의 라이프사이클을 관찰하고 싶을 수 있습니다. 예를 들어, 특정 이벤트 발생 시 이벤트 로깅, 데이터 사전 조회, 사용량 기록 등을 수행할 수 있습니다.

hook 범위는 두 가지입니다:

-   [`RunHooks`][agents.lifecycle.RunHooks]는 다른 에이전트로의 핸드오프를 포함해 전체 `Runner.run(...)` 호출을 관찰합니다
-   [`AgentHooks`][agents.lifecycle.AgentHooks]는 `agent.hooks`를 통해 특정 에이전트 인스턴스에 연결됩니다

콜백 컨텍스트도 이벤트에 따라 달라집니다:

-   에이전트 시작/종료 hooks는 [`AgentHookContext`][agents.run_context.AgentHookContext]를 받으며, 이는 원래 컨텍스트를 래핑하고 공유 실행 사용량 상태를 포함합니다
-   LLM, 도구, 핸드오프 hooks는 [`RunContextWrapper`][agents.run_context.RunContextWrapper]를 받습니다

일반적인 hook 실행 시점:

-   `on_agent_start` / `on_agent_end`: 특정 에이전트가 최종 출력을 생성하기 시작하거나 마칠 때
-   `on_llm_start` / `on_llm_end`: 각 모델 호출 직전/직후
-   `on_tool_start` / `on_tool_end`: 각 로컬 도구 호출 전후
-   `on_handoff`: 제어가 한 에이전트에서 다른 에이전트로 이동할 때

전체 워크플로우에 단일 관찰자가 필요하면 `RunHooks`를, 특정 에이전트에 맞춤형 부수 효과가 필요하면 `AgentHooks`를 사용하세요.

```python
from agents import Agent, RunHooks, Runner


class LoggingHooks(RunHooks):
    async def on_agent_start(self, context, agent):
        print(f"Starting {agent.name}")

    async def on_llm_end(self, context, agent, response):
        print(f"{agent.name} produced {len(response.output)} output items")

    async def on_agent_end(self, context, agent, output):
        print(f"{agent.name} finished with usage: {context.usage}")


agent = Agent(name="Assistant", instructions="Be concise.")
result = await Runner.run(agent, "Explain quines", hooks=LoggingHooks())
print(result.final_output)
```

전체 콜백 표면은 [라이프사이클 API 레퍼런스](ref/lifecycle.md)를 참고하세요.

## 가드레일

가드레일을 사용하면 에이전트 실행과 병렬로 사용자 입력에 대한 점검/검증을 수행하고, 에이전트 출력이 생성된 뒤에도 검사를 수행할 수 있습니다. 예를 들어 사용자 입력과 에이전트 출력의 관련성을 검사할 수 있습니다. 자세한 내용은 [가드레일](guardrails.md) 문서를 참고하세요.

## 에이전트 복제/복사

에이전트에서 `clone()` 메서드를 사용하면 Agent를 복제하고, 원하는 속성을 선택적으로 변경할 수 있습니다.

```python
pirate_agent = Agent(
    name="Pirate",
    instructions="Write like a pirate",
    model="gpt-5.2",
)

robot_agent = pirate_agent.clone(
    name="Robot",
    instructions="Write like a robot",
)
```

## 도구 사용 강제

도구 목록을 제공했다고 해서 LLM이 항상 도구를 사용하는 것은 아닙니다. [`ModelSettings.tool_choice`][agents.model_settings.ModelSettings.tool_choice]를 설정해 도구 사용을 강제할 수 있습니다. 유효한 값은 다음과 같습니다:

1. `auto`: LLM이 도구 사용 여부를 결정하도록 허용합니다
2. `required`: LLM이 도구를 사용해야 합니다 (단, 어떤 도구를 사용할지는 지능적으로 결정할 수 있습니다)
3. `none`: LLM이 도구를 사용하지 않도록 강제합니다
4. 예: `my_tool` 같은 특정 문자열 설정: LLM이 해당 특정 도구를 사용하도록 강제합니다

```python
from agents import Agent, Runner, function_tool, ModelSettings

@function_tool
def get_weather(city: str) -> str:
    """Returns weather info for the specified city."""
    return f"The weather in {city} is sunny"

agent = Agent(
    name="Weather Agent",
    instructions="Retrieve weather details.",
    tools=[get_weather],
    model_settings=ModelSettings(tool_choice="get_weather")
)
```

## 도구 사용 동작

`Agent` 구성의 `tool_use_behavior` 매개변수는 도구 출력 처리 방식을 제어합니다:

- `"run_llm_again"`: 기본값입니다. 도구를 실행한 뒤 LLM이 결과를 처리해 최종 응답을 생성합니다
- `"stop_on_first_tool"`: 첫 번째 도구 호출의 출력을 추가 LLM 처리 없이 최종 응답으로 사용합니다

```python
from agents import Agent, Runner, function_tool, ModelSettings

@function_tool
def get_weather(city: str) -> str:
    """Returns weather info for the specified city."""
    return f"The weather in {city} is sunny"

agent = Agent(
    name="Weather Agent",
    instructions="Retrieve weather details.",
    tools=[get_weather],
    tool_use_behavior="stop_on_first_tool"
)
```

- `StopAtTools(stop_at_tool_names=[...])`: 지정한 도구 중 하나라도 호출되면 중지하고, 해당 출력을 최종 응답으로 사용합니다

```python
from agents import Agent, Runner, function_tool
from agents.agent import StopAtTools

@function_tool
def get_weather(city: str) -> str:
    """Returns weather info for the specified city."""
    return f"The weather in {city} is sunny"

@function_tool
def sum_numbers(a: int, b: int) -> int:
    """Adds two numbers."""
    return a + b

agent = Agent(
    name="Stop At Stock Agent",
    instructions="Get weather or sum numbers.",
    tools=[get_weather, sum_numbers],
    tool_use_behavior=StopAtTools(stop_at_tool_names=["get_weather"])
)
```

- `ToolsToFinalOutputFunction`: 도구 결과를 처리하고 LLM으로 계속 진행할지 중지할지 결정하는 사용자 지정 함수입니다

```python
from agents import Agent, Runner, function_tool, FunctionToolResult, RunContextWrapper
from agents.agent import ToolsToFinalOutputResult
from typing import List, Any

@function_tool
def get_weather(city: str) -> str:
    """Returns weather info for the specified city."""
    return f"The weather in {city} is sunny"

def custom_tool_handler(
    context: RunContextWrapper[Any],
    tool_results: List[FunctionToolResult]
) -> ToolsToFinalOutputResult:
    """Processes tool results to decide final output."""
    for result in tool_results:
        if result.output and "sunny" in result.output:
            return ToolsToFinalOutputResult(
                is_final_output=True,
                final_output=f"Final weather: {result.output}"
            )
    return ToolsToFinalOutputResult(
        is_final_output=False,
        final_output=None
    )

agent = Agent(
    name="Weather Agent",
    instructions="Retrieve weather details.",
    tools=[get_weather],
    tool_use_behavior=custom_tool_handler
)
```

!!! note

    무한 루프를 방지하기 위해 프레임워크는 도구 호출 후 `tool_choice`를 자동으로 "auto"로 재설정합니다. 이 동작은 [`agent.reset_tool_choice`][agents.agent.Agent.reset_tool_choice]로 구성할 수 있습니다. 도구 결과가 LLM으로 전송되고, `tool_choice` 때문에 LLM이 다시 도구 호출을 생성하는 과정이 무한히 반복되어 무한 루프가 발생합니다

================
File: docs/ko/config.md
================
---
search:
  exclude: true
---
# 구성

이 페이지에서는 기본 OpenAI 키 또는 client, 기본 OpenAI API 형태, 트레이싱 내보내기 기본값, 로깅 동작 등 애플리케이션 시작 시 보통 한 번 설정하는 SDK 전역 기본값을 다룹니다

대신 특정 에이전트나 run을 구성해야 한다면 다음부터 시작하세요:

- [Running agents](running_agents.md): `RunConfig`, 세션, 대화 상태 옵션
- [Models](models/index.md): 모델 선택 및 provider 구성
- [Tracing](tracing.md): run별 트레이싱 메타데이터 및 사용자 지정 트레이스 프로세서

## API 키 및 클라이언트

기본적으로 SDK는 LLM 요청과 트레이싱에 `OPENAI_API_KEY` 환경 변수를 사용합니다. 키는 SDK가 처음 OpenAI 클라이언트를 생성할 때(지연 초기화) 확인되므로, 첫 모델 호출 전에 환경 변수를 설정하세요. 앱 시작 전에 해당 환경 변수를 설정할 수 없다면 [set_default_openai_key()][agents.set_default_openai_key] 함수를 사용해 키를 설정할 수 있습니다.

```python
from agents import set_default_openai_key

set_default_openai_key("sk-...")
```

또는 사용할 OpenAI client를 구성할 수도 있습니다. 기본적으로 SDK는 환경 변수의 API 키 또는 위에서 설정한 기본 키를 사용해 `AsyncOpenAI` 인스턴스를 생성합니다. [set_default_openai_client()][agents.set_default_openai_client] 함수를 사용해 이를 변경할 수 있습니다.

```python
from openai import AsyncOpenAI
from agents import set_default_openai_client

custom_client = AsyncOpenAI(base_url="...", api_key="...")
set_default_openai_client(custom_client)
```

마지막으로, 사용되는 OpenAI API를 사용자 지정할 수도 있습니다. 기본적으로 OpenAI Responses API를 사용합니다. [set_default_openai_api()][agents.set_default_openai_api] 함수를 사용하면 이를 Chat Completions API로 재정의할 수 있습니다.

```python
from agents import set_default_openai_api

set_default_openai_api("chat_completions")
```

## 트레이싱

트레이싱은 기본적으로 활성화되어 있습니다. 기본적으로 위 섹션의 모델 요청과 동일한 OpenAI API 키(즉, 환경 변수 또는 설정한 기본 키)를 사용합니다. 트레이싱에 사용할 API 키를 별도로 지정하려면 [`set_tracing_export_api_key`][agents.set_tracing_export_api_key] 함수를 사용하세요.

```python
from agents import set_tracing_export_api_key

set_tracing_export_api_key("sk-...")
```

기본 exporter 사용 시 트레이스를 특정 organization 또는 project에 귀속해야 한다면, 앱 시작 전에 다음 환경 변수를 설정하세요:

```bash
export OPENAI_ORG_ID="org_..."
export OPENAI_PROJECT_ID="proj_..."
```

전역 exporter를 변경하지 않고 run별로 트레이싱 API 키를 설정할 수도 있습니다.

```python
from agents import Runner, RunConfig

await Runner.run(
    agent,
    input="Hello",
    run_config=RunConfig(tracing={"api_key": "sk-tracing-123"}),
)
```

[`set_tracing_disabled()`][agents.set_tracing_disabled] 함수를 사용해 트레이싱을 완전히 비활성화할 수도 있습니다.

```python
from agents import set_tracing_disabled

set_tracing_disabled(True)
```

트레이싱은 활성화한 채로 트레이스 페이로드에서 잠재적으로 민감한 입력/출력을 제외하려면 [`RunConfig.trace_include_sensitive_data`][agents.run.RunConfig.trace_include_sensitive_data]를 `False`로 설정하세요:

```python
from agents import Runner, RunConfig

await Runner.run(
    agent,
    input="Hello",
    run_config=RunConfig(trace_include_sensitive_data=False),
)
```

앱 시작 전에 다음 환경 변수를 설정하면 코드 없이 기본값을 변경할 수도 있습니다:

```bash
export OPENAI_AGENTS_TRACE_INCLUDE_SENSITIVE_DATA=0
```

전체 트레이싱 제어는 [tracing guide](tracing.md)를 참고하세요.

## 디버그 로깅

SDK는 두 개의 Python 로거(`openai.agents`, `openai.agents.tracing`)를 정의하며 기본적으로 핸들러를 연결하지 않습니다. 로그는 애플리케이션의 Python 로깅 구성을 따릅니다.

상세 로깅을 활성화하려면 [`enable_verbose_stdout_logging()`][agents.enable_verbose_stdout_logging] 함수를 사용하세요.

```python
from agents import enable_verbose_stdout_logging

enable_verbose_stdout_logging()
```

또는 핸들러, 필터, 포매터 등을 추가해 로그를 사용자 지정할 수 있습니다. 자세한 내용은 [Python logging guide](https://docs.python.org/3/howto/logging.html)를 참고하세요.

```python
import logging

logger = logging.getLogger("openai.agents") # or openai.agents.tracing for the Tracing logger

# To make all logs show up
logger.setLevel(logging.DEBUG)
# To make info and above show up
logger.setLevel(logging.INFO)
# To make warning and above show up
logger.setLevel(logging.WARNING)
# etc

# You can customize this as needed, but this will output to `stderr` by default
logger.addHandler(logging.StreamHandler())
```

### 로그 내 민감한 데이터

일부 로그에는 민감한 데이터(예: 사용자 데이터)가 포함될 수 있습니다.

기본적으로 SDK는 LLM 입력/출력 또는 도구 입력/출력을 기록하지 **않습니다**. 이러한 보호는 다음으로 제어됩니다:

```bash
OPENAI_AGENTS_DONT_LOG_MODEL_DATA=1
OPENAI_AGENTS_DONT_LOG_TOOL_DATA=1
```

디버깅을 위해 이 데이터를 일시적으로 포함해야 한다면, 앱 시작 전에 변수 중 하나를 `0`(또는 `false`)으로 설정하세요:

```bash
export OPENAI_AGENTS_DONT_LOG_MODEL_DATA=0
export OPENAI_AGENTS_DONT_LOG_TOOL_DATA=0
```

================
File: docs/ko/context.md
================
---
search:
  exclude: true
---
# 컨텍스트 관리

컨텍스트는 여러 의미로 사용되는 용어입니다. 주로 신경 써야 할 컨텍스트는 두 가지 범주가 있습니다

1. 코드에서 로컬로 사용할 수 있는 컨텍스트: 도구 함수 실행 시, `on_handoff` 같은 콜백 중, 라이프사이클 훅 등에서 필요할 수 있는 데이터와 의존성
2. LLM에서 사용할 수 있는 컨텍스트: LLM이 응답을 생성할 때 보는 데이터

## 로컬 컨텍스트

이는 [`RunContextWrapper`][agents.run_context.RunContextWrapper] 클래스와 그 안의 [`context`][agents.run_context.RunContextWrapper.context] 속성으로 표현됩니다. 동작 방식은 다음과 같습니다

1. 원하는 Python 객체를 만듭니다. 일반적인 패턴은 dataclass나 Pydantic 객체를 사용하는 것입니다
2. 해당 객체를 다양한 run 메서드에 전달합니다(예: `Runner.run(..., context=whatever)`)
3. 모든 도구 호출, 라이프사이클 훅 등은 `RunContextWrapper[T]` 래퍼 객체를 전달받으며, 여기서 `T`는 `wrapper.context`를 통해 접근할 수 있는 컨텍스트 객체 타입을 나타냅니다

**가장 중요**하게 알아둘 점: 특정 에이전트 실행에 대해, 모든 에이전트, 도구 함수, 라이프사이클 등은 동일한 _타입_ 의 컨텍스트를 사용해야 합니다

컨텍스트는 다음과 같은 용도로 사용할 수 있습니다

-   실행에 대한 문맥 데이터(예: 사용자 이름/uid 또는 사용자에 관한 기타 정보)
-   의존성(예: logger 객체, 데이터 가져오기 객체 등)
-   헬퍼 함수

!!! danger "참고"

    컨텍스트 객체는 LLM으로 **전송되지 않습니다**. 이는 순수하게 로컬 객체이며, 여기서 값을 읽고, 쓰고, 메서드를 호출할 수 있습니다

단일 실행 내에서 파생된 래퍼들은 동일한 기본 앱 컨텍스트, 승인 상태, 사용량 추적을 공유합니다. 중첩된 [`Agent.as_tool()`][agents.agent.Agent.as_tool] 실행은 다른 `tool_input`을 연결할 수 있지만, 기본적으로 앱 상태의 분리된 복사본을 받지는 않습니다.

### `RunContextWrapper` 노출 항목

[`RunContextWrapper`][agents.run_context.RunContextWrapper]는 앱에서 정의한 컨텍스트 객체를 감싸는 래퍼입니다. 실제로는 보통 다음을 가장 많이 사용합니다

-   앱의 변경 가능한 상태와 의존성을 위한 [`wrapper.context`][agents.run_context.RunContextWrapper.context]
-   현재 실행 전반의 집계된 요청 및 토큰 사용량을 위한 [`wrapper.usage`][agents.run_context.RunContextWrapper.usage]
-   현재 실행이 [`Agent.as_tool()`][agents.agent.Agent.as_tool] 내부에서 수행될 때 구조화된 입력을 위한 [`wrapper.tool_input`][agents.run_context.RunContextWrapper.tool_input]
-   승인 상태를 프로그래밍 방식으로 업데이트해야 할 때 [`wrapper.approve_tool(...)`][agents.run_context.RunContextWrapper.approve_tool] / [`wrapper.reject_tool(...)`][agents.run_context.RunContextWrapper.reject_tool]

`wrapper.context`만이 앱에서 정의한 객체입니다. 나머지 필드는 SDK가 관리하는 런타임 메타데이터입니다.

나중에 휴먼인더루프 (HITL) 또는 내구성 있는 작업 워크플로를 위해 [`RunState`][agents.run_state.RunState]를 직렬화하면, 해당 런타임 메타데이터도 상태와 함께 저장됩니다. 직렬화된 상태를 유지하거나 전송할 계획이라면 [`RunContextWrapper.context`][agents.run_context.RunContextWrapper.context]에 비밀 정보를 넣지 마세요.

대화 상태는 별개의 관심사입니다. 턴을 이어가는 방식에 따라 `result.to_input_list()`, `session`, `conversation_id`, `previous_response_id`를 사용하세요. 이 결정에 대해서는 [results](results.md), [running agents](running_agents.md), [sessions](sessions/index.md)를 참고하세요.

```python
import asyncio
from dataclasses import dataclass

from agents import Agent, RunContextWrapper, Runner, function_tool

@dataclass
class UserInfo:  # (1)!
    name: str
    uid: int

@function_tool
async def fetch_user_age(wrapper: RunContextWrapper[UserInfo]) -> str:  # (2)!
    """Fetch the age of the user. Call this function to get user's age information."""
    return f"The user {wrapper.context.name} is 47 years old"

async def main():
    user_info = UserInfo(name="John", uid=123)

    agent = Agent[UserInfo](  # (3)!
        name="Assistant",
        tools=[fetch_user_age],
    )

    result = await Runner.run(  # (4)!
        starting_agent=agent,
        input="What is the age of the user?",
        context=user_info,
    )

    print(result.final_output)  # (5)!
    # The user John is 47 years old.

if __name__ == "__main__":
    asyncio.run(main())
```

1. 이것이 컨텍스트 객체입니다. 여기서는 dataclass를 사용했지만, 어떤 타입이든 사용할 수 있습니다
2. 이것은 도구입니다. `RunContextWrapper[UserInfo]`를 받는 것을 볼 수 있습니다. 도구 구현은 컨텍스트에서 값을 읽습니다
3. 타입 체커가 오류를 잡을 수 있도록(예: 다른 컨텍스트 타입을 받는 도구를 전달하려는 경우) 에이전트를 제네릭 `UserInfo`로 지정합니다
4. 컨텍스트는 `run` 함수에 전달됩니다
5. 에이전트는 도구를 올바르게 호출하고 나이를 얻습니다

---

### 고급: `ToolContext`

경우에 따라 실행 중인 도구에 대한 추가 메타데이터(예: 이름, 호출 ID, 원문 인자 문자열)에 접근하고 싶을 수 있습니다  
이를 위해 `RunContextWrapper`를 확장한 [`ToolContext`][agents.tool_context.ToolContext] 클래스를 사용할 수 있습니다

```python
from typing import Annotated
from pydantic import BaseModel, Field
from agents import Agent, Runner, function_tool
from agents.tool_context import ToolContext

class WeatherContext(BaseModel):
    user_id: str

class Weather(BaseModel):
    city: str = Field(description="The city name")
    temperature_range: str = Field(description="The temperature range in Celsius")
    conditions: str = Field(description="The weather conditions")

@function_tool
def get_weather(ctx: ToolContext[WeatherContext], city: Annotated[str, "The city to get the weather for"]) -> Weather:
    print(f"[debug] Tool context: (name: {ctx.tool_name}, call_id: {ctx.tool_call_id}, args: {ctx.tool_arguments})")
    return Weather(city=city, temperature_range="14-20C", conditions="Sunny with wind.")

agent = Agent(
    name="Weather Agent",
    instructions="You are a helpful agent that can tell the weather of a given city.",
    tools=[get_weather],
)
```

`ToolContext`는 `RunContextWrapper`와 동일한 `.context` 속성을 제공하며,  
여기에 현재 도구 호출에 특화된 추가 필드가 있습니다

- `tool_name` – 호출되는 도구의 이름  
- `tool_call_id` – 이 도구 호출의 고유 식별자  
- `tool_arguments` – 도구에 전달된 원문 인자 문자열  

실행 중 도구 수준 메타데이터가 필요할 때 `ToolContext`를 사용하세요  
에이전트와 도구 간 일반적인 컨텍스트 공유에는 `RunContextWrapper`만으로도 충분합니다. `ToolContext`는 `RunContextWrapper`를 확장하므로, 중첩된 `Agent.as_tool()` 실행이 구조화된 입력을 제공한 경우 `.tool_input`도 노출할 수 있습니다.

---

## 에이전트/LLM 컨텍스트

LLM이 호출될 때 볼 수 있는 데이터는 대화 기록의 내용이 **전부**입니다. 즉, 어떤 새 데이터를 LLM에서 사용할 수 있게 하려면, 그 데이터가 대화 기록에서 접근 가능하도록 만들어야 합니다. 이를 위한 방법은 몇 가지가 있습니다

1. 에이전트 `instructions`에 추가할 수 있습니다. 이는 "시스템 프롬프트" 또는 "개발자 메시지"라고도 합니다. 시스템 프롬프트는 정적 문자열일 수도 있고, 컨텍스트를 받아 문자열을 출력하는 동적 함수일 수도 있습니다. 이는 항상 유용한 정보(예: 사용자 이름 또는 현재 날짜)에 대한 일반적인 방법입니다
2. `Runner.run` 함수를 호출할 때 `input`에 추가합니다. 이는 `instructions` 방식과 유사하지만, [chain of command](https://cdn.openai.com/spec/model-spec-2024-05-08.html#follow-the-chain-of-command)에서 더 낮은 우선순위의 메시지를 둘 수 있게 해줍니다
3. 함수 도구를 통해 노출합니다. 이는 _온디맨드_ 컨텍스트에 유용합니다. LLM이 데이터가 필요한 시점을 결정하고, 해당 데이터를 가져오기 위해 도구를 호출할 수 있습니다
4. retrieval 또는 웹 검색을 사용합니다. 이들은 파일 또는 데이터베이스(retrieval), 혹은 웹(웹 검색)에서 관련 데이터를 가져올 수 있는 특수 도구입니다. 이는 관련 컨텍스트 데이터에 응답을 "근거화(grounding)"하는 데 유용합니다

================
File: docs/ko/examples.md
================
---
search:
  exclude: true
---
# 코드 예제

[repo](https://github.com/openai/openai-agents-python/tree/main/examples)의 examples 섹션에서 SDK의 다양한 샘플 구현을 확인해 보세요. examples는 여러 카테고리로 구성되어 있으며, 각각 서로 다른 패턴과 기능을 보여줍니다.

## 카테고리

-   **[agent_patterns](https://github.com/openai/openai-agents-python/tree/main/examples/agent_patterns):**
    이 카테고리의 examples는 다음과 같은 일반적인 에이전트 설계 패턴을 설명합니다

    -   결정적 워크플로
    -   Agents as tools
    -   병렬 에이전트 실행
    -   조건부 도구 사용
    -   입출력 가드레일
    -   심판으로서의 LLM
    -   라우팅
    -   스트리밍 가드레일

-   **[basic](https://github.com/openai/openai-agents-python/tree/main/examples/basic):**
    이 examples는 SDK의 기본 기능을 보여줍니다. 예시는 다음과 같습니다

    -   Hello World 예제(Default model, GPT-5, 오픈 웨이트 모델)
    -   에이전트 수명 주기 관리
    -   동적 시스템 프롬프트
    -   스트리밍 출력(텍스트, 항목, 함수 호출 인자)
    -   턴 간 공유 세션 헬퍼를 사용하는 Responses websocket 전송(`examples/basic/stream_ws.py`)
    -   프롬프트 템플릿
    -   파일 처리(로컬 및 원격, 이미지 및 PDF)
    -   사용량 추적
    -   비엄격 출력 타입
    -   이전 응답 ID 사용

-   **[customer_service](https://github.com/openai/openai-agents-python/tree/main/examples/customer_service):**
    항공사를 위한 고객 서비스 시스템 예제입니다

-   **[financial_research_agent](https://github.com/openai/openai-agents-python/tree/main/examples/financial_research_agent):**
    금융 데이터 분석을 위한 에이전트와 도구를 사용한 구조화된 리서치 워크플로를 보여주는 금융 리서치 에이전트입니다

-   **[handoffs](https://github.com/openai/openai-agents-python/tree/main/examples/handoffs):**
    메시지 필터링을 포함한 에이전트 핸드오프의 실용적인 예제를 확인해 보세요

-   **[hosted_mcp](https://github.com/openai/openai-agents-python/tree/main/examples/hosted_mcp):**
    호스티드 MCP(Model Context Protocol) 커넥터와 승인 사용 방법을 보여주는 예제입니다

-   **[mcp](https://github.com/openai/openai-agents-python/tree/main/examples/mcp):**
    다음을 포함해 MCP(Model Context Protocol)로 에이전트를 구축하는 방법을 알아보세요

    -   파일 시스템 예제
    -   Git 예제
    -   MCP 프롬프트 서버 예제
    -   SSE(Server-Sent Events) 예제
    -   스트리밍 가능한 HTTP 예제

-   **[memory](https://github.com/openai/openai-agents-python/tree/main/examples/memory):**
    다음을 포함한 에이전트용 다양한 메모리 구현 예제입니다

    -   SQLite 세션 저장소
    -   고급 SQLite 세션 저장소
    -   Redis 세션 저장소
    -   SQLAlchemy 세션 저장소
    -   Dapr 상태 저장소 세션 저장소
    -   암호화된 세션 저장소
    -   OpenAI Conversations 세션 저장소
    -   Responses 압축 세션 저장소

-   **[model_providers](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers):**
    커스텀 provider 및 LiteLLM 통합을 포함해 SDK에서 OpenAI 이외의 모델을 사용하는 방법을 살펴보세요

-   **[realtime](https://github.com/openai/openai-agents-python/tree/main/examples/realtime):**
    다음을 포함해 SDK를 사용해 실시간 경험을 구축하는 방법을 보여주는 예제입니다

    -   구조화된 텍스트 및 이미지 메시지를 활용한 웹 애플리케이션 패턴
    -   명령줄 오디오 루프 및 재생 처리
    -   WebSocket을 통한 Twilio Media Streams 통합
    -   Realtime Calls API attach 플로우를 사용하는 Twilio SIP 통합

-   **[reasoning_content](https://github.com/openai/openai-agents-python/tree/main/examples/reasoning_content):**
    reasoning content 및 structured outputs를 다루는 방법을 보여주는 예제입니다

-   **[research_bot](https://github.com/openai/openai-agents-python/tree/main/examples/research_bot):**
    복잡한 멀티 에이전트 리서치 워크플로를 보여주는 간단한 딥 리서치 클론입니다

-   **[tools](https://github.com/openai/openai-agents-python/tree/main/examples/tools):**
    다음과 같은 OAI hosted tools 및 실험적 Codex 도구를 구현하는 방법을 알아보세요

    -   웹 검색 및 필터가 있는 웹 검색
    -   파일 검색
    -   코드 인터프리터
    -   인라인 스킬이 있는 호스티드 컨테이너 셸(`examples/tools/container_shell_inline_skill.py`)
    -   스킬 참조가 있는 호스티드 컨테이너 셸(`examples/tools/container_shell_skill_reference.py`)
    -   컴퓨터 사용
    -   이미지 생성
    -   실험적 Codex 도구 워크플로(`examples/tools/codex.py`)
    -   실험적 Codex 동일 스레드 워크플로(`examples/tools/codex_same_thread.py`)

-   **[voice](https://github.com/openai/openai-agents-python/tree/main/examples/voice):**
    스트리밍 음성 예제를 포함해, TTS 및 STT 모델을 사용하는 음성 에이전트 예제를 확인해 보세요

================
File: docs/ko/guardrails.md
================
---
search:
  exclude: true
---
# 가드레일

가드레일을 사용하면 사용자 입력과 에이전트 출력에 대한 검사 및 검증을 수행할 수 있습니다. 예를 들어, 고객 요청을 돕기 위해 매우 똑똑한(따라서 느리고/비싼) 모델을 사용하는 에이전트가 있다고 가정해 보겠습니다. 악의적인 사용자가 그 모델에게 수학 숙제를 도와달라고 요청하게 두고 싶지는 않을 것입니다. 따라서 빠르고/저렴한 모델로 가드레일을 실행할 수 있습니다. 가드레일이 악의적인 사용을 감지하면 즉시 오류를 발생시켜 비싼 모델의 실행을 막을 수 있어 시간과 비용을 절약할 수 있습니다(**blocking guardrails를 사용할 때; parallel guardrails의 경우 가드레일이 완료되기 전에 비싼 모델이 이미 실행을 시작했을 수 있습니다. 자세한 내용은 아래의 "Execution modes"를 참고하세요**).

가드레일에는 두 가지 종류가 있습니다:

1. 입력 가드레일은 초기 사용자 입력에서 실행됩니다
2. 출력 가드레일은 최종 에이전트 출력에서 실행됩니다

## 워크플로 경계

가드레일은 에이전트와 도구에 연결되지만, 워크플로의 동일한 지점에서 모두 실행되지는 않습니다:

- **입력 가드레일**은 체인의 첫 번째 에이전트에 대해서만 실행됩니다
- **출력 가드레일**은 최종 출력을 생성하는 에이전트에 대해서만 실행됩니다
- **도구 가드레일**은 모든 커스텀 함수 도구 호출에서 실행되며, 실행 전에는 입력 가드레일이, 실행 후에는 출력 가드레일이 실행됩니다

매니저, 핸드오프 또는 위임된 전문 에이전트가 포함된 워크플로에서 각 커스텀 함수 도구 호출마다 검사가 필요하다면, 에이전트 수준의 입력/출력 가드레일에만 의존하지 말고 도구 가드레일을 사용하세요.

## 입력 가드레일

입력 가드레일은 3단계로 실행됩니다:

1. 먼저, 가드레일은 에이전트에 전달된 것과 동일한 입력을 받습니다
2. 다음으로, 가드레일 함수가 실행되어 [`GuardrailFunctionOutput`][agents.guardrail.GuardrailFunctionOutput]을 생성하고, 이는 [`InputGuardrailResult`][agents.guardrail.InputGuardrailResult]로 래핑됩니다
3. 마지막으로, [`.tripwire_triggered`][agents.guardrail.GuardrailFunctionOutput.tripwire_triggered]가 true인지 확인합니다. true이면 [`InputGuardrailTripwireTriggered`][agents.exceptions.InputGuardrailTripwireTriggered] 예외가 발생하므로, 사용자에게 적절히 응답하거나 예외를 처리할 수 있습니다

!!! Note

    입력 가드레일은 사용자 입력에서 실행되도록 설계되었으므로, 에이전트의 가드레일은 해당 에이전트가 *첫 번째* 에이전트일 때만 실행됩니다. 그렇다면 왜 가드레일을 `Runner.run`에 전달하지 않고 에이전트의 `guardrails` 속성에 두는지 궁금할 수 있습니다. 이는 가드레일이 실제 Agent와 관련되는 경향이 있기 때문입니다. 에이전트마다 다른 가드레일을 실행하게 되므로 코드를 함께 배치하면 가독성에 유리합니다.

### 실행 모드

입력 가드레일은 두 가지 실행 모드를 지원합니다:

- **병렬 실행**(기본값, `run_in_parallel=True`): 가드레일이 에이전트 실행과 동시에 실행됩니다. 둘 다 같은 시점에 시작되므로 지연 시간 측면에서 가장 유리합니다. 하지만 가드레일이 실패하면, 취소되기 전에 에이전트가 이미 토큰을 소비하고 도구를 실행했을 수 있습니다

- **차단 실행**(`run_in_parallel=False`): 에이전트가 시작되기 *전에* 가드레일이 실행되고 완료됩니다. 가드레일 트립와이어가 트리거되면 에이전트는 전혀 실행되지 않아 토큰 소비와 도구 실행을 방지합니다. 비용 최적화가 중요하고 도구 호출로 인한 잠재적 부작용을 피하고 싶을 때 이상적입니다

## 출력 가드레일

출력 가드레일은 3단계로 실행됩니다:

1. 먼저, 가드레일은 에이전트가 생성한 출력을 받습니다
2. 다음으로, 가드레일 함수가 실행되어 [`GuardrailFunctionOutput`][agents.guardrail.GuardrailFunctionOutput]을 생성하고, 이는 [`OutputGuardrailResult`][agents.guardrail.OutputGuardrailResult]로 래핑됩니다
3. 마지막으로, [`.tripwire_triggered`][agents.guardrail.GuardrailFunctionOutput.tripwire_triggered]가 true인지 확인합니다. true이면 [`OutputGuardrailTripwireTriggered`][agents.exceptions.OutputGuardrailTripwireTriggered] 예외가 발생하므로, 사용자에게 적절히 응답하거나 예외를 처리할 수 있습니다

!!! Note

    출력 가드레일은 최종 에이전트 출력에서 실행되도록 설계되었으므로, 에이전트의 가드레일은 해당 에이전트가 *마지막* 에이전트일 때만 실행됩니다. 입력 가드레일과 마찬가지로 이렇게 하는 이유는 가드레일이 실제 Agent와 관련되는 경향이 있기 때문입니다. 에이전트마다 다른 가드레일을 실행하게 되므로 코드를 함께 배치하면 가독성에 유리합니다.

    출력 가드레일은 항상 에이전트 완료 후 실행되므로 `run_in_parallel` 매개변수를 지원하지 않습니다.

## 도구 가드레일

도구 가드레일은 **함수 도구**를 감싸서 실행 전후에 도구 호출을 검증하거나 차단할 수 있게 합니다. 도구 자체에 구성되며 해당 도구가 호출될 때마다 실행됩니다.

- 입력 도구 가드레일은 도구 실행 전에 실행되며 호출 건너뛰기, 메시지로 출력 대체, 또는 트립와이어 발생을 수행할 수 있습니다
- 출력 도구 가드레일은 도구 실행 후에 실행되며 출력 대체 또는 트립와이어 발생을 수행할 수 있습니다
- 도구 가드레일은 [`function_tool`][agents.tool.function_tool]로 생성된 함수 도구에만 적용됩니다. 핸드오프는 일반 함수 도구 파이프라인이 아닌 SDK의 핸드오프 파이프라인을 통해 실행되므로, 핸드오프 호출 자체에는 도구 가드레일이 적용되지 않습니다. Hosted tools(`WebSearchTool`, `FileSearchTool`, `HostedMCPTool`, `CodeInterpreterTool`, `ImageGenerationTool`) 및 내장 실행 도구(`ComputerTool`, `ShellTool`, `ApplyPatchTool`, `LocalShellTool`)도 이 가드레일 파이프라인을 사용하지 않으며, [`Agent.as_tool()`][agents.agent.Agent.as_tool]은 현재 도구 가드레일 옵션을 직접 노출하지 않습니다

자세한 내용은 아래 코드 스니펫을 참고하세요.

## 트립와이어

입력 또는 출력이 가드레일 검사를 통과하지 못하면, Guardrail은 트립와이어로 이를 신호할 수 있습니다. 트립와이어가 트리거된 가드레일을 확인하는 즉시 `{Input,Output}GuardrailTripwireTriggered` 예외를 발생시키고 Agent 실행을 중단합니다.

## 가드레일 구현

입력을 받아 [`GuardrailFunctionOutput`][agents.guardrail.GuardrailFunctionOutput]을 반환하는 함수를 제공해야 합니다. 이 예제에서는 내부적으로 에이전트를 실행하는 방식으로 이를 수행합니다.

```python
from pydantic import BaseModel
from agents import (
    Agent,
    GuardrailFunctionOutput,
    InputGuardrailTripwireTriggered,
    RunContextWrapper,
    Runner,
    TResponseInputItem,
    input_guardrail,
)

class MathHomeworkOutput(BaseModel):
    is_math_homework: bool
    reasoning: str

guardrail_agent = Agent( # (1)!
    name="Guardrail check",
    instructions="Check if the user is asking you to do their math homework.",
    output_type=MathHomeworkOutput,
)


@input_guardrail
async def math_guardrail( # (2)!
    ctx: RunContextWrapper[None], agent: Agent, input: str | list[TResponseInputItem]
) -> GuardrailFunctionOutput:
    result = await Runner.run(guardrail_agent, input, context=ctx.context)

    return GuardrailFunctionOutput(
        output_info=result.final_output, # (3)!
        tripwire_triggered=result.final_output.is_math_homework,
    )


agent = Agent(  # (4)!
    name="Customer support agent",
    instructions="You are a customer support agent. You help customers with their questions.",
    input_guardrails=[math_guardrail],
)

async def main():
    # This should trip the guardrail
    try:
        await Runner.run(agent, "Hello, can you help me solve for x: 2x + 3 = 11?")
        print("Guardrail didn't trip - this is unexpected")

    except InputGuardrailTripwireTriggered:
        print("Math homework guardrail tripped")
```

1. 가드레일 함수에서 이 에이전트를 사용합니다
2. 에이전트의 입력/컨텍스트를 받아 결과를 반환하는 가드레일 함수입니다
3. 가드레일 결과에 추가 정보를 포함할 수 있습니다
4. 워크플로를 정의하는 실제 에이전트입니다

출력 가드레일도 유사합니다.

```python
from pydantic import BaseModel
from agents import (
    Agent,
    GuardrailFunctionOutput,
    OutputGuardrailTripwireTriggered,
    RunContextWrapper,
    Runner,
    output_guardrail,
)
class MessageOutput(BaseModel): # (1)!
    response: str

class MathOutput(BaseModel): # (2)!
    reasoning: str
    is_math: bool

guardrail_agent = Agent(
    name="Guardrail check",
    instructions="Check if the output includes any math.",
    output_type=MathOutput,
)

@output_guardrail
async def math_guardrail(  # (3)!
    ctx: RunContextWrapper, agent: Agent, output: MessageOutput
) -> GuardrailFunctionOutput:
    result = await Runner.run(guardrail_agent, output.response, context=ctx.context)

    return GuardrailFunctionOutput(
        output_info=result.final_output,
        tripwire_triggered=result.final_output.is_math,
    )

agent = Agent( # (4)!
    name="Customer support agent",
    instructions="You are a customer support agent. You help customers with their questions.",
    output_guardrails=[math_guardrail],
    output_type=MessageOutput,
)

async def main():
    # This should trip the guardrail
    try:
        await Runner.run(agent, "Hello, can you help me solve for x: 2x + 3 = 11?")
        print("Guardrail didn't trip - this is unexpected")

    except OutputGuardrailTripwireTriggered:
        print("Math output guardrail tripped")
```

1. 실제 에이전트의 출력 타입입니다
2. 가드레일의 출력 타입입니다
3. 에이전트의 출력을 받아 결과를 반환하는 가드레일 함수입니다
4. 워크플로를 정의하는 실제 에이전트입니다

마지막으로, 다음은 도구 가드레일 예시입니다.

```python
import json
from agents import (
    Agent,
    Runner,
    ToolGuardrailFunctionOutput,
    function_tool,
    tool_input_guardrail,
    tool_output_guardrail,
)

@tool_input_guardrail
def block_secrets(data):
    args = json.loads(data.context.tool_arguments or "{}")
    if "sk-" in json.dumps(args):
        return ToolGuardrailFunctionOutput.reject_content(
            "Remove secrets before calling this tool."
        )
    return ToolGuardrailFunctionOutput.allow()


@tool_output_guardrail
def redact_output(data):
    text = str(data.output or "")
    if "sk-" in text:
        return ToolGuardrailFunctionOutput.reject_content("Output contained sensitive data.")
    return ToolGuardrailFunctionOutput.allow()


@function_tool(
    tool_input_guardrails=[block_secrets],
    tool_output_guardrails=[redact_output],
)
def classify_text(text: str) -> str:
    """Classify text for internal routing."""
    return f"length:{len(text)}"


agent = Agent(name="Classifier", tools=[classify_text])
result = Runner.run_sync(agent, "hello world")
print(result.final_output)
```

================
File: docs/ko/handoffs.md
================
---
search:
  exclude: true
---
# 핸드오프

핸드오프를 사용하면 한 에이전트가 다른 에이전트에 작업을 위임할 수 있습니다. 이는 서로 다른 에이전트가 각기 다른 영역을 전문으로 하는 시나리오에서 특히 유용합니다. 예를 들어 고객 지원 앱에는 주문 상태, 환불, FAQ 등의 작업을 각각 전담하는 에이전트가 있을 수 있습니다.

핸드오프는 LLM에 도구로 표현됩니다. 따라서 `Refund Agent`라는 이름의 에이전트로 핸드오프가 있으면 도구 이름은 `transfer_to_refund_agent`가 됩니다.

## 핸드오프 생성

모든 에이전트에는 [`handoffs`][agents.agent.Agent.handoffs] 매개변수가 있으며, 여기에 `Agent`를 직접 전달하거나 핸드오프를 사용자 지정하는 `Handoff` 객체를 전달할 수 있습니다.

일반 `Agent` 인스턴스를 전달하면 해당 [`handoff_description`][agents.agent.Agent.handoff_description] (설정된 경우)이 기본 도구 설명에 추가됩니다. 전체 `handoff()` 객체를 작성하지 않고도 모델이 해당 핸드오프를 선택해야 하는 시점을 힌트로 제공할 때 사용하세요.

Agents SDK가 제공하는 [`handoff()`][agents.handoffs.handoff] 함수를 사용해 핸드오프를 만들 수 있습니다. 이 함수로 핸드오프 대상 에이전트와 선택적 재정의 및 입력 필터를 지정할 수 있습니다.

### 기본 사용법

간단한 핸드오프를 만드는 방법은 다음과 같습니다:

```python
from agents import Agent, handoff

billing_agent = Agent(name="Billing agent")
refund_agent = Agent(name="Refund agent")

# (1)!
triage_agent = Agent(name="Triage agent", handoffs=[billing_agent, handoff(refund_agent)])
```

1. 에이전트를 직접 사용할 수 있고(`billing_agent`처럼), 또는 `handoff()` 함수를 사용할 수 있습니다.

### `handoff()` 함수로 핸드오프 사용자 지정

[`handoff()`][agents.handoffs.handoff] 함수로 여러 항목을 사용자 지정할 수 있습니다.

-   `agent`: 핸드오프 대상 에이전트입니다.
-   `tool_name_override`: 기본적으로 `Handoff.default_tool_name()` 함수가 사용되며, `transfer_to_<agent_name>`으로 해석됩니다. 이를 재정의할 수 있습니다.
-   `tool_description_override`: `Handoff.default_tool_description()`의 기본 도구 설명을 재정의합니다
-   `on_handoff`: 핸드오프가 호출될 때 실행되는 콜백 함수입니다. 핸드오프 호출이 확정되는 즉시 데이터 페칭을 시작하는 등의 용도에 유용합니다. 이 함수는 에이전트 컨텍스트를 받으며, 선택적으로 LLM이 생성한 입력도 받을 수 있습니다. 입력 데이터는 `input_type` 매개변수로 제어됩니다.
-   `input_type`: 핸드오프 도구 호출 인자의 스키마입니다. 설정하면 파싱된 페이로드가 `on_handoff`로 전달됩니다.
-   `input_filter`: 다음 에이전트가 받는 입력을 필터링할 수 있습니다. 자세한 내용은 아래를 참고하세요.
-   `is_enabled`: 핸드오프 활성화 여부입니다. 불리언 또는 불리언을 반환하는 함수가 될 수 있어 런타임에 동적으로 핸드오프를 활성화/비활성화할 수 있습니다.
-   `nest_handoff_history`: RunConfig 수준의 `nest_handoff_history` 설정에 대한 선택적 호출별 재정의입니다. `None`이면 활성 run 설정에 정의된 값을 대신 사용합니다.

[`handoff()`][agents.handoffs.handoff] 헬퍼는 항상 전달한 특정 `agent`로 제어를 넘깁니다. 가능한 대상이 여러 개라면 대상마다 하나의 핸드오프를 등록하고 모델이 그중에서 선택하게 하세요. 호출 시점에 어떤 에이전트를 반환할지 직접 핸드오프 코드에서 결정해야 할 때만 사용자 지정 [`Handoff`][agents.handoffs.Handoff]를 사용하세요.

```python
from agents import Agent, handoff, RunContextWrapper

def on_handoff(ctx: RunContextWrapper[None]):
    print("Handoff called")

agent = Agent(name="My agent")

handoff_obj = handoff(
    agent=agent,
    on_handoff=on_handoff,
    tool_name_override="custom_handoff_tool",
    tool_description_override="Custom description",
)
```

## 핸드오프 입력

특정 상황에서는 핸드오프를 호출할 때 LLM이 일부 데이터를 제공하도록 하고 싶을 수 있습니다. 예를 들어 "Escalation agent"로 핸드오프한다고 가정해 보겠습니다. 이때 기록을 남기기 위해 사유를 함께 받도록 할 수 있습니다.

```python
from pydantic import BaseModel

from agents import Agent, handoff, RunContextWrapper

class EscalationData(BaseModel):
    reason: str

async def on_handoff(ctx: RunContextWrapper[None], input_data: EscalationData):
    print(f"Escalation agent called with reason: {input_data.reason}")

agent = Agent(name="Escalation agent")

handoff_obj = handoff(
    agent=agent,
    on_handoff=on_handoff,
    input_type=EscalationData,
)
```

`input_type`은 핸드오프 도구 호출 자체의 인자를 설명합니다. SDK는 그 스키마를 핸드오프 도구의 `parameters`로 모델에 노출하고, 반환된 JSON을 로컬에서 검증한 뒤, 파싱된 값을 `on_handoff`에 전달합니다.

이는 다음 에이전트의 기본 입력을 대체하지 않으며, 다른 목적지를 선택하지도 않습니다. [`handoff()`][agents.handoffs.handoff] 헬퍼는 여전히 래핑한 특정 에이전트로 전송하며, 수신 에이전트는 [`input_filter`][agents.handoffs.Handoff.input_filter] 또는 중첩 핸드오프 기록 설정으로 변경하지 않는 한 대화 기록을 계속 확인합니다.

`input_type`은 [`RunContextWrapper.context`][agents.run_context.RunContextWrapper.context]와도 별개입니다. 이미 로컬에 있는 애플리케이션 상태나 의존성이 아니라, 모델이 핸드오프 시점에 결정하는 메타데이터에 `input_type`을 사용하세요.

### `input_type` 사용 시점

핸드오프에 `reason`, `language`, `priority`, `summary` 같은 모델 생성 메타데이터의 작은 조각이 필요할 때 `input_type`을 사용하세요. 예를 들어 트리아지 에이전트는 `{ "reason": "duplicate_charge", "priority": "high" }`와 함께 환불 에이전트로 핸드오프할 수 있으며, `on_handoff`는 환불 에이전트가 이어받기 전에 해당 메타데이터를 기록하거나 저장할 수 있습니다.

목적이 다르면 다른 메커니즘을 선택하세요:

-   기존 애플리케이션 상태와 의존성은 [`RunContextWrapper.context`][agents.run_context.RunContextWrapper.context]에 넣으세요. [컨텍스트 가이드](context.md)를 참고하세요.
-   수신 에이전트가 보는 기록을 바꾸려면 [`input_filter`][agents.handoffs.Handoff.input_filter], [`RunConfig.nest_handoff_history`][agents.run.RunConfig.nest_handoff_history], 또는 [`RunConfig.handoff_history_mapper`][agents.run.RunConfig.handoff_history_mapper]를 사용하세요.
-   가능한 전문 에이전트 대상이 여러 개라면 대상마다 하나의 핸드오프를 등록하세요. `input_type`은 선택된 핸드오프에 메타데이터를 추가할 수는 있지만, 대상 간 디스패치를 수행하지는 않습니다.
-   대화를 전송하지 않고 중첩 전문 에이전트에 구조화된 입력을 주고 싶다면 [`Agent.as_tool(parameters=...)`][agents.agent.Agent.as_tool]을 우선 사용하세요. [도구](tools.md#structured-input-for-tool-agents)를 참고하세요.

## 입력 필터

핸드오프가 발생하면 새 에이전트가 대화를 이어받아 이전 전체 대화 기록을 보는 것과 같습니다. 이를 변경하려면 [`input_filter`][agents.handoffs.Handoff.input_filter]를 설정할 수 있습니다. 입력 필터는 [`HandoffInputData`][agents.handoffs.HandoffInputData]를 통해 기존 입력을 받고, 새로운 `HandoffInputData`를 반환해야 하는 함수입니다.

[`HandoffInputData`][agents.handoffs.HandoffInputData]에는 다음이 포함됩니다:

-   `input_history`: `Runner.run(...)` 시작 전의 입력 기록
-   `pre_handoff_items`: 핸드오프가 호출된 에이전트 턴 이전에 생성된 항목
-   `new_items`: 핸드오프 호출 및 핸드오프 출력 항목을 포함해 현재 턴에서 생성된 항목
-   `input_items`: `new_items` 대신 다음 에이전트로 전달할 선택적 항목으로, 세션 기록용 `new_items`는 유지하면서 모델 입력을 필터링할 수 있게 해줍니다
-   `run_context`: 핸드오프 호출 시점의 활성 [`RunContextWrapper`][agents.run_context.RunContextWrapper]

중첩 핸드오프는 옵트인 베타로 제공되며 안정화 중이므로 기본적으로 비활성화되어 있습니다. [`RunConfig.nest_handoff_history`][agents.run.RunConfig.nest_handoff_history]를 활성화하면 러너는 이전 전사를 단일 어시스턴트 요약 메시지로 축약하고, 동일 run에서 여러 핸드오프가 발생할 때 새 턴이 계속 추가되도록 `<CONVERSATION HISTORY>` 블록으로 감쌉니다. 전체 `input_filter`를 작성하지 않고 생성된 메시지를 대체하려면 [`RunConfig.handoff_history_mapper`][agents.run.RunConfig.handoff_history_mapper]를 통해 자체 매핑 함수를 제공할 수 있습니다. 이 옵트인은 핸드오프와 run 어느 쪽에서도 명시적 `input_filter`를 제공하지 않을 때만 적용되므로, 이미 페이로드를 사용자 지정하는 기존 코드(이 저장소의 예제 포함)는 변경 없이 현재 동작을 유지합니다. [`handoff(...)`][agents.handoffs.handoff]에 `nest_handoff_history=True` 또는 `False`를 전달해 단일 핸드오프의 중첩 동작을 재정의할 수 있으며, 이는 [`Handoff.nest_handoff_history`][agents.handoffs.Handoff.nest_handoff_history]를 설정합니다. 생성된 요약의 래퍼 텍스트만 바꾸면 된다면 에이전트를 실행하기 전에 [`set_conversation_history_wrappers`][agents.handoffs.set_conversation_history_wrappers] (및 선택적으로 [`reset_conversation_history_wrappers`][agents.handoffs.reset_conversation_history_wrappers])를 호출하세요.

핸드오프와 활성 [`RunConfig.handoff_input_filter`][agents.run.RunConfig.handoff_input_filter] 양쪽 모두 필터를 정의한 경우, 해당 핸드오프에는 핸드오프별 [`input_filter`][agents.handoffs.Handoff.input_filter]가 우선 적용됩니다.

!!! note

    핸드오프는 단일 run 내에서만 유지됩니다. 입력 가드레일은 체인의 첫 번째 에이전트에만 계속 적용되고, 출력 가드레일은 최종 출력을 생성하는 에이전트에만 적용됩니다. 워크플로 내 각 사용자 지정 함수 도구 호출 주변에서 검사가 필요하다면 도구 가드레일을 사용하세요.

일부 일반 패턴(예: 기록에서 모든 도구 호출 제거)은 [`agents.extensions.handoff_filters`][]에 구현되어 있습니다

```python
from agents import Agent, handoff
from agents.extensions import handoff_filters

agent = Agent(name="FAQ agent")

handoff_obj = handoff(
    agent=agent,
    input_filter=handoff_filters.remove_all_tools, # (1)!
)
```

1. 이렇게 하면 `FAQ agent`가 호출될 때 기록에서 모든 도구가 자동으로 제거됩니다.

## 권장 프롬프트

LLM이 핸드오프를 올바르게 이해하도록 하려면, 에이전트에 핸드오프 관련 정보를 포함할 것을 권장합니다. [`agents.extensions.handoff_prompt.RECOMMENDED_PROMPT_PREFIX`][]에 권장 접두사가 있으며, [`agents.extensions.handoff_prompt.prompt_with_handoff_instructions`][]를 호출해 프롬프트에 권장 데이터를 자동으로 추가할 수도 있습니다.

```python
from agents import Agent
from agents.extensions.handoff_prompt import RECOMMENDED_PROMPT_PREFIX

billing_agent = Agent(
    name="Billing agent",
    instructions=f"""{RECOMMENDED_PROMPT_PREFIX}
    <Fill in the rest of your prompt here>.""",
)
```

================
File: docs/ko/human_in_the_loop.md
================
---
search:
  exclude: true
---
# 휴먼인더루프 (HITL)

human-in-the-loop (HITL) 흐름을 사용하면 민감한 도구 호출을 사람이 승인하거나 거부할 때까지 에이전트 실행을 일시 중지할 수 있습니다. 도구는 승인 필요 여부를 선언하고, 실행 결과의 보류 중 승인 항목은 인터럽션으로 표시되며, `RunState` 를 통해 결정 이후 실행을 직렬화하고 재개할 수 있습니다.

이 승인 표면은 현재 최상위 에이전트에만 제한되지 않고 실행 전체에 적용됩니다. 동일한 패턴은 도구가 현재 에이전트에 속한 경우, 핸드오프를 통해 도달한 에이전트에 속한 경우, 또는 중첩된 [`Agent.as_tool()`][agents.agent.Agent.as_tool] 실행에 속한 경우에도 적용됩니다. 중첩 `Agent.as_tool()` 의 경우에도 인터럽션은 외부 실행에 표시되므로, 외부 `RunState` 에서 승인 또는 거부하고 원래 최상위 실행을 재개합니다.

`Agent.as_tool()` 에서는 서로 다른 두 계층에서 승인이 발생할 수 있습니다: 에이전트 도구 자체가 `Agent.as_tool(..., needs_approval=...)` 를 통해 승인을 요구할 수 있고, 중첩 실행이 시작된 뒤 중첩 에이전트 내부 도구가 자체 승인을 추가로 발생시킬 수 있습니다. 둘 다 동일한 외부 실행 인터럽션 흐름으로 처리됩니다.

이 페이지는 `interruptions` 를 통한 수동 승인 흐름에 중점을 둡니다. 앱이 코드에서 결정을 내릴 수 있다면, 일부 도구 유형은 프로그래밍 방식 승인 콜백도 지원하므로 실행을 일시 중지하지 않고 계속 진행할 수 있습니다.

## 승인 필요 도구 표시

`needs_approval` 을 `True` 로 설정하면 항상 승인이 필요하며, 호출별로 결정하는 비동기 함수를 제공할 수도 있습니다. 이 callable 은 실행 컨텍스트, 파싱된 도구 매개변수, 도구 호출 ID 를 받습니다.

```python
from agents import Agent, Runner, function_tool


@function_tool(needs_approval=True)
async def cancel_order(order_id: int) -> str:
    return f"Cancelled order {order_id}"


async def requires_review(_ctx, params, _call_id) -> bool:
    return "refund" in params.get("subject", "").lower()


@function_tool(needs_approval=requires_review)
async def send_email(subject: str, body: str) -> str:
    return f"Sent '{subject}'"


agent = Agent(
    name="Support agent",
    instructions="Handle tickets and ask for approval when needed.",
    tools=[cancel_order, send_email],
)
```

`needs_approval` 은 [`function_tool`][agents.tool.function_tool], [`Agent.as_tool`][agents.agent.Agent.as_tool], [`ShellTool`][agents.tool.ShellTool], [`ApplyPatchTool`][agents.tool.ApplyPatchTool] 에서 사용할 수 있습니다. 로컬 MCP 서버도 [`MCPServerStdio`][agents.mcp.server.MCPServerStdio], [`MCPServerSse`][agents.mcp.server.MCPServerSse], [`MCPServerStreamableHttp`][agents.mcp.server.MCPServerStreamableHttp] 의 `require_approval` 을 통해 승인을 지원합니다. 호스티드 MCP 서버는 [`HostedMCPTool`][agents.tool.HostedMCPTool] 의 `tool_config={"require_approval": "always"}` 와 선택적 `on_approval_request` 콜백을 통해 승인을 지원합니다. Shell 및 apply_patch 도구는 인터럽션을 노출하지 않고 자동 승인 또는 자동 거부하려는 경우 `on_approval` 콜백을 받을 수 있습니다.

## 승인 흐름 작동 방식

1. 모델이 도구 호출을 생성하면 러너가 해당 승인 규칙(`needs_approval`, `require_approval`, 또는 호스티드 MCP 동등 설정)을 평가합니다
2. 해당 도구 호출에 대한 승인 결정이 이미 [`RunContextWrapper`][agents.run_context.RunContextWrapper] 에 저장되어 있다면, 러너는 추가 프롬프트 없이 진행합니다. 호출별 승인은 특정 호출 ID 범위로 제한됩니다. 실행의 남은 기간 동안 해당 도구의 이후 호출에도 동일 결정을 유지하려면 `always_approve=True` 또는 `always_reject=True` 를 전달하세요
3. 그렇지 않으면 실행이 일시 중지되고 `RunResult.interruptions` (또는 `RunResultStreaming.interruptions`) 에 `agent.name`, `tool_name`, `arguments` 같은 세부 정보를 담은 [`ToolApprovalItem`][agents.items.ToolApprovalItem] 항목이 포함됩니다. 여기에는 핸드오프 이후 또는 중첩 `Agent.as_tool()` 실행 내부에서 발생한 승인도 포함됩니다
4. 결과를 `result.to_state()` 로 `RunState` 로 변환하고, `state.approve(...)` 또는 `state.reject(...)` 를 호출한 다음, `Runner.run(agent, state)` 또는 `Runner.run_streamed(agent, state)` 로 재개합니다. 여기서 `agent` 는 해당 실행의 원래 최상위 에이전트입니다
5. 재개된 실행은 중단된 지점부터 계속되며, 새로운 승인이 필요하면 이 흐름으로 다시 진입합니다

`always_approve=True` 또는 `always_reject=True` 로 생성된 고정 결정은 실행 상태에 저장되므로, 나중에 동일한 일시 중지 실행을 재개할 때 `state.to_string()` / `RunState.from_string(...)` 및 `state.to_json()` / `RunState.from_json(...)` 에서도 유지됩니다.

동일한 패스에서 모든 보류 승인을 해결할 필요는 없습니다. `interruptions` 에는 일반 함수 도구, 호스티드 MCP 승인, 중첩 `Agent.as_tool()` 승인이 섞여 있을 수 있습니다. 일부 항목만 승인 또는 거부한 뒤 다시 실행하면, 해결된 호출은 계속 진행되고 미해결 항목은 `interruptions` 에 남아 실행을 다시 일시 중지합니다.

## 자동 승인 결정

수동 `interruptions` 이 가장 일반적인 패턴이지만, 유일한 방식은 아닙니다:

- 로컬 [`ShellTool`][agents.tool.ShellTool] 및 [`ApplyPatchTool`][agents.tool.ApplyPatchTool] 은 `on_approval` 을 사용해 코드에서 즉시 승인 또는 거부할 수 있습니다
- [`HostedMCPTool`][agents.tool.HostedMCPTool] 은 같은 유형의 프로그래밍 방식 결정을 위해 `tool_config={"require_approval": "always"}` 와 `on_approval_request` 를 함께 사용할 수 있습니다
- 일반 [`function_tool`][agents.tool.function_tool] 도구와 [`Agent.as_tool()`][agents.agent.Agent.as_tool] 은 이 페이지의 수동 인터럽션 흐름을 사용합니다

이러한 콜백이 결정을 반환하면, 실행은 사람의 응답을 기다리며 일시 중지하지 않고 계속됩니다. Realtime 및 음성 세션 API 의 경우 [Realtime guide](realtime/guide.md)의 승인 흐름을 참조하세요.

## 스트리밍과 세션

동일한 인터럽션 흐름은 스트리밍 실행에서도 동작합니다. 스트리밍 실행이 일시 중지된 후, 이터레이터가 끝날 때까지 [`RunResultStreaming.stream_events()`][agents.result.RunResultStreaming.stream_events] 를 계속 소비하고, [`RunResultStreaming.interruptions`][agents.result.RunResultStreaming.interruptions] 를 확인해 해결한 뒤, 재개 출력도 계속 스트리밍하려면 [`Runner.run_streamed(...)`][agents.run.Runner.run_streamed] 로 재개하세요. 이 패턴의 스트리밍 버전은 [Streaming](streaming.md)을 참조하세요.

세션도 함께 사용하는 경우 `RunState` 에서 재개할 때 동일한 세션 인스턴스를 계속 전달하거나, 동일한 백킹 스토어를 가리키는 다른 세션 객체를 전달하세요. 그러면 재개된 턴이 동일한 저장 대화 이력에 추가됩니다. 세션 수명주기 상세 내용은 [Sessions](sessions/index.md)를 참조하세요.

## 예시: 일시 중지, 승인, 재개

아래 스니펫은 JavaScript HITL 가이드를 반영합니다: 도구에 승인이 필요하면 일시 중지하고, 상태를 디스크에 저장한 뒤, 다시 로드하고, 결정을 수집한 후 재개합니다.

```python
import asyncio
import json
from pathlib import Path

from agents import Agent, Runner, RunState, function_tool


async def needs_oakland_approval(_ctx, params, _call_id) -> bool:
    return "Oakland" in params.get("city", "")


@function_tool(needs_approval=needs_oakland_approval)
async def get_temperature(city: str) -> str:
    return f"The temperature in {city} is 20° Celsius"


agent = Agent(
    name="Weather assistant",
    instructions="Answer weather questions with the provided tools.",
    tools=[get_temperature],
)

STATE_PATH = Path(".cache/hitl_state.json")


def prompt_approval(tool_name: str, arguments: str | None) -> bool:
    answer = input(f"Approve {tool_name} with {arguments}? [y/N]: ").strip().lower()
    return answer in {"y", "yes"}


async def main() -> None:
    result = await Runner.run(agent, "What is the temperature in Oakland?")

    while result.interruptions:
        # Persist the paused state.
        state = result.to_state()
        STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
        STATE_PATH.write_text(state.to_string())

        # Load the state later (could be a different process).
        stored = json.loads(STATE_PATH.read_text())
        state = await RunState.from_json(agent, stored)

        for interruption in result.interruptions:
            approved = await asyncio.get_running_loop().run_in_executor(
                None, prompt_approval, interruption.name or "unknown_tool", interruption.arguments
            )
            if approved:
                state.approve(interruption, always_approve=False)
            else:
                state.reject(interruption)

        result = await Runner.run(agent, state)

    print(result.final_output)


if __name__ == "__main__":
    asyncio.run(main())
```

이 예시에서 `prompt_approval` 는 `input()` 을 사용하고 `run_in_executor(...)` 로 실행되므로 동기식입니다. 승인 소스가 이미 비동기(예: HTTP 요청 또는 비동기 데이터베이스 쿼리)라면, 대신 `async def` 함수를 사용하고 직접 `await` 할 수 있습니다.

승인을 기다리는 동안 출력을 스트리밍하려면 `Runner.run_streamed` 를 호출하고, 완료될 때까지 `result.stream_events()` 를 소비한 다음, 위에 나온 동일한 `result.to_state()` 및 재개 단계를 따르세요.

## 저장소 패턴 및 코드 예제

- **스트리밍 승인**: `examples/agent_patterns/human_in_the_loop_stream.py` 는 `stream_events()` 를 모두 소비한 뒤 보류 중 도구 호출을 승인하고 `Runner.run_streamed(agent, state)` 로 재개하는 방법을 보여줍니다
- **Agent as tool 승인**: `Agent.as_tool(..., needs_approval=...)` 는 위임된 에이전트 작업에 검토가 필요할 때 동일한 인터럽션 흐름을 적용합니다. 중첩 인터럽션도 외부 실행에 표시되므로, 중첩 에이전트가 아니라 원래 최상위 에이전트를 재개하세요
- **로컬 shell 및 apply_patch 도구**: `ShellTool` 과 `ApplyPatchTool` 도 `needs_approval` 을 지원합니다. 이후 호출에 대한 결정을 캐시하려면 `state.approve(interruption, always_approve=True)` 또는 `state.reject(..., always_reject=True)` 를 사용하세요. 자동 결정을 위해서는 `on_approval` 을 제공하고(`examples/tools/shell.py` 참조), 수동 결정을 위해서는 인터럽션을 처리하세요(`examples/tools/shell_human_in_the_loop.py` 참조). 호스티드 shell 환경은 `needs_approval` 또는 `on_approval` 을 지원하지 않습니다. [tools guide](tools.md)를 참조하세요
- **로컬 MCP 서버**: MCP 도구 호출을 제어하려면 `MCPServerStdio` / `MCPServerSse` / `MCPServerStreamableHttp` 에 `require_approval` 을 사용하세요(`examples/mcp/get_all_mcp_tools_example/main.py` 및 `examples/mcp/tool_filter_example/main.py` 참조)
- **호스티드 MCP 서버**: HITL 을 강제하려면 `HostedMCPTool` 에서 `require_approval` 을 `"always"` 로 설정하고, 선택적으로 `on_approval_request` 를 제공해 자동 승인 또는 거부할 수 있습니다(`examples/hosted_mcp/human_in_the_loop.py` 및 `examples/hosted_mcp/on_approval.py` 참조). 신뢰할 수 있는 서버에는 `"never"` 를 사용하세요(`examples/hosted_mcp/simple.py`)
- **세션 및 메모리**: 승인과 대화 이력이 여러 턴에 걸쳐 유지되도록 `Runner.run` 에 세션을 전달하세요. SQLite 및 OpenAI Conversations 세션 변형은 `examples/memory/memory_session_hitl_example.py` 및 `examples/memory/openai_session_hitl_example.py` 에 있습니다
- **실시간 에이전트**: realtime 데모는 `RealtimeSession` 의 `approve_tool_call` / `reject_tool_call` 을 통해 도구 호출을 승인 또는 거부하는 WebSocket 메시지를 노출합니다(서버 측 핸들러는 `examples/realtime/app/server.py`, API 표면은 [Realtime guide](realtime/guide.md#tool-approvals) 참조)

## 장기 실행 승인

`RunState` 는 내구성을 고려해 설계되었습니다. 대기 중 작업을 데이터베이스나 큐에 저장하려면 `state.to_json()` 또는 `state.to_string()` 을 사용하고, 나중에 `RunState.from_json(...)` 또는 `RunState.from_string(...)` 으로 다시 생성하세요.

유용한 직렬화 옵션:

- `context_serializer`: 비매핑 컨텍스트 객체를 직렬화하는 방법을 사용자 지정합니다
- `context_deserializer`: `RunState.from_json(...)` 또는 `RunState.from_string(...)` 으로 상태를 로드할 때 비매핑 컨텍스트 객체를 다시 구성합니다
- `strict_context=True`: 컨텍스트가 이미 매핑이거나 적절한 serializer/deserializer 를 제공하지 않으면 직렬화 또는 역직렬화를 실패시킵니다
- `context_override`: 상태 로드 시 직렬화된 컨텍스트를 대체합니다. 원래 컨텍스트 객체를 복원하고 싶지 않을 때 유용하지만, 이미 직렬화된 페이로드에서 해당 컨텍스트를 제거하지는 않습니다
- `include_tracing_api_key=True`: 재개된 작업이 동일한 자격 증명으로 트레이스를 계속 내보내야 할 때 직렬화된 trace 페이로드에 tracing API 키를 포함합니다

직렬화된 실행 상태에는 앱 컨텍스트와 함께, 승인, 사용량, 직렬화된 `tool_input`, 중첩 agent-as-tool 재개, trace 메타데이터, 서버 관리 대화 설정 같은 SDK 관리 런타임 메타데이터가 포함됩니다. 직렬화된 상태를 저장하거나 전송할 계획이라면 `RunContextWrapper.context` 를 영속 데이터로 간주하고, 상태와 함께 이동하도록 의도한 경우가 아니라면 비밀 정보를 넣지 마세요.

## 보류 작업 버전 관리

승인이 한동안 대기될 수 있다면, 직렬화된 상태와 함께 에이전트 정의 또는 SDK 버전 마커를 저장하세요. 그러면 모델, 프롬프트, 도구 정의가 바뀔 때 비호환을 피할 수 있도록 일치하는 코드 경로로 역직렬화를 라우팅할 수 있습니다.

================
File: docs/ko/index.md
================
---
search:
  exclude: true
---
# OpenAI Agents SDK

[OpenAI Agents SDK](https://github.com/openai/openai-agents-python)는 매우 적은 추상화로 구성된 가볍고 사용하기 쉬운 패키지에서 에이전트형 AI 앱을 구축할 수 있게 해줍니다. 이는 이전의 에이전트 실험인 [Swarm](https://github.com/openai/swarm/tree/main)을 프로덕션 준비 수준으로 업그레이드한 것입니다. Agents SDK는 매우 작은 기본 구성요소 집합을 제공합니다

-   **에이전트**: instructions와 tools를 갖춘 LLM
-   **Agents as tools / 핸드오프**: 특정 작업을 위해 에이전트가 다른 에이전트에게 위임할 수 있게 하는 기능
-   **가드레일**: 에이전트 입력 및 출력 검증을 가능하게 하는 기능

파이썬과 결합하면, 이러한 기본 구성요소는 도구와 에이전트 간의 복잡한 관계를 표현할 만큼 강력하며, 가파른 학습 곡선 없이 실제 애플리케이션을 구축할 수 있게 해줍니다. 또한 SDK에는 에이전트형 흐름을 시각화하고 디버그할 수 있으며, 평가하고 애플리케이션에 맞게 모델을 파인튜닝할 수 있도록 하는 내장 **트레이싱**이 포함되어 있습니다.

## Agents SDK 사용 이유

SDK에는 두 가지 핵심 설계 원칙이 있습니다

1. 사용할 가치가 있을 만큼 충분한 기능을 제공하되, 빠르게 학습할 수 있을 만큼 기본 구성요소는 적게 유지합니다.
2. 기본 설정만으로도 훌륭하게 동작하지만, 어떤 일이 일어나는지 정확히 원하는 대로 사용자 지정할 수 있습니다.

다음은 SDK의 주요 기능입니다

-   **에이전트 루프**: 도구 호출을 처리하고, 결과를 LLM으로 다시 보내며, 작업이 완료될 때까지 계속하는 내장 에이전트 루프
-   **파이썬 우선**: 새로운 추상화를 배울 필요 없이, 내장 언어 기능으로 에이전트를 오케스트레이션하고 체이닝
-   **Agents as tools / 핸드오프**: 여러 에이전트 간 작업을 조정하고 위임하는 강력한 메커니즘
-   **가드레일**: 에이전트 실행과 병렬로 입력 검증 및 안전성 검사를 수행하고, 검사를 통과하지 못하면 빠르게 실패 처리
-   **함수 도구**: 자동 스키마 생성 및 Pydantic 기반 검증으로 모든 파이썬 함수를 도구로 변환
-   **MCP 서버 도구 호출**: 함수 도구와 동일한 방식으로 동작하는 내장 MCP 서버 도구 통합
-   **세션**: 에이전트 루프 내 작업 컨텍스트 유지를 위한 지속형 메모리 계층
-   **휴먼인더루프 (HITL)**: 에이전트 실행 전반에 사람을 참여시키는 내장 메커니즘
-   **트레이싱**: 워크플로 시각화, 디버깅, 모니터링을 위한 내장 트레이싱과 OpenAI 평가, 파인튜닝, 증류 도구 모음 지원
-   **실시간 에이전트**: 자동 인터럽션(중단 처리) 감지, 컨텍스트 관리, 가드레일 등의 기능으로 강력한 음성 에이전트 구축

## 설치

```bash
pip install openai-agents
```

## Hello World 예제

```python
from agents import Agent, Runner

agent = Agent(name="Assistant", instructions="You are a helpful assistant")

result = Runner.run_sync(agent, "Write a haiku about recursion in programming.")
print(result.final_output)

# Code within the code,
# Functions calling themselves,
# Infinite loop's dance.
```

(_이를 실행하는 경우 `OPENAI_API_KEY` 환경 변수를 설정했는지 확인하세요_)

```bash
export OPENAI_API_KEY=sk-...
```

## 시작 지점

-   [Quickstart](quickstart.md)로 첫 텍스트 기반 에이전트를 만들어 보세요
-   그런 다음 [Running agents](running_agents.md#choose-a-memory-strategy)에서 턴 간 상태를 유지할 방법을 결정하세요
-   핸드오프와 매니저 스타일 오케스트레이션 중에서 고민 중이라면 [Agent orchestration](multi_agent.md)을 읽어보세요

## 경로 선택

수행하려는 작업은 알지만 이를 설명하는 페이지를 모를 때 이 표를 사용하세요.

| 목표 | 시작 지점 |
| --- | --- |
| 첫 텍스트 에이전트를 만들고 하나의 전체 실행 보기 | [Quickstart](quickstart.md) |
| 함수 도구, 호스티드 툴 또는 Agents as tools 추가 | [Tools](tools.md) |
| 핸드오프와 매니저 스타일 오케스트레이션 중 결정 | [Agent orchestration](multi_agent.md) |
| 턴 간 메모리 유지 | [Running agents](running_agents.md#choose-a-memory-strategy) 및 [Sessions](sessions/index.md) |
| OpenAI 모델, websocket 전송 또는 비OpenAI 제공자 사용 | [Models](models/index.md) |
| 출력, run 항목, 인터럽션(중단 처리), 상태 재개 검토 | [Results](results.md) |
| 저지연 음성 에이전트 구축 | [Realtime agents quickstart](realtime/quickstart.md) 및 [Realtime transport](realtime/transport.md) |
| speech-to-text / 에이전트 / text-to-speech 파이프라인 구축 | [Voice pipeline quickstart](voice/quickstart.md) |

================
File: docs/ko/mcp.md
================
---
search:
  exclude: true
---
# Model context protocol (MCP)

[Model context protocol](https://modelcontextprotocol.io/introduction) (MCP)은 애플리케이션이 언어 모델에 도구와 컨텍스트를 노출하는 방식을 표준화합니다. 공식 문서에서는 다음과 같이 설명합니다

> MCP는 애플리케이션이 LLM에 컨텍스트를 제공하는 방식을 표준화하는 개방형 프로토콜입니다. MCP를 AI 애플리케이션용 USB-C 포트라고 생각해 보세요
> USB-C가 다양한 주변기기 및 액세서리에 장치를 연결하는 표준화된 방법을 제공하듯이, MCP는 AI 모델을 다양한 데이터 소스 및 도구에 연결하는 표준화된 방법을 제공합니다

Agents Python SDK는 여러 MCP 전송 방식을 지원합니다. 이를 통해 기존 MCP 서버를 재사용하거나 자체 서버를 구축하여 파일 시스템, HTTP 또는 커넥터 기반 도구를 에이전트에 노출할 수 있습니다.

## MCP 통합 선택

MCP 서버를 에이전트에 연결하기 전에, 도구 호출이 어디에서 실행되어야 하는지와 어떤 전송 방식에 접근할 수 있는지를 결정해야 합니다. 아래 매트릭스는 Python SDK가 지원하는 옵션을 요약합니다.

| 필요한 사항 | 권장 옵션 |
| ------------------------------------------------------------------------------------ | ----------------------------------------------------- |
| 모델을 대신해 OpenAI의 Responses API가 공개적으로 접근 가능한 MCP 서버를 호출하도록 하기| [`HostedMCPTool`][agents.tool.HostedMCPTool]을 통한 **호스티드 MCP 서버 도구** |
| 로컬 또는 원격에서 실행 중인 Streamable HTTP 서버에 연결하기 | [`MCPServerStreamableHttp`][agents.mcp.server.MCPServerStreamableHttp]를 통한 **Streamable HTTP MCP 서버** |
| Server-Sent Events를 사용하는 HTTP를 구현한 서버와 통신하기 | [`MCPServerSse`][agents.mcp.server.MCPServerSse]를 통한 **SSE 기반 HTTP MCP 서버** |
| 로컬 프로세스를 실행하고 stdin/stdout으로 통신하기 | [`MCPServerStdio`][agents.mcp.server.MCPServerStdio]를 통한 **stdio MCP 서버** |

아래 섹션에서는 각 옵션, 구성 방법, 그리고 전송 방식 간 선택 기준을 설명합니다.

## 에이전트 수준 MCP 구성

전송 방식을 선택하는 것 외에도, `Agent.mcp_config`를 설정하여 MCP 도구 준비 방식을 조정할 수 있습니다.

```python
from agents import Agent

agent = Agent(
    name="Assistant",
    mcp_servers=[server],
    mcp_config={
        # Try to convert MCP tool schemas to strict JSON schema.
        "convert_schemas_to_strict": True,
        # If None, MCP tool failures are raised as exceptions instead of
        # returning model-visible error text.
        "failure_error_function": None,
    },
)
```

참고:

- `convert_schemas_to_strict`는 최선 노력 방식입니다. 스키마를 변환할 수 없으면 원본 스키마가 사용됩니다.
- `failure_error_function`은 MCP 도구 호출 실패가 모델에 어떻게 표시되는지 제어합니다.
- `failure_error_function`이 설정되지 않으면 SDK는 기본 도구 오류 포맷터를 사용합니다.
- 서버 수준 `failure_error_function`은 해당 서버에 대해 `Agent.mcp_config["failure_error_function"]`보다 우선합니다.

## 전송 방식 전반의 공통 패턴

전송 방식을 선택한 후 대부분의 통합에서는 동일한 후속 결정을 내려야 합니다:

- 도구 일부만 노출하는 방법([도구 필터링](#tool-filtering))
- 서버가 재사용 가능한 프롬프트도 제공하는지 여부([프롬프트](#prompts))
- `list_tools()`를 캐시해야 하는지 여부([캐싱](#caching))
- 트레이스에서 MCP 활동이 어떻게 표시되는지([트레이싱](#tracing))

로컬 MCP 서버(`MCPServerStdio`, `MCPServerSse`, `MCPServerStreamableHttp`)의 경우 승인 정책과 호출별 `_meta` 페이로드도 공통 개념입니다. Streamable HTTP 섹션에 가장 완전한 예제가 있으며, 동일한 패턴이 다른 로컬 전송 방식에도 적용됩니다.

## 1. 호스티드 MCP 서버 도구

호스티드 도구는 전체 도구 왕복 과정을 OpenAI 인프라로 넘깁니다. 코드에서 도구를 나열하고 호출하는 대신, [`HostedMCPTool`][agents.tool.HostedMCPTool]이 서버 라벨(및 선택적 커넥터 메타데이터)을 Responses API로 전달합니다. 모델은 원격 서버의 도구를 나열하고 Python 프로세스로의 추가 콜백 없이 이를 호출합니다. 현재 호스티드 도구는 Responses API의 호스티드 MCP 통합을 지원하는 OpenAI 모델에서 동작합니다.

### 기본 호스티드 MCP 도구

에이전트의 `tools` 목록에 [`HostedMCPTool`][agents.tool.HostedMCPTool]을 추가하여 호스티드 도구를 생성합니다. `tool_config` 딕셔너리는 REST API로 보내는 JSON을 그대로 반영합니다:

```python
import asyncio

from agents import Agent, HostedMCPTool, Runner

async def main() -> None:
    agent = Agent(
        name="Assistant",
        tools=[
            HostedMCPTool(
                tool_config={
                    "type": "mcp",
                    "server_label": "gitmcp",
                    "server_url": "https://gitmcp.io/openai/codex",
                    "require_approval": "never",
                }
            )
        ],
    )

    result = await Runner.run(agent, "Which language is this repository written in?")
    print(result.final_output)

asyncio.run(main())
```

호스티드 서버는 도구를 자동으로 노출하므로 `mcp_servers`에 추가할 필요가 없습니다.

### 호스티드 MCP 결과 스트리밍

호스티드 도구는 함수 도구와 정확히 동일한 방식으로 결과 스트리밍을 지원합니다. 모델이 아직 작업 중일 때 점진적 MCP 출력을 소비하려면 `Runner.run_streamed`를 사용하세요:

```python
result = Runner.run_streamed(agent, "Summarise this repository's top languages")
async for event in result.stream_events():
    if event.type == "run_item_stream_event":
        print(f"Received: {event.item}")
print(result.final_output)
```

### 선택적 승인 흐름

서버가 민감한 작업을 수행할 수 있다면 각 도구 실행 전에 사람 또는 프로그래밍 방식의 승인을 요구할 수 있습니다. `tool_config`의 `require_approval`에 단일 정책(`"always"`, `"never"`) 또는 도구 이름별 정책 딕셔너리를 설정하세요. Python 내부에서 결정을 내리려면 `on_approval_request` 콜백을 제공하세요.

```python
from agents import MCPToolApprovalFunctionResult, MCPToolApprovalRequest

SAFE_TOOLS = {"read_project_metadata"}

def approve_tool(request: MCPToolApprovalRequest) -> MCPToolApprovalFunctionResult:
    if request.data.name in SAFE_TOOLS:
        return {"approve": True}
    return {"approve": False, "reason": "Escalate to a human reviewer"}

agent = Agent(
    name="Assistant",
    tools=[
        HostedMCPTool(
            tool_config={
                "type": "mcp",
                "server_label": "gitmcp",
                "server_url": "https://gitmcp.io/openai/codex",
                "require_approval": "always",
            },
            on_approval_request=approve_tool,
        )
    ],
)
```

콜백은 동기 또는 비동기일 수 있으며, 모델이 실행을 계속하기 위해 승인 데이터가 필요할 때마다 호출됩니다.

### 커넥터 기반 호스티드 서버

호스티드 MCP는 OpenAI 커넥터도 지원합니다. `server_url` 대신 `connector_id`와 액세스 토큰을 제공하세요. Responses API가 인증을 처리하고 호스티드 서버가 커넥터의 도구를 노출합니다.

```python
import os

HostedMCPTool(
    tool_config={
        "type": "mcp",
        "server_label": "google_calendar",
        "connector_id": "connector_googlecalendar",
        "authorization": os.environ["GOOGLE_CALENDAR_AUTHORIZATION"],
        "require_approval": "never",
    }
)
```

스트리밍, 승인, 커넥터를 포함한 완전한 호스티드 도구 샘플은 [`examples/hosted_mcp`](https://github.com/openai/openai-agents-python/tree/main/examples/hosted_mcp)에 있습니다.

## 2. Streamable HTTP MCP 서버

네트워크 연결을 직접 관리하려면 [`MCPServerStreamableHttp`][agents.mcp.server.MCPServerStreamableHttp]를 사용하세요. Streamable HTTP 서버는 전송 계층을 직접 제어하거나, 자체 인프라 내에서 서버를 실행하면서 지연 시간을 낮게 유지하려는 경우에 적합합니다.

```python
import asyncio
import os

from agents import Agent, Runner
from agents.mcp import MCPServerStreamableHttp
from agents.model_settings import ModelSettings

async def main() -> None:
    token = os.environ["MCP_SERVER_TOKEN"]
    async with MCPServerStreamableHttp(
        name="Streamable HTTP Python Server",
        params={
            "url": "http://localhost:8000/mcp",
            "headers": {"Authorization": f"Bearer {token}"},
            "timeout": 10,
        },
        cache_tools_list=True,
        max_retry_attempts=3,
    ) as server:
        agent = Agent(
            name="Assistant",
            instructions="Use the MCP tools to answer the questions.",
            mcp_servers=[server],
            model_settings=ModelSettings(tool_choice="required"),
        )

        result = await Runner.run(agent, "Add 7 and 22.")
        print(result.final_output)

asyncio.run(main())
```

생성자는 다음 추가 옵션을 받습니다:

- `client_session_timeout_seconds`는 HTTP 읽기 타임아웃을 제어합니다.
- `use_structured_content`는 텍스트 출력보다 `tool_result.structured_content`를 우선할지 전환합니다.
- `max_retry_attempts` 및 `retry_backoff_seconds_base`는 `list_tools()`와 `call_tool()`에 자동 재시도를 추가합니다.
- `tool_filter`는 도구 일부만 노출하도록 설정합니다([도구 필터링](#tool-filtering) 참고).
- `require_approval`는 로컬 MCP 도구에 휴먼인더루프 (HITL) 승인 정책을 활성화합니다.
- `failure_error_function`은 모델에 표시되는 MCP 도구 실패 메시지를 사용자 지정합니다. 대신 오류를 발생시키려면 `None`으로 설정하세요.
- `tool_meta_resolver`는 `call_tool()` 전에 호출별 MCP `_meta` 페이로드를 주입합니다.

### 로컬 MCP 서버의 승인 정책

`MCPServerStdio`, `MCPServerSse`, `MCPServerStreamableHttp`는 모두 `require_approval`를 받습니다.

지원 형식:

- 모든 도구에 대해 `"always"` 또는 `"never"`
- `True` / `False`(always/never와 동일)
- 도구별 매핑(예: `{"delete_file": "always", "read_file": "never"}`)
- 그룹 객체:
  `{"always": {"tool_names": [...]}, "never": {"tool_names": [...]}}`

```python
async with MCPServerStreamableHttp(
    name="Filesystem MCP",
    params={"url": "http://localhost:8000/mcp"},
    require_approval={"always": {"tool_names": ["delete_file"]}},
) as server:
    ...
```

전체 일시 중지/재개 흐름은 [Human-in-the-loop](human_in_the_loop.md) 및 `examples/mcp/get_all_mcp_tools_example/main.py`를 참고하세요.

### `tool_meta_resolver`를 사용한 호출별 메타데이터

MCP 서버가 `_meta`에 요청 메타데이터(예: 테넌트 ID 또는 트레이스 컨텍스트)를 기대하는 경우 `tool_meta_resolver`를 사용하세요. 아래 예제는 `Runner.run(...)`에 `context`로 `dict`를 전달한다고 가정합니다.

```python
from agents.mcp import MCPServerStreamableHttp, MCPToolMetaContext


def resolve_meta(context: MCPToolMetaContext) -> dict[str, str] | None:
    run_context_data = context.run_context.context or {}
    tenant_id = run_context_data.get("tenant_id")
    if tenant_id is None:
        return None
    return {"tenant_id": str(tenant_id), "source": "agents-sdk"}


server = MCPServerStreamableHttp(
    name="Metadata-aware MCP",
    params={"url": "http://localhost:8000/mcp"},
    tool_meta_resolver=resolve_meta,
)
```

run 컨텍스트가 Pydantic 모델, dataclass 또는 사용자 정의 클래스라면 대신 속성 접근으로 테넌트 ID를 읽으세요.

### MCP 도구 출력: 텍스트 및 이미지

MCP 도구가 이미지 콘텐츠를 반환하면 SDK는 이를 이미지 도구 출력 항목으로 자동 매핑합니다. 텍스트/이미지 혼합 응답은 출력 항목 목록으로 전달되므로, 에이전트는 일반 함수 도구의 이미지 출력과 같은 방식으로 MCP 이미지 결과를 소비할 수 있습니다.

## 3. SSE 기반 HTTP MCP 서버

!!! warning

    MCP 프로젝트는 Server-Sent Events 전송 방식을 더 이상 권장하지 않습니다. 새 통합에는 Streamable HTTP 또는 stdio를 사용하고, SSE는 레거시 서버에만 유지하세요.

MCP 서버가 SSE 기반 HTTP 전송을 구현한 경우 [`MCPServerSse`][agents.mcp.server.MCPServerSse]를 인스턴스화하세요. 전송 방식만 제외하면 API는 Streamable HTTP 서버와 동일합니다.

```python

from agents import Agent, Runner
from agents.model_settings import ModelSettings
from agents.mcp import MCPServerSse

workspace_id = "demo-workspace"

async with MCPServerSse(
    name="SSE Python Server",
    params={
        "url": "http://localhost:8000/sse",
        "headers": {"X-Workspace": workspace_id},
    },
    cache_tools_list=True,
) as server:
    agent = Agent(
        name="Assistant",
        mcp_servers=[server],
        model_settings=ModelSettings(tool_choice="required"),
    )
    result = await Runner.run(agent, "What's the weather in Tokyo?")
    print(result.final_output)
```

## 4. stdio MCP 서버

로컬 하위 프로세스로 실행되는 MCP 서버에는 [`MCPServerStdio`][agents.mcp.server.MCPServerStdio]를 사용하세요. SDK는 프로세스를 생성하고 파이프를 열어 둔 상태로 유지하며, 컨텍스트 매니저가 종료될 때 자동으로 닫습니다. 이 옵션은 빠른 개념 검증이나 서버가 명령줄 엔트리 포인트만 제공하는 경우에 유용합니다.

```python
from pathlib import Path
from agents import Agent, Runner
from agents.mcp import MCPServerStdio

current_dir = Path(__file__).parent
samples_dir = current_dir / "sample_files"

async with MCPServerStdio(
    name="Filesystem Server via npx",
    params={
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-filesystem", str(samples_dir)],
    },
) as server:
    agent = Agent(
        name="Assistant",
        instructions="Use the files in the sample directory to answer questions.",
        mcp_servers=[server],
    )
    result = await Runner.run(agent, "List the files available to you.")
    print(result.final_output)
```

## 5. MCP 서버 관리자

여러 MCP 서버가 있는 경우 `MCPServerManager`를 사용해 미리 연결하고, 연결된 하위 집합을 에이전트에 노출하세요. 생성자 옵션과 재연결 동작은 [MCPServerManager API reference](ref/mcp/manager.md)를 참고하세요.

```python
from agents import Agent, Runner
from agents.mcp import MCPServerManager, MCPServerStreamableHttp

servers = [
    MCPServerStreamableHttp(name="calendar", params={"url": "http://localhost:8000/mcp"}),
    MCPServerStreamableHttp(name="docs", params={"url": "http://localhost:8001/mcp"}),
]

async with MCPServerManager(servers) as manager:
    agent = Agent(
        name="Assistant",
        instructions="Use MCP tools when they help.",
        mcp_servers=manager.active_servers,
    )
    result = await Runner.run(agent, "Which MCP tools are available?")
    print(result.final_output)
```

핵심 동작:

- `drop_failed_servers=True`(기본값)일 때 `active_servers`에는 연결에 성공한 서버만 포함됩니다.
- 실패는 `failed_servers`와 `errors`에 추적됩니다.
- 첫 연결 실패에서 예외를 발생시키려면 `strict=True`를 설정하세요.
- 실패한 서버를 재시도하려면 `reconnect(failed_only=True)`, 모든 서버를 재시작하려면 `reconnect(failed_only=False)`를 호출하세요.
- 라이프사이클 동작 조정을 위해 `connect_timeout_seconds`, `cleanup_timeout_seconds`, `connect_in_parallel`을 사용하세요.

## 공통 서버 기능

아래 섹션은 MCP 서버 전송 방식 전반에 적용됩니다(정확한 API 표면은 서버 클래스에 따라 다름).

## 도구 필터링

각 MCP 서버는 도구 필터를 지원하므로, 에이전트에 필요한 함수만 노출할 수 있습니다. 필터링은 생성 시점 또는 run별 동적으로 수행할 수 있습니다.

### 정적 도구 필터링

단순 허용/차단 목록을 구성하려면 [`create_static_tool_filter`][agents.mcp.create_static_tool_filter]를 사용하세요:

```python
from pathlib import Path

from agents.mcp import MCPServerStdio, create_static_tool_filter

samples_dir = Path("/path/to/files")

filesystem_server = MCPServerStdio(
    params={
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-filesystem", str(samples_dir)],
    },
    tool_filter=create_static_tool_filter(allowed_tool_names=["read_file", "write_file"]),
)
```

`allowed_tool_names`와 `blocked_tool_names`가 모두 제공되면 SDK는 먼저 허용 목록을 적용한 뒤 남은 집합에서 차단 도구를 제거합니다.

### 동적 도구 필터링

더 정교한 로직에는 [`ToolFilterContext`][agents.mcp.ToolFilterContext]를 받는 호출 가능 객체를 전달하세요. 이 객체는 동기 또는 비동기일 수 있으며, 도구를 노출해야 하면 `True`를 반환합니다.

```python
from pathlib import Path

from agents.mcp import MCPServerStdio, ToolFilterContext

samples_dir = Path("/path/to/files")

async def context_aware_filter(context: ToolFilterContext, tool) -> bool:
    if context.agent.name == "Code Reviewer" and tool.name.startswith("danger_"):
        return False
    return True

async with MCPServerStdio(
    params={
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-filesystem", str(samples_dir)],
    },
    tool_filter=context_aware_filter,
) as server:
    ...
```

필터 컨텍스트는 활성 `run_context`, 도구를 요청하는 `agent`, 그리고 `server_name`을 제공합니다.

## 프롬프트

MCP 서버는 에이전트 instructions를 동적으로 생성하는 프롬프트도 제공할 수 있습니다. 프롬프트를 지원하는 서버는 두 가지 메서드를 노출합니다:

- `list_prompts()`는 사용 가능한 프롬프트 템플릿을 열거합니다.
- `get_prompt(name, arguments)`는 선택적으로 매개변수를 사용해 구체적인 프롬프트를 가져옵니다.

```python
from agents import Agent

prompt_result = await server.get_prompt(
    "generate_code_review_instructions",
    {"focus": "security vulnerabilities", "language": "python"},
)
instructions = prompt_result.messages[0].content.text

agent = Agent(
    name="Code Reviewer",
    instructions=instructions,
    mcp_servers=[server],
)
```

## 캐싱

모든 에이전트 run은 각 MCP 서버에서 `list_tools()`를 호출합니다. 원격 서버는 눈에 띄는 지연을 유발할 수 있으므로, 모든 MCP 서버 클래스는 `cache_tools_list` 옵션을 제공합니다. 도구 정의가 자주 변경되지 않는다고 확신할 때만 `True`로 설정하세요. 이후 새 목록을 강제로 가져오려면 서버 인스턴스에서 `invalidate_tools_cache()`를 호출하세요.

## 트레이싱

[트레이싱](./tracing.md)은 다음을 포함한 MCP 활동을 자동으로 수집합니다:

1. 도구 목록 조회를 위한 MCP 서버 호출
2. 도구 호출의 MCP 관련 정보

![MCP Tracing Screenshot](../assets/images/mcp-tracing.jpg)

## 추가 읽을거리

- [Model Context Protocol](https://modelcontextprotocol.io/) – 사양 및 설계 가이드
- [examples/mcp](https://github.com/openai/openai-agents-python/tree/main/examples/mcp) – 실행 가능한 stdio, SSE, Streamable HTTP 샘플
- [examples/hosted_mcp](https://github.com/openai/openai-agents-python/tree/main/examples/hosted_mcp) – 승인 및 커넥터를 포함한 완전한 호스티드 MCP 데모

================
File: docs/ko/multi_agent.md
================
---
search:
  exclude: true
---
# 에이전트 오케스트레이션

오케스트레이션은 앱에서 에이전트의 흐름을 의미합니다. 어떤 에이전트가 실행되고, 어떤 순서로 실행되며, 다음에 무엇이 일어날지를 어떻게 결정할까요? 에이전트를 오케스트레이션하는 주요 방법은 두 가지입니다

1. LLM이 의사결정을 하도록 허용: LLM의 지능을 활용해 계획하고, 추론하고, 이를 바탕으로 어떤 단계를 수행할지 결정합니다
2. 코드를 통한 오케스트레이션: 코드로 에이전트의 흐름을 결정합니다

이 패턴들은 함께 조합해 사용할 수 있습니다. 각각에는 아래에 설명된 고유한 트레이드오프가 있습니다

## LLM을 통한 오케스트레이션

에이전트는 instructions, tools, handoffs를 갖춘 LLM입니다. 즉, 개방형 작업이 주어지면 LLM은 도구를 사용해 행동을 수행하고 데이터를 수집하며, 핸드오프를 사용해 하위 에이전트에 작업을 위임하면서 작업을 어떻게 해결할지 자율적으로 계획할 수 있습니다. 예를 들어, 리서치 에이전트에는 다음과 같은 도구를 갖출 수 있습니다

-   온라인 정보를 찾기 위한 웹 검색
-   독점 데이터와 연결을 검색하기 위한 파일 검색 및 검색 결과 가져오기
-   컴퓨터에서 작업을 수행하기 위한 컴퓨터 사용
-   데이터 분석을 수행하기 위한 코드 실행
-   계획 수립, 보고서 작성 등에 뛰어난 전문 에이전트로의 핸드오프

### 핵심 SDK 패턴

Python SDK에서는 두 가지 오케스트레이션 패턴이 가장 자주 사용됩니다

| 패턴 | 작동 방식 | 적합한 경우 |
| --- | --- | --- |
| Agents as tools | 관리자 에이전트가 대화의 제어권을 유지하고 `Agent.as_tool()`을 통해 전문 에이전트를 호출합니다 | 하나의 에이전트가 최종 답변을 책임지고, 여러 전문 에이전트의 출력을 결합하거나, 공통 가드레일을 한곳에서 적용하고 싶을 때 |
| 핸드오프 | 트리아지 에이전트가 대화를 전문 에이전트로 라우팅하고, 해당 전문 에이전트가 해당 턴의 나머지 동안 활성 에이전트가 됩니다 | 전문 에이전트가 직접 응답하고, 프롬프트를 집중되게 유지하거나, 관리자가 결과를 설명하지 않고 instructions를 전환하고 싶을 때 |

전문 에이전트가 제한된 하위 작업을 돕되 사용자 대상 대화를 넘겨받지 않아야 한다면 **agents as tools**를 사용하세요. 라우팅 자체가 워크플로의 일부이고 선택된 전문 에이전트가 다음 상호작용 구간을 맡아야 한다면 **handoffs**를 사용하세요

두 가지를 결합할 수도 있습니다. 트리아지 에이전트가 전문 에이전트로 핸드오프한 뒤에도, 해당 전문 에이전트는 좁은 하위 작업을 위해 다른 에이전트를 도구로 호출할 수 있습니다

이 패턴은 작업이 개방형이고 LLM의 지능에 의존하고 싶을 때 매우 유용합니다. 여기서 가장 중요한 전술은 다음과 같습니다

1. 좋은 프롬프트에 투자하세요. 사용 가능한 도구, 사용 방법, 그리고 반드시 지켜야 하는 매개변수 범위를 명확히 하세요
2. 앱을 모니터링하고 반복 개선하세요. 문제가 발생하는 지점을 확인하고 프롬프트를 반복 개선하세요
3. 에이전트가 스스로 점검하고 개선하도록 하세요. 예를 들어 루프로 실행하고 자기 비평을 하게 하거나, 오류 메시지를 제공해 개선하게 하세요
4. 어떤 작업이든 잘해야 하는 범용 에이전트 하나보다, 단일 작업에 뛰어난 전문 에이전트를 두세요
5. [evals](https://platform.openai.com/docs/guides/evals)에 투자하세요. 이를 통해 에이전트를 훈련해 작업 수행 능력을 개선하고 향상시킬 수 있습니다

이 스타일의 오케스트레이션을 뒷받침하는 핵심 SDK 기본 구성 요소를 원한다면 [tools](tools.md), [handoffs](handoffs.md), [running agents](running_agents.md)부터 시작하세요

## 코드를 통한 오케스트레이션

LLM을 통한 오케스트레이션은 강력하지만, 코드를 통한 오케스트레이션은 속도, 비용, 성능 측면에서 작업을 더 결정론적이고 예측 가능하게 만듭니다. 여기서의 일반적인 패턴은 다음과 같습니다

-   [structured outputs](https://platform.openai.com/docs/guides/structured-outputs)를 사용해 코드로 검사할 수 있는 적절한 형식의 데이터를 생성하기. 예를 들어 에이전트에게 작업을 몇 가지 카테고리로 분류하게 한 다음, 카테고리에 따라 다음 에이전트를 선택할 수 있습니다
-   한 에이전트의 출력을 다음 에이전트의 입력으로 변환해 여러 에이전트를 체이닝하기. 블로그 글 작성 같은 작업을 리서치, 개요 작성, 본문 작성, 비평, 개선 같은 일련의 단계로 분해할 수 있습니다
-   작업을 수행하는 에이전트를 평가 및 피드백을 제공하는 에이전트와 함께 `while` 루프로 실행하고, 평가자가 출력이 특정 기준을 통과한다고 말할 때까지 반복하기
-   여러 에이전트를 병렬로 실행하기(예: `asyncio.gather` 같은 Python 기본 구성 요소 사용). 서로 의존하지 않는 여러 작업이 있을 때 속도 측면에서 유용합니다

[`examples/agent_patterns`](https://github.com/openai/openai-agents-python/tree/main/examples/agent_patterns)에 다양한 예제가 있습니다

## 관련 가이드

-   구성 패턴과 에이전트 설정은 [Agents](agents.md)를 참고하세요
-   `Agent.as_tool()` 및 관리자 스타일 오케스트레이션은 [Tools](tools.md#agents-as-tools)를 참고하세요
-   전문 에이전트 간 위임은 [Handoffs](handoffs.md)를 참고하세요
-   실행별 오케스트레이션 제어 및 대화 상태는 [Running agents](running_agents.md)를 참고하세요
-   최소한의 엔드투엔드 핸드오프 예제는 [Quickstart](quickstart.md)를 참고하세요

================
File: docs/ko/quickstart.md
================
---
search:
  exclude: true
---
# 빠른 시작

## 프로젝트 및 가상 환경 생성

이 작업은 한 번만 하면 됩니다

```bash
mkdir my_project
cd my_project
python -m venv .venv
```

### 가상 환경 활성화

새 터미널 세션을 시작할 때마다 이 작업을 수행하세요

```bash
source .venv/bin/activate
```

### Agents SDK 설치

```bash
pip install openai-agents # or `uv add openai-agents`, etc
```

### OpenAI API 키 설정

아직 키가 없다면 [이 지침](https://platform.openai.com/docs/quickstart#create-and-export-an-api-key)을 따라 OpenAI API 키를 생성하세요

```bash
export OPENAI_API_KEY=sk-...
```

## 첫 에이전트 생성

에이전트는 instructions, 이름, 그리고 특정 모델 같은 선택적 구성으로 정의됩니다

```python
from agents import Agent

agent = Agent(
    name="History Tutor",
    instructions="You answer history questions clearly and concisely.",
)
```

## 첫 에이전트 실행

[`Runner`][agents.run.Runner]를 사용해 에이전트를 실행하고 [`RunResult`][agents.result.RunResult]를 반환받으세요

```python
import asyncio
from agents import Agent, Runner

agent = Agent(
    name="History Tutor",
    instructions="You answer history questions clearly and concisely.",
)

async def main():
    result = await Runner.run(agent, "When did the Roman Empire fall?")
    print(result.final_output)

if __name__ == "__main__":
    asyncio.run(main())
```

두 번째 턴에서는 `result.to_input_list()`를 `Runner.run(...)`에 다시 전달하거나, [session](sessions/index.md)을 연결하거나, `conversation_id` / `previous_response_id`로 OpenAI 서버 관리 상태를 재사용할 수 있습니다. [에이전트 실행](running_agents.md) 가이드에서 이러한 접근 방식을 비교합니다

이 경험칙을 사용하세요:

| 원한다면... | 시작 방법... |
| --- | --- |
| 완전한 수동 제어와 provider-agnostic 기록 | `result.to_input_list()` |
| SDK가 기록을 대신 불러오고 저장하기를 원함 | [`session=...`](sessions/index.md) |
| OpenAI 관리 서버 측 이어서 실행 | `previous_response_id` 또는 `conversation_id` |

트레이드오프와 정확한 동작은 [에이전트 실행](running_agents.md#choose-a-memory-strategy)을 참고하세요

## 에이전트에 도구 제공

에이전트에 정보를 조회하거나 작업을 수행할 수 있는 도구를 제공할 수 있습니다

```python
import asyncio
from agents import Agent, Runner, function_tool


@function_tool
def history_fun_fact() -> str:
    """Return a short history fact."""
    return "Sharks are older than trees."


agent = Agent(
    name="History Tutor",
    instructions="Answer history questions clearly. Use history_fun_fact when it helps.",
    tools=[history_fun_fact],
)


async def main():
    result = await Runner.run(
        agent,
        "Tell me something surprising about ancient life on Earth.",
    )
    print(result.final_output)


if __name__ == "__main__":
    asyncio.run(main())
```

## 에이전트 몇 개 더 추가

멀티 에이전트 패턴을 선택하기 전에, 최종 답변을 누가 담당할지 결정하세요:

-   **핸드오프**: 해당 턴의 그 부분에서는 전문 에이전트가 대화를 이어받습니다
-   **Agents as tools**: 오케스트레이터가 제어를 유지하고 전문 에이전트를 도구로 호출합니다

이 빠른 시작은 가장 짧은 첫 예제이므로 **핸드오프**를 계속 사용합니다. 매니저 스타일 패턴은 [에이전트 오케스트레이션](multi_agent.md) 및 [도구: Agents as tools](tools.md#agents-as-tools)을 참고하세요

추가 에이전트도 같은 방식으로 정의할 수 있습니다. `handoff_description`은 라우팅 에이전트에 언제 위임할지에 대한 추가 컨텍스트를 제공합니다

```python
from agents import Agent

history_tutor_agent = Agent(
    name="History Tutor",
    handoff_description="Specialist agent for historical questions",
    instructions="You answer history questions clearly and concisely.",
)

math_tutor_agent = Agent(
    name="Math Tutor",
    handoff_description="Specialist agent for math questions",
    instructions="You explain math step by step and include worked examples.",
)
```

## 핸드오프 정의

에이전트에서 작업 해결 중 선택할 수 있는 외부 핸드오프 옵션 목록을 정의할 수 있습니다

```python
triage_agent = Agent(
    name="Triage Agent",
    instructions="Route each homework question to the right specialist.",
    handoffs=[history_tutor_agent, math_tutor_agent],
)
```

## 에이전트 오케스트레이션 실행

러너는 개별 에이전트 실행, 핸드오프, 도구 호출을 모두 처리합니다

```python
import asyncio
from agents import Runner


async def main():
    result = await Runner.run(
        triage_agent,
        "Who was the first president of the United States?",
    )
    print(result.final_output)
    print(f"Answered by: {result.last_agent.name}")


if __name__ == "__main__":
    asyncio.run(main())
```

## 참고 코드 예제

리포지토리에는 동일한 핵심 패턴에 대한 전체 스크립트가 포함되어 있습니다:

-   첫 실행용 [`examples/basic/hello_world.py`](https://github.com/openai/openai-agents-python/tree/main/examples/basic/hello_world.py)
-   함수 도구용 [`examples/basic/tools.py`](https://github.com/openai/openai-agents-python/tree/main/examples/basic/tools.py)
-   멀티 에이전트 라우팅용 [`examples/agent_patterns/routing.py`](https://github.com/openai/openai-agents-python/tree/main/examples/agent_patterns/routing.py)

## 트레이스 확인

에이전트 실행 중 무엇이 발생했는지 검토하려면 [OpenAI Dashboard의 Trace viewer](https://platform.openai.com/traces)로 이동해 에이전트 실행의 트레이스를 확인하세요

## 다음 단계

더 복잡한 에이전트 흐름을 구축하는 방법을 알아보세요:

-   [Agents](agents.md) 구성 방법 알아보기
-   [에이전트 실행](running_agents.md) 및 [sessions](sessions/index.md) 알아보기
-   [도구](tools.md), [가드레일](guardrails.md), [모델](models/index.md) 알아보기

================
File: docs/ko/release.md
================
---
search:
  exclude: true
---
# 릴리스 프로세스/변경 로그

이 프로젝트는 `0.Y.Z` 형식을 사용하는, 약간 수정된 시맨틱 버저닝을 따릅니다. 앞의 `0`은 SDK가 아직 빠르게 발전 중임을 의미합니다. 구성 요소 증가는 다음과 같습니다.

## 마이너(`Y`) 버전

베타로 표시되지 않은 모든 공개 인터페이스에 대한 **호환성이 깨지는 변경(breaking change)** 이 있을 때 마이너 버전 `Y`를 올립니다. 예를 들어 `0.0.x`에서 `0.1.x`로 가는 경우에는 호환성이 깨지는 변경이 포함될 수 있습니다.

호환성이 깨지는 변경을 원하지 않는다면, 프로젝트에서 `0.0.x` 버전에 고정(pin)하는 것을 권장합니다.

## 패치(`Z`) 버전

호환성이 깨지지 않는 변경에 대해 `Z`를 올립니다.

-   버그 수정
-   새 기능
-   비공개 인터페이스 변경
-   베타 기능 업데이트

## 호환성이 깨지는 변경 변경 로그

### 0.10.0

이 마이너 릴리스는 호환성이 깨지는 변경을 **도입하지 않지만**, OpenAI Responses 사용자를 위한 중요한 새 기능 영역을 포함합니다. 즉, Responses API에 대한 websocket 전송 지원입니다.

주요 내용:

-   OpenAI Responses 모델에 대한 websocket 전송 지원을 추가했습니다(선택 사항; HTTP는 기본 전송 방식으로 유지)
-   멀티 턴 실행 전반에서 websocket 사용 가능한 provider와 `RunConfig`를 공유해 재사용할 수 있도록 `responses_websocket_session()` 헬퍼 / `ResponsesWebSocketSession`을 추가했습니다
-   스트리밍, 도구, 승인, 후속 턴을 다루는 새로운 websocket 스트리밍 예제(`examples/basic/stream_ws.py`)를 추가했습니다

### 0.9.0

이 버전부터 Python 3.9는 더 이상 지원되지 않습니다. 이 메이저 버전은 3개월 전에 EOL에 도달했습니다. 더 최신 런타임 버전으로 업그레이드해 주세요.

또한 `Agent#as_tool()` 메서드가 반환하는 값의 타입 힌트가 `Tool`에서 `FunctionTool`로 좁혀졌습니다. 이 변경은 일반적으로 호환성 문제를 일으키지 않지만, 코드가 더 넓은 유니온 타입에 의존하고 있다면 일부 조정이 필요할 수 있습니다.

### 0.8.0

이 버전에서는 두 가지 런타임 동작 변경으로 인해 마이그레이션 작업이 필요할 수 있습니다.

- **동기식(synchronous)** Python 호출 가능 객체(callable)를 래핑하는 함수 도구는 이제 이벤트 루프 스레드에서 실행하는 대신 `asyncio.to_thread(...)`를 통해 워커 스레드에서 실행됩니다. 도구 로직이 스레드 로컬 상태나 스레드에 종속적인 리소스에 의존한다면, async 도구 구현으로 마이그레이션하거나 도구 코드에서 스레드 종속성을 명시적으로 처리하세요
- 로컬 MCP 도구 실패 처리 방식이 이제 구성 가능해졌으며, 기본 동작은 전체 실행을 실패시키는 대신 모델에 보이는 오류 출력(model-visible error output)을 반환할 수 있습니다. fail-fast 의미론에 의존한다면 `mcp_config={"failure_error_function": None}`을 설정하세요. 서버 레벨의 `failure_error_function` 값은 에이전트 레벨 설정을 덮어쓰므로, 명시적 핸들러가 있는 각 로컬 MCP 서버마다 `failure_error_function=None`을 설정하세요

### 0.7.0

이 버전에서는 기존 애플리케이션에 영향을 줄 수 있는 몇 가지 동작 변경이 있었습니다.

- 중첩된 핸드오프 기록은 이제 **opt-in**입니다(기본적으로 비활성화). v0.6.x의 기본 중첩 동작에 의존했다면 `RunConfig(nest_handoff_history=True)`를 명시적으로 설정하세요
- `gpt-5.1` / `gpt-5.2`의 기본 `reasoning.effort`가 SDK 기본값으로 설정되던 이전 기본값 `"low"`에서 `"none"`으로 변경되었습니다. 프롬프트나 품질/비용 프로파일이 `"low"`에 의존했다면 `model_settings`에서 명시적으로 설정하세요

### 0.6.0

이 버전부터 기본 핸드오프 기록은 원문 사용자/어시스턴트 턴을 노출하는 대신 하나의 assistant 메시지로 패키징되어, 다운스트림 에이전트가 간결하고 예측 가능한 요약을 받습니다
- 기존의 단일 메시지 핸드오프 대화 기록은 이제 기본적으로 `<CONVERSATION HISTORY>` 블록 앞에 "For context, here is the conversation so far between the user and the previous agent:"로 시작하므로, 다운스트림 에이전트가 명확하게 라벨된 요약을 받습니다

### 0.5.0

이 버전은 눈에 띄는 호환성이 깨지는 변경을 도입하지 않지만, 새 기능과 내부적으로 몇 가지 중요한 업데이트를 포함합니다.

-   `RealtimeRunner`가 [SIP 프로토콜 연결](https://platform.openai.com/docs/guides/realtime-sip)을 처리할 수 있도록 지원을 추가했습니다
-   Python 3.14 호환성을 위해 `Runner#run_sync`의 내부 로직을 크게 개정했습니다

### 0.4.0

이 버전부터 [openai](https://pypi.org/project/openai/) 패키지 v1.x 버전은 더 이상 지원되지 않습니다. 이 SDK와 함께 openai v2.x를 사용해 주세요.

### 0.3.0

이 버전에서 Realtime API 지원은 gpt-realtime 모델과 해당 API 인터페이스(GA 버전)로 마이그레이션됩니다.

### 0.2.0

이 버전에서는 이전에 인자(arg)로 `Agent`를 받던 몇몇 위치가 이제 대신 `AgentBase`를 받습니다. 예를 들어 MCP 서버의 `list_tools()` 호출이 그렇습니다. 이는 순수하게 타이핑 변경이며, 여전히 `Agent` 객체를 받게 됩니다. 업데이트하려면 `Agent`를 `AgentBase`로 바꿔 타입 오류만 수정하면 됩니다.

### 0.1.0

이 버전에서 [`MCPServer.list_tools()`][agents.mcp.server.MCPServer]에 `run_context`와 `agent`라는 두 개의 새 매개변수가 추가되었습니다. `MCPServer`를 서브클래싱하는 모든 클래스에 이 매개변수들을 추가해야 합니다.

================
File: docs/ko/repl.md
================
---
search:
  exclude: true
---
# REPL 유틸리티

SDK는 터미널에서 에이전트의 동작을 빠르고 대화형으로 테스트할 수 있도록 `run_demo_loop`를 제공합니다.

```python
import asyncio
from agents import Agent, run_demo_loop

async def main() -> None:
    agent = Agent(name="Assistant", instructions="You are a helpful assistant.")
    await run_demo_loop(agent)

if __name__ == "__main__":
    asyncio.run(main())
```

`run_demo_loop`는 루프에서 사용자 입력을 요청하고, 턴 간 대화 기록을 유지합니다. 기본적으로 모델 출력이 생성되는 대로 스트리밍합니다. 위 예제를 실행하면 run_demo_loop가 대화형 채팅 세션을 시작합니다. 계속해서 입력을 요청하고, 턴 간 전체 대화 기록을 기억하여(에이전트가 어떤 내용이 논의되었는지 알 수 있도록) 생성되는 즉시 에이전트의 응답을 실시간으로 자동 스트리밍합니다.

이 채팅 세션을 종료하려면 `quit` 또는 `exit`를 입력하고 Enter 키를 누르거나 `Ctrl-D` 키보드 단축키를 사용하세요.

================
File: docs/ko/results.md
================
---
search:
  exclude: true
---
# 결과

`Runner.run` 메서드를 호출하면 두 가지 결과 타입 중 하나를 받습니다:

-   `Runner.run(...)` 또는 `Runner.run_sync(...)`의 [`RunResult`][agents.result.RunResult]
-   `Runner.run_streamed(...)`의 [`RunResultStreaming`][agents.result.RunResultStreaming]

두 타입 모두 [`RunResultBase`][agents.result.RunResultBase]를 상속하며, `final_output`, `new_items`, `last_agent`, `raw_responses`, `to_state()` 같은 공통 결과 표면을 제공합니다.

`RunResultStreaming`은 [`stream_events()`][agents.result.RunResultStreaming.stream_events], [`current_agent`][agents.result.RunResultStreaming.current_agent], [`is_complete`][agents.result.RunResultStreaming.is_complete], [`cancel(...)`][agents.result.RunResultStreaming.cancel] 같은 스트리밍 전용 제어 기능을 추가로 제공합니다.

## 적절한 결과 표면 선택

대부분의 애플리케이션은 몇 가지 결과 속성이나 헬퍼만 필요합니다:

| 다음이 필요하다면... | 사용 |
| --- | --- |
| 사용자에게 보여줄 최종 답변 | `final_output` |
| 전체 로컬 전사 기록이 포함된 재생 가능한 다음 턴 입력 목록 | `to_input_list()` |
| 에이전트, 도구, 핸드오프, 승인 메타데이터가 포함된 풍부한 실행 항목 | `new_items` |
| 일반적으로 다음 사용자 턴을 처리해야 하는 에이전트 | `last_agent` |
| `previous_response_id`를 사용하는 OpenAI Responses API 체이닝 | `last_response_id` |
| 보류 중인 승인 및 재개 가능한 스냅샷 | `interruptions` 및 `to_state()` |
| 현재 중첩된 `Agent.as_tool()` 호출에 대한 메타데이터 | `agent_tool_invocation` |
| 원문 모델 호출 또는 가드레일 진단 | `raw_responses` 및 가드레일 결과 배열 |

## 최종 출력

[`final_output`][agents.result.RunResultBase.final_output] 속성에는 마지막으로 실행된 에이전트의 최종 출력이 들어 있습니다. 이는 다음 중 하나입니다:

-   마지막 에이전트에 `output_type`이 정의되지 않은 경우 `str`
-   마지막 에이전트에 출력 타입이 정의된 경우 `last_agent.output_type` 타입의 객체
-   최종 출력이 생성되기 전에 실행이 중단된 경우 `None`(예: 승인 인터럽션에서 일시 중지된 경우)

!!! note

    `final_output`의 타입은 `Any`입니다. 핸드오프로 인해 어떤 에이전트가 실행을 완료할지 바뀔 수 있으므로, SDK는 가능한 출력 타입 전체를 정적으로 알 수 없습니다.

스트리밍 모드에서는 스트림 처리가 완료될 때까지 `final_output`이 `None`으로 유지됩니다. 이벤트별 흐름은 [Streaming](streaming.md)을 참고하세요.

## 입력, 다음 턴 기록, 새 항목

이 표면들은 서로 다른 질문에 답합니다:

| 속성 또는 헬퍼 | 포함 내용 | 최적 용도 |
| --- | --- | --- |
| [`input`][agents.result.RunResultBase.input] | 이 실행 구간의 기본 입력. 핸드오프 입력 필터가 기록을 다시 쓴 경우, 실행이 이어진 필터링된 입력을 반영합니다 | 이 실행이 실제로 어떤 입력을 사용했는지 감사 |
| [`to_input_list()`][agents.result.RunResultBase.to_input_list] | `input`과 이 실행의 변환된 `new_items`로 구성된 재생 가능한 다음 턴 입력 목록 | 수동 채팅 루프 및 클라이언트 관리 대화 상태 |
| [`new_items`][agents.result.RunResultBase.new_items] | 에이전트, 도구, 핸드오프, 승인 메타데이터가 포함된 풍부한 [`RunItem`][agents.items.RunItem] 래퍼 | 로그, UI, 감사, 디버깅 |
| [`raw_responses`][agents.result.RunResultBase.raw_responses] | 실행 중 각 모델 호출에서 수집된 원문 [`ModelResponse`][agents.items.ModelResponse] 객체 | 제공자 수준 진단 또는 원문 응답 검사 |

실무에서는:

-   애플리케이션이 전체 대화 전사 기록을 수동으로 유지한다면 `to_input_list()`를 사용하세요
-   SDK가 기록을 로드/저장하게 하려면 [`session=...`](sessions/index.md)을 사용하세요
-   `conversation_id` 또는 `previous_response_id`로 OpenAI 서버 관리 상태를 사용 중이라면, 보통은 `to_input_list()`를 다시 보내기보다 새 사용자 입력만 전달하고 저장된 ID를 재사용하세요

JavaScript SDK와 달리 Python은 모델 형태의 델타만 담은 별도 `output` 속성을 제공하지 않습니다. SDK 메타데이터가 필요하면 `new_items`를 사용하고, 원문 모델 페이로드가 필요하면 `raw_responses`를 확인하세요.

### 새 항목

[`new_items`][agents.result.RunResultBase.new_items]는 실행 중 발생한 일을 가장 풍부하게 보여줍니다. 일반적인 항목 타입은 다음과 같습니다:

-   어시스턴트 메시지용 [`MessageOutputItem`][agents.items.MessageOutputItem]
-   추론 항목용 [`ReasoningItem`][agents.items.ReasoningItem]
-   도구 호출 및 결과용 [`ToolCallItem`][agents.items.ToolCallItem] 및 [`ToolCallOutputItem`][agents.items.ToolCallOutputItem]
-   승인을 위해 일시 중지된 도구 호출용 [`ToolApprovalItem`][agents.items.ToolApprovalItem]
-   핸드오프 요청 및 완료된 이관용 [`HandoffCallItem`][agents.items.HandoffCallItem] 및 [`HandoffOutputItem`][agents.items.HandoffOutputItem]

에이전트 연관 정보, 도구 출력, 핸드오프 경계, 승인 경계가 필요하다면 `to_input_list()`보다 `new_items`를 선택하세요.

## 대화 계속 또는 재개

### 다음 턴 에이전트

[`last_agent`][agents.result.RunResultBase.last_agent]에는 마지막으로 실행된 에이전트가 들어 있습니다. 핸드오프 이후 다음 사용자 턴에 재사용할 최적의 에이전트인 경우가 많습니다.

스트리밍 모드에서는 실행이 진행됨에 따라 [`RunResultStreaming.current_agent`][agents.result.RunResultStreaming.current_agent]가 업데이트되므로, 스트림이 끝나기 전에 핸드오프를 관찰할 수 있습니다.

### 인터럽션 및 실행 상태

도구에 승인이 필요하면 보류 중 승인 항목이 [`RunResult.interruptions`][agents.result.RunResult.interruptions] 또는 [`RunResultStreaming.interruptions`][agents.result.RunResultStreaming.interruptions]에 노출됩니다. 여기에는 직접 도구에서 발생한 승인, 핸드오프 이후 도달한 도구에서 발생한 승인, 중첩된 [`Agent.as_tool()`][agents.agent.Agent.as_tool] 실행에서 발생한 승인이 포함될 수 있습니다.

[`to_state()`][agents.result.RunResult.to_state]를 호출해 재개 가능한 [`RunState`][agents.run_state.RunState]를 캡처하고, 보류 항목을 승인 또는 거부한 뒤 `Runner.run(...)` 또는 `Runner.run_streamed(...)`로 재개하세요.

```python
from agents import Agent, Runner

agent = Agent(name="Assistant", instructions="Use tools when needed.")
result = await Runner.run(agent, "Delete temp files that are no longer needed.")

if result.interruptions:
    state = result.to_state()
    for interruption in result.interruptions:
        state.approve(interruption)
    result = await Runner.run(agent, state)
```

스트리밍 실행의 경우 먼저 [`stream_events()`][agents.result.RunResultStreaming.stream_events] 소비를 완료한 다음 `result.interruptions`를 확인하고 `result.to_state()`에서 재개하세요. 전체 승인 흐름은 [Human-in-the-loop](human_in_the_loop.md)를 참고하세요.

### 서버 관리 연속 실행

[`last_response_id`][agents.result.RunResultBase.last_response_id]는 실행의 최신 모델 응답 ID입니다. OpenAI Responses API 체인을 이어가려면 다음 턴에서 이를 `previous_response_id`로 다시 전달하세요.

이미 `to_input_list()`, `session`, 또는 `conversation_id`로 대화를 이어가고 있다면 보통 `last_response_id`는 필요하지 않습니다. 다단계 실행의 모든 모델 응답이 필요하면 대신 `raw_responses`를 확인하세요.

## Agent-as-tool 메타데이터

결과가 중첩된 [`Agent.as_tool()`][agents.agent.Agent.as_tool] 실행에서 나온 경우, [`agent_tool_invocation`][agents.result.RunResultBase.agent_tool_invocation]은 외부 도구 호출에 대한 불변 메타데이터를 제공합니다:

-   `tool_name`
-   `tool_call_id`
-   `tool_arguments`

일반적인 최상위 실행에서는 `agent_tool_invocation`이 `None`입니다.

이는 특히 `custom_output_extractor` 내부에서 유용하며, 중첩 결과를 후처리할 때 외부 도구 이름, 호출 ID, 원문 인자가 필요할 수 있습니다. 주변 `Agent.as_tool()` 패턴은 [Tools](tools.md)를 참고하세요.

해당 중첩 실행의 파싱된 구조화 입력도 필요하다면 `context_wrapper.tool_input`을 읽으세요. 이 필드는 중첩 도구 입력에 대해 [`RunState`][agents.run_state.RunState]가 일반적으로 직렬화하는 필드이며, `agent_tool_invocation`은 현재 중첩 호출에 대한 라이브 결과 접근자입니다.

## 스트리밍 수명 주기 및 진단

[`RunResultStreaming`][agents.result.RunResultStreaming]은 위와 동일한 결과 표면을 상속하면서, 스트리밍 전용 제어 기능을 추가합니다:

-   의미론적 스트림 이벤트를 소비하는 [`stream_events()`][agents.result.RunResultStreaming.stream_events]
-   실행 중 활성 에이전트를 추적하는 [`current_agent`][agents.result.RunResultStreaming.current_agent]
-   스트리밍 실행이 완전히 끝났는지 확인하는 [`is_complete`][agents.result.RunResultStreaming.is_complete]
-   실행을 즉시 또는 현재 턴 이후에 중단하는 [`cancel(...)`][agents.result.RunResultStreaming.cancel]

비동기 이터레이터가 끝날 때까지 `stream_events()`를 계속 소비하세요. 스트리밍 실행은 해당 이터레이터가 종료되어야 완료되며, 마지막으로 보이는 토큰이 도착한 뒤에도 `final_output`, `interruptions`, `raw_responses`, 세션 영속화 부작용 같은 요약 속성이 아직 정리 중일 수 있습니다.

`cancel()`을 호출한 경우에도 취소 및 정리가 올바르게 완료되도록 `stream_events()` 소비를 계속하세요.

Python은 별도의 스트리밍 `completed` 프로미스나 `error` 속성을 제공하지 않습니다. 최종 스트리밍 실패는 `stream_events()`에서 예외를 발생시키는 방식으로 노출되며, `is_complete`는 실행이 종료 상태에 도달했는지를 반영합니다.

### 원문 응답

[`raw_responses`][agents.result.RunResultBase.raw_responses]에는 실행 중 수집된 원문 모델 응답이 들어 있습니다. 다단계 실행에서는 예를 들어 핸드오프 또는 반복되는 모델/도구/모델 사이클을 거치며 응답이 둘 이상 생성될 수 있습니다.

[`last_response_id`][agents.result.RunResultBase.last_response_id]는 `raw_responses`의 마지막 항목 ID일 뿐입니다.

### 가드레일 결과

에이전트 수준 가드레일은 [`input_guardrail_results`][agents.result.RunResultBase.input_guardrail_results] 및 [`output_guardrail_results`][agents.result.RunResultBase.output_guardrail_results]로 노출됩니다.

도구 가드레일은 [`tool_input_guardrail_results`][agents.result.RunResultBase.tool_input_guardrail_results] 및 [`tool_output_guardrail_results`][agents.result.RunResultBase.tool_output_guardrail_results]로 별도 노출됩니다.

이 배열들은 실행 전체에 걸쳐 누적되므로, 의사결정 로깅, 추가 가드레일 메타데이터 저장, 실행이 차단된 이유 디버깅에 유용합니다.

### 컨텍스트 및 사용량

[`context_wrapper`][agents.result.RunResultBase.context_wrapper]는 앱 컨텍스트와 함께 승인, 사용량, 중첩 `tool_input` 같은 SDK 관리 런타임 메타데이터를 노출합니다.

사용량은 `context_wrapper.usage`에서 추적됩니다. 스트리밍 실행의 경우 스트림 최종 청크가 처리될 때까지 사용량 합계가 지연될 수 있습니다. 전체 래퍼 형태와 영속성 관련 주의사항은 [Context management](context.md)를 참고하세요.

================
File: docs/ko/running_agents.md
================
---
search:
  exclude: true
---
# 에이전트 실행

[`Runner`][agents.run.Runner] 클래스를 통해 에이전트를 실행할 수 있습니다. 방법은 3가지입니다

1. [`Runner.run()`][agents.run.Runner.run]: 비동기로 실행되며 [`RunResult`][agents.result.RunResult]를 반환합니다
2. [`Runner.run_sync()`][agents.run.Runner.run_sync]: 동기 메서드이며 내부적으로 `.run()`을 실행합니다
3. [`Runner.run_streamed()`][agents.run.Runner.run_streamed]: 비동기로 실행되며 [`RunResultStreaming`][agents.result.RunResultStreaming]을 반환합니다. LLM을 스트리밍 모드로 호출하고, 수신되는 이벤트를 즉시 스트리밍합니다

```python
from agents import Agent, Runner

async def main():
    agent = Agent(name="Assistant", instructions="You are a helpful assistant")

    result = await Runner.run(agent, "Write a haiku about recursion in programming.")
    print(result.final_output)
    # Code within the code,
    # Functions calling themselves,
    # Infinite loop's dance
```

자세한 내용은 [결과 가이드](results.md)를 참고하세요

## Runner 수명 주기 및 구성

### 에이전트 루프

`Runner`의 run 메서드를 사용할 때 시작 에이전트와 입력을 전달합니다. 입력은 다음 중 하나일 수 있습니다

-   문자열(사용자 메시지로 처리)
-   OpenAI Responses API 형식의 입력 항목 목록
-   인터럽션(중단 처리)된 실행을 재개할 때의 [`RunState`][agents.run_state.RunState]

그다음 runner는 루프를 실행합니다

1. 현재 입력으로 현재 에이전트에 대해 LLM을 호출합니다
2. LLM이 출력을 생성합니다
    1. LLM이 `final_output`을 반환하면 루프를 종료하고 결과를 반환합니다
    2. LLM이 핸드오프를 수행하면 현재 에이전트와 입력을 업데이트하고 루프를 다시 실행합니다
    3. LLM이 도구 호출을 생성하면 해당 도구 호출을 실행하고 결과를 추가한 뒤 루프를 다시 실행합니다
3. 전달된 `max_turns`를 초과하면 [`MaxTurnsExceeded`][agents.exceptions.MaxTurnsExceeded] 예외를 발생시킵니다

!!! note

    LLM 출력이 "final output"으로 간주되는 기준은 원하는 타입의 텍스트 출력을 생성하고, 도구 호출이 없는 경우입니다

### 스트리밍

스트리밍을 사용하면 LLM 실행 중 스트리밍 이벤트를 추가로 받을 수 있습니다. 스트림이 완료되면 [`RunResultStreaming`][agents.result.RunResultStreaming]에 실행에 관한 전체 정보(생성된 모든 신규 출력 포함)가 담깁니다. 스트리밍 이벤트는 `.stream_events()`를 호출해 받을 수 있습니다. 자세한 내용은 [스트리밍 가이드](streaming.md)를 참고하세요

#### Responses WebSocket 전송(선택적 헬퍼)

OpenAI Responses websocket 전송을 활성화하면 일반 `Runner` API를 계속 사용할 수 있습니다. websocket 세션 헬퍼는 연결 재사용에 권장되지만 필수는 아닙니다

이것은 websocket 전송 기반 Responses API이며 [Realtime API](realtime/guide.md)가 아닙니다

구체적인 모델 객체 또는 커스텀 provider 관련 전송 선택 규칙과 주의사항은 [Models](models/index.md#responses-websocket-transport)를 참고하세요

##### 패턴 1: 세션 헬퍼 없음(작동함)

websocket 전송만 원하고 SDK가 공유 provider/session을 관리할 필요가 없을 때 사용합니다

```python
import asyncio

from agents import Agent, Runner, set_default_openai_responses_transport


async def main():
    set_default_openai_responses_transport("websocket")

    agent = Agent(name="Assistant", instructions="Be concise.")
    result = Runner.run_streamed(agent, "Summarize recursion in one sentence.")

    async for event in result.stream_events():
        if event.type == "raw_response_event":
            continue
        print(event.type)


asyncio.run(main())
```

이 패턴은 단일 실행에 적합합니다. `Runner.run()` / `Runner.run_streamed()`를 반복 호출하면 동일한 `RunConfig` / provider 인스턴스를 수동 재사용하지 않는 한 실행마다 재연결될 수 있습니다

##### 패턴 2: `responses_websocket_session()` 사용(멀티턴 재사용에 권장)

여러 실행(동일한 `run_config`를 상속하는 중첩 agent-as-tool 호출 포함)에서 websocket 지원 provider와 `RunConfig`를 공유하려면 [`responses_websocket_session()`][agents.responses_websocket_session]을 사용하세요

```python
import asyncio

from agents import Agent, responses_websocket_session


async def main():
    agent = Agent(name="Assistant", instructions="Be concise.")

    async with responses_websocket_session() as ws:
        first = ws.run_streamed(agent, "Say hello in one short sentence.")
        async for _event in first.stream_events():
            pass

        second = ws.run_streamed(
            agent,
            "Now say goodbye.",
            previous_response_id=first.last_response_id,
        )
        async for _event in second.stream_events():
            pass


asyncio.run(main())
```

컨텍스트를 종료하기 전에 스트리밍 결과 소비를 완료하세요. websocket 요청이 진행 중인 상태에서 컨텍스트를 종료하면 공유 연결이 강제 종료될 수 있습니다

### 실행 구성

`run_config` 매개변수로 에이전트 실행의 전역 설정 일부를 구성할 수 있습니다

#### 공통 실행 구성 카테고리

각 에이전트 정의를 변경하지 않고 단일 실행의 동작을 재정의하려면 `RunConfig`를 사용하세요

##### 모델, provider, 세션 기본값

-   [`model`][agents.run.RunConfig.model]: 각 Agent의 `model`과 관계없이 사용할 전역 LLM 모델을 설정할 수 있습니다
-   [`model_provider`][agents.run.RunConfig.model_provider]: 모델 이름 조회용 모델 provider이며 기본값은 OpenAI입니다
-   [`model_settings`][agents.run.RunConfig.model_settings]: 에이전트별 설정을 재정의합니다. 예: 전역 `temperature` 또는 `top_p` 설정
-   [`session_settings`][agents.run.RunConfig.session_settings]: 실행 중 히스토리 조회 시 세션 수준 기본값(예: `SessionSettings(limit=...)`)을 재정의합니다
-   [`session_input_callback`][agents.run.RunConfig.session_input_callback]: Sessions 사용 시 각 턴 전에 새 사용자 입력을 세션 히스토리와 병합하는 방식을 커스터마이즈합니다. 콜백은 sync 또는 async가 가능합니다

##### 가드레일, 핸드오프, 모델 입력 형태 조정

-   [`input_guardrails`][agents.run.RunConfig.input_guardrails], [`output_guardrails`][agents.run.RunConfig.output_guardrails]: 모든 실행에 포함할 입력 또는 출력 가드레일 목록
-   [`handoff_input_filter`][agents.run.RunConfig.handoff_input_filter]: 핸드오프에 이미 필터가 없는 경우 모든 핸드오프에 적용할 전역 입력 필터입니다. 입력 필터로 새 에이전트에 전송되는 입력을 편집할 수 있습니다. 자세한 내용은 [`Handoff.input_filter`][agents.handoffs.Handoff.input_filter] 문서를 참고하세요
-   [`nest_handoff_history`][agents.run.RunConfig.nest_handoff_history]: 다음 에이전트 호출 전에 이전 transcript를 단일 assistant 메시지로 축약하는 opt-in 베타 기능입니다. 중첩 핸드오프 안정화 중이므로 기본 비활성화이며, 활성화하려면 `True`, 원문 transcript를 통과시키려면 `False`를 사용합니다. [Runner 메서드][agents.run.Runner]는 `RunConfig`를 전달하지 않으면 자동 생성하므로 quickstart와 코드 예제에서는 기본적으로 비활성화 상태를 유지하며, 명시적 [`Handoff.input_filter`][agents.handoffs.Handoff.input_filter] 콜백은 계속 우선 적용됩니다. 개별 핸드오프는 [`Handoff.nest_handoff_history`][agents.handoffs.Handoff.nest_handoff_history]로 이 설정을 재정의할 수 있습니다
-   [`handoff_history_mapper`][agents.run.RunConfig.handoff_history_mapper]: `nest_handoff_history`를 사용할 때마다 정규화된 transcript(히스토리 + 핸드오프 항목)를 받아 다음 에이전트로 전달할 정확한 입력 항목 목록을 반환하는 선택적 callable입니다. 전체 핸드오프 필터를 작성하지 않고도 내장 요약을 대체할 수 있습니다
-   [`call_model_input_filter`][agents.run.RunConfig.call_model_input_filter]: 모델 호출 직전에 완전히 준비된 모델 입력(instructions 및 입력 항목)을 편집하는 훅입니다. 예: 히스토리 축약, 시스템 프롬프트 주입
-   [`reasoning_item_id_policy`][agents.run.RunConfig.reasoning_item_id_policy]: runner가 이전 출력을 다음 턴 모델 입력으로 변환할 때 reasoning 항목 ID를 유지할지 생략할지 제어합니다

##### 트레이싱 및 관측 가능성

-   [`tracing_disabled`][agents.run.RunConfig.tracing_disabled]: 전체 실행에 대해 [트레이싱](tracing.md)을 비활성화할 수 있습니다
-   [`tracing`][agents.run.RunConfig.tracing]: 이 실행의 exporter, processor 또는 트레이싱 메타데이터를 재정의하려면 [`TracingConfig`][agents.tracing.TracingConfig]를 전달합니다
-   [`trace_include_sensitive_data`][agents.run.RunConfig.trace_include_sensitive_data]: 트레이스에 LLM/도구 호출 입력/출력 등 잠재적으로 민감한 데이터를 포함할지 구성합니다
-   [`workflow_name`][agents.run.RunConfig.workflow_name], [`trace_id`][agents.run.RunConfig.trace_id], [`group_id`][agents.run.RunConfig.group_id]: 실행의 트레이싱 워크플로 이름, trace ID, trace group ID를 설정합니다. 최소한 `workflow_name` 설정을 권장합니다. group ID는 여러 실행 간 트레이스를 연결할 수 있는 선택 필드입니다
-   [`trace_metadata`][agents.run.RunConfig.trace_metadata]: 모든 트레이스에 포함할 메타데이터

##### 도구 승인 및 도구 오류 동작

-   [`tool_error_formatter`][agents.run.RunConfig.tool_error_formatter]: 승인 플로우 중 도구 호출이 거부될 때 모델에 보이는 메시지를 커스터마이즈합니다

중첩 핸드오프는 opt-in 베타로 제공됩니다. 축약 transcript 동작을 사용하려면 `RunConfig(nest_handoff_history=True)`를 전달하거나 특정 핸드오프에 `handoff(..., nest_handoff_history=True)`를 설정하세요. 원문 transcript(기본값)를 유지하려면 플래그를 설정하지 않거나, 대화를 원하는 그대로 전달하는 `handoff_input_filter`(또는 `handoff_history_mapper`)를 제공하세요. 커스텀 mapper 작성 없이 생성 요약에 사용되는 래퍼 텍스트를 변경하려면 [`set_conversation_history_wrappers`][agents.handoffs.set_conversation_history_wrappers]를 호출하세요(기본값 복원은 [`reset_conversation_history_wrappers`][agents.handoffs.reset_conversation_history_wrappers])

#### 실행 구성 세부사항

##### `tool_error_formatter`

승인 플로우에서 도구 호출이 거부될 때 모델에 반환되는 메시지를 커스터마이즈하려면 `tool_error_formatter`를 사용하세요

formatter는 다음이 포함된 [`ToolErrorFormatterArgs`][agents.run_config.ToolErrorFormatterArgs]를 받습니다

-   `kind`: 오류 카테고리. 현재는 `"approval_rejected"`입니다
-   `tool_type`: 도구 런타임(`"function"`, `"computer"`, `"shell"`, `"apply_patch"`)
-   `tool_name`: 도구 이름
-   `call_id`: 도구 호출 ID
-   `default_message`: SDK의 기본 모델 표시 메시지
-   `run_context`: 활성 실행 컨텍스트 래퍼

메시지를 대체할 문자열을 반환하거나 SDK 기본값을 사용하려면 `None`을 반환하세요

```python
from agents import Agent, RunConfig, Runner, ToolErrorFormatterArgs


def format_rejection(args: ToolErrorFormatterArgs[None]) -> str | None:
    if args.kind == "approval_rejected":
        return (
            f"Tool call '{args.tool_name}' was rejected by a human reviewer. "
            "Ask for confirmation or propose a safer alternative."
        )
    return None


agent = Agent(name="Assistant")
result = Runner.run_sync(
    agent,
    "Please delete the production database.",
    run_config=RunConfig(tool_error_formatter=format_rejection),
)
```

##### `reasoning_item_id_policy`

`reasoning_item_id_policy`는 runner가 히스토리를 다음 턴으로 전달할 때(예: `RunResult.to_input_list()` 또는 session 기반 실행) reasoning 항목을 다음 턴 모델 입력으로 변환하는 방식을 제어합니다

-   `None` 또는 `"preserve"`(기본값): reasoning 항목 ID 유지
-   `"omit"`: 생성된 다음 턴 입력에서 reasoning 항목 ID 제거

`"omit"`은 주로 Responses API 400 오류의 한 유형에 대한 opt-in 완화책으로 사용합니다. 이 오류는 reasoning 항목이 `id`와 함께 전송되지만 필수 후속 항목 없이 전송될 때 발생합니다(예: `Item 'rs_...' of type 'reasoning' was provided without its required following item.`)

이는 SDK가 이전 출력으로 후속 입력을 구성하는 멀티턴 에이전트 실행에서 발생할 수 있습니다(세션 영속성, 서버 관리 대화 델타, 스트리밍/비스트리밍 후속 턴, 재개 경로 포함). 이때 reasoning 항목 ID는 유지되지만 provider가 해당 ID가 대응하는 후속 항목과 짝을 유지하도록 요구할 수 있습니다

`reasoning_item_id_policy="omit"`을 설정하면 reasoning 내용은 유지하면서 reasoning 항목 `id`를 제거하므로 SDK가 생성한 후속 입력에서 해당 API 불변 조건을 트리거하지 않게 됩니다

적용 범위 참고사항

-   이는 SDK가 후속 입력을 구성할 때 생성/전달하는 reasoning 항목에만 영향을 줍니다
-   사용자가 제공한 초기 입력 항목은 다시 작성하지 않습니다
-   `call_model_input_filter`는 이 정책 적용 후에도 의도적으로 reasoning ID를 다시 도입할 수 있습니다

## 상태 및 대화 관리

### 메모리 전략 선택

다음 턴으로 상태를 전달하는 일반적인 방법은 4가지입니다

| 전략 | 상태 저장 위치 | 적합한 경우 | 다음 턴에 전달할 내용 |
| --- | --- | --- | --- |
| `result.to_input_list()` | 앱 메모리 | 작은 채팅 루프, 완전 수동 제어, 모든 provider | `result.to_input_list()`의 목록 + 다음 사용자 메시지 |
| `session` | 사용자 저장소 + SDK | 영속 채팅 상태, 재개 가능한 실행, 커스텀 스토어 | 동일한 `session` 인스턴스 또는 같은 스토어를 가리키는 다른 인스턴스 |
| `conversation_id` | OpenAI Conversations API | 워커/서비스 간 공유할 이름 있는 서버 측 대화 | 동일한 `conversation_id` + 새 사용자 턴만 |
| `previous_response_id` | OpenAI Responses API | 대화 리소스 생성 없이 가벼운 서버 관리 연속 실행 | `result.last_response_id` + 새 사용자 턴만 |

`result.to_input_list()`와 `session`은 클라이언트 관리 방식입니다. `conversation_id`와 `previous_response_id`는 OpenAI 관리 방식이며 OpenAI Responses API 사용 시에만 적용됩니다. 대부분의 애플리케이션에서는 대화당 하나의 영속화 전략을 선택하세요. 클라이언트 관리 히스토리와 OpenAI 관리 상태를 함께 쓰면 두 계층을 의도적으로 조정하지 않는 한 컨텍스트가 중복될 수 있습니다

!!! note

    세션 영속성은 서버 관리 대화 설정
    (`conversation_id`, `previous_response_id`, `auto_previous_response_id`)과
    동일 실행에서 함께 사용할 수 없습니다. 호출마다 한 가지 접근법을 선택하세요

### 대화/채팅 스레드

어떤 run 메서드를 호출하든 하나 이상의 에이전트 실행(즉 하나 이상의 LLM 호출)이 발생할 수 있지만, 논리적으로는 채팅 대화의 단일 턴을 나타냅니다. 예를 들어

1. 사용자 턴: 사용자가 텍스트 입력
2. Runner 실행: 첫 번째 에이전트가 LLM 호출, 도구 실행, 두 번째 에이전트로 핸드오프, 두 번째 에이전트가 추가 도구 실행 후 출력 생성

에이전트 실행이 끝나면 사용자에게 무엇을 보여줄지 선택할 수 있습니다. 예를 들어 에이전트가 생성한 모든 신규 항목을 보여주거나 최종 출력만 보여줄 수 있습니다. 어느 쪽이든 사용자가 후속 질문을 하면 run 메서드를 다시 호출할 수 있습니다

#### 수동 대화 관리

다음 턴 입력을 얻기 위해 [`RunResultBase.to_input_list()`][agents.result.RunResultBase.to_input_list] 메서드로 대화 히스토리를 수동 관리할 수 있습니다

```python
async def main():
    agent = Agent(name="Assistant", instructions="Reply very concisely.")

    thread_id = "thread_123"  # Example thread ID
    with trace(workflow_name="Conversation", group_id=thread_id):
        # First turn
        result = await Runner.run(agent, "What city is the Golden Gate Bridge in?")
        print(result.final_output)
        # San Francisco

        # Second turn
        new_input = result.to_input_list() + [{"role": "user", "content": "What state is it in?"}]
        result = await Runner.run(agent, new_input)
        print(result.final_output)
        # California
```

#### Sessions를 사용한 자동 대화 관리

더 간단한 방법으로 [Sessions](sessions/index.md)를 사용하면 `.to_input_list()`를 수동 호출하지 않고도 대화 히스토리를 자동 처리할 수 있습니다

```python
from agents import Agent, Runner, SQLiteSession

async def main():
    agent = Agent(name="Assistant", instructions="Reply very concisely.")

    # Create session instance
    session = SQLiteSession("conversation_123")

    thread_id = "thread_123"  # Example thread ID
    with trace(workflow_name="Conversation", group_id=thread_id):
        # First turn
        result = await Runner.run(agent, "What city is the Golden Gate Bridge in?", session=session)
        print(result.final_output)
        # San Francisco

        # Second turn - agent automatically remembers previous context
        result = await Runner.run(agent, "What state is it in?", session=session)
        print(result.final_output)
        # California
```

Sessions는 자동으로 다음을 수행합니다

-   각 실행 전에 대화 히스토리 조회
-   각 실행 후 새 메시지 저장
-   서로 다른 세션 ID에 대해 분리된 대화 유지

자세한 내용은 [Sessions 문서](sessions/index.md)를 참고하세요


#### 서버 관리 대화

`to_input_list()` 또는 `Sessions`로 로컬 처리하는 대신 OpenAI 대화 상태 기능이 서버 측에서 대화 상태를 관리하도록 할 수도 있습니다. 이렇게 하면 과거 메시지 전체를 수동 재전송하지 않고 대화 히스토리를 유지할 수 있습니다. 아래의 서버 관리 방식에서는 요청마다 새 턴 입력만 전달하고 저장된 ID를 재사용하세요. 자세한 내용은 [OpenAI 대화 상태 가이드](https://platform.openai.com/docs/guides/conversation-state?api-mode=responses)를 참고하세요

OpenAI는 턴 간 상태 추적을 위한 두 가지 방법을 제공합니다

##### 1. `conversation_id` 사용

먼저 OpenAI Conversations API로 대화를 생성한 뒤, 이후 모든 호출에서 해당 ID를 재사용합니다

```python
from agents import Agent, Runner
from openai import AsyncOpenAI

client = AsyncOpenAI()

async def main():
    agent = Agent(name="Assistant", instructions="Reply very concisely.")

    # Create a server-managed conversation
    conversation = await client.conversations.create()
    conv_id = conversation.id

    while True:
        user_input = input("You: ")
        result = await Runner.run(agent, user_input, conversation_id=conv_id)
        print(f"Assistant: {result.final_output}")
```

##### 2. `previous_response_id` 사용

다른 방법은 **응답 체이닝(response chaining)**으로, 각 턴을 이전 턴의 응답 ID에 명시적으로 연결합니다

```python
from agents import Agent, Runner

async def main():
    agent = Agent(name="Assistant", instructions="Reply very concisely.")

    previous_response_id = None

    while True:
        user_input = input("You: ")

        # Setting auto_previous_response_id=True enables response chaining automatically
        # for the first turn, even when there's no actual previous response ID yet.
        result = await Runner.run(
            agent,
            user_input,
            previous_response_id=previous_response_id,
            auto_previous_response_id=True,
        )
        previous_response_id = result.last_response_id
        print(f"Assistant: {result.final_output}")
```

실행이 승인 대기로 일시 중지되어 [`RunState`][agents.run_state.RunState]에서 재개하는 경우,
SDK는 저장된 `conversation_id` / `previous_response_id` / `auto_previous_response_id`
설정을 유지하므로 재개된 턴이 동일한 서버 관리 대화에서 계속됩니다

`conversation_id`와 `previous_response_id`는 상호 배타적입니다. 시스템 간 공유 가능한 이름 있는 대화 리소스가 필요하면 `conversation_id`를 사용하세요. 턴 간 가장 가벼운 Responses API 연속 실행 기본 요소가 필요하면 `previous_response_id`를 사용하세요

!!! note

    SDK는 `conversation_locked` 오류를 백오프와 함께 자동 재시도합니다. 서버 관리
    대화 실행에서는 재시도 전에 내부 conversation-tracker 입력을 되감아
    동일한 준비 항목을 깔끔하게 재전송할 수 있도록 합니다

    로컬 session 기반 실행에서는(`conversation_id`,
    `previous_response_id`, `auto_previous_response_id`와 함께 사용할 수 없음) SDK가
    재시도 후 중복 히스토리 항목을 줄이기 위해 최근 저장된 입력 항목을
    최선의 노력으로 롤백합니다

## 훅 및 커스터마이즈

### call model input filter

모델 호출 직전에 모델 입력을 편집하려면 `call_model_input_filter`를 사용하세요. 이 훅은 현재 에이전트, 컨텍스트, 결합된 입력 항목(Session 히스토리 포함 가능)을 받고 새로운 `ModelInputData`를 반환합니다

반환값은 [`ModelInputData`][agents.run.ModelInputData] 객체여야 합니다. `input` 필드는 필수이며 입력 항목 목록이어야 합니다. 다른 형태를 반환하면 `UserError`가 발생합니다

```python
from agents import Agent, Runner, RunConfig
from agents.run import CallModelData, ModelInputData

def drop_old_messages(data: CallModelData[None]) -> ModelInputData:
    # Keep only the last 5 items and preserve existing instructions.
    trimmed = data.model_data.input[-5:]
    return ModelInputData(input=trimmed, instructions=data.model_data.instructions)

agent = Agent(name="Assistant", instructions="Answer concisely.")
result = Runner.run_sync(
    agent,
    "Explain quines",
    run_config=RunConfig(call_model_input_filter=drop_old_messages),
)
```

runner는 준비된 입력 목록의 복사본을 훅에 전달하므로, 호출자가 가진 원본 목록을 제자리 변경하지 않고도 항목을 축약, 교체, 재정렬할 수 있습니다

session을 사용하는 경우 `call_model_input_filter`는 세션 히스토리가 이미 로드되어 현재 턴과 병합된 뒤에 실행됩니다. 이보다 이른 병합 단계 자체를 커스터마이즈하려면 [`session_input_callback`][agents.run.RunConfig.session_input_callback]을 사용하세요

`conversation_id`, `previous_response_id`, `auto_previous_response_id`를 사용하는 OpenAI 서버 관리 대화 상태에서는 이 훅이 다음 Responses API 호출용 준비 payload에 대해 실행됩니다. 이 payload는 이미 이전 히스토리 전체 재생이 아닌 새 턴 델타만 나타낼 수 있습니다. 사용자가 반환한 항목만 해당 서버 관리 연속 실행에서 전송된 것으로 표시됩니다

민감 정보 마스킹, 긴 히스토리 축약, 추가 시스템 가이드 주입을 위해 실행별로 `run_config`에서 이 훅을 설정하세요

## 오류 및 복구

### 오류 핸들러

모든 `Runner` 진입점은 오류 종류를 키로 하는 dict인 `error_handlers`를 받습니다. 현재 지원 키는 `"max_turns"`입니다. `MaxTurnsExceeded`를 발생시키는 대신 제어된 최종 출력을 반환하려면 사용하세요

```python
from agents import (
    Agent,
    RunErrorHandlerInput,
    RunErrorHandlerResult,
    Runner,
)

agent = Agent(name="Assistant", instructions="Be concise.")


def on_max_turns(_data: RunErrorHandlerInput[None]) -> RunErrorHandlerResult:
    return RunErrorHandlerResult(
        final_output="I couldn't finish within the turn limit. Please narrow the request.",
        include_in_history=False,
    )


result = Runner.run_sync(
    agent,
    "Analyze this long transcript",
    max_turns=3,
    error_handlers={"max_turns": on_max_turns},
)
print(result.final_output)
```

대체 출력이 대화 히스토리에 추가되지 않도록 하려면 `include_in_history=False`를 설정하세요

## 내구성 실행 통합 및 휴먼인더루프 (HITL)

도구 승인 일시중지/재개 패턴은 전용 [휴먼인더루프 가이드](human_in_the_loop.md)부터 참고하세요
아래 통합은 실행이 긴 대기, 재시도, 프로세스 재시작을 걸칠 수 있는 내구성 오케스트레이션을 위한 것입니다

### Temporal

Agents SDK의 [Temporal](https://temporal.io/) 통합을 사용하면 휴먼인더루프 작업을 포함한 내구성 있고 장시간 실행되는 워크플로를 실행할 수 있습니다. 장시간 작업을 완료하기 위해 Temporal과 Agents SDK가 함께 동작하는 데모는 [이 영상](https://www.youtube.com/watch?v=fFBZqzT4DD8)에서 확인할 수 있으며, 문서는 [여기](https://github.com/temporalio/sdk-python/tree/main/temporalio/contrib/openai_agents)에서 확인할 수 있습니다

### Restate

Agents SDK의 [Restate](https://restate.dev/) 통합을 사용하면 인간 승인, 핸드오프, 세션 관리를 포함한 경량의 내구성 있는 에이전트를 구현할 수 있습니다. 이 통합은 의존성으로 Restate의 단일 바이너리 런타임이 필요하며, 프로세스/컨테이너 또는 서버리스 함수로 에이전트를 실행할 수 있습니다
자세한 내용은 [개요](https://www.restate.dev/blog/durable-orchestration-for-ai-agents-with-restate-and-openai-sdk) 또는 [문서](https://docs.restate.dev/ai)를 참고하세요

### DBOS

Agents SDK의 [DBOS](https://dbos.dev/) 통합을 사용하면 실패 및 재시작 상황에서도 진행 상태를 보존하는 신뢰성 높은 에이전트를 실행할 수 있습니다. 장시간 실행 에이전트, 휴먼인더루프 워크플로, 핸드오프를 지원합니다. sync와 async 메서드를 모두 지원합니다. 이 통합에는 SQLite 또는 Postgres 데이터베이스만 필요합니다. 자세한 내용은 통합 [repo](https://github.com/dbos-inc/dbos-openai-agents)와 [문서](https://docs.dbos.dev/integrations/openai-agents)를 참고하세요

## 예외

SDK는 특정 경우 예외를 발생시킵니다. 전체 목록은 [`agents.exceptions`][]에 있습니다. 개요는 다음과 같습니다

-   [`AgentsException`][agents.exceptions.AgentsException]: SDK 내부에서 발생하는 모든 예외의 기본 클래스입니다. 다른 모든 구체적인 예외가 이 클래스를 기반으로 파생됩니다
-   [`MaxTurnsExceeded`][agents.exceptions.MaxTurnsExceeded]: 에이전트 실행이 `Runner.run`, `Runner.run_sync`, `Runner.run_streamed` 메서드에 전달한 `max_turns` 제한을 초과할 때 발생합니다. 지정된 상호작용 턴 수 내에 에이전트가 작업을 완료하지 못했음을 의미합니다
-   [`ModelBehaviorError`][agents.exceptions.ModelBehaviorError]: 기반 모델(LLM)이 예상치 못했거나 유효하지 않은 출력을 생성할 때 발생합니다. 예시는 다음과 같습니다
    -   잘못된 형식의 JSON: 모델이 도구 호출용 JSON 구조 또는 직접 출력에서 잘못된 형식의 JSON을 제공한 경우(특히 특정 `output_type`이 정의된 경우)
    -   예상치 못한 도구 관련 실패: 모델이 예상된 방식으로 도구를 사용하지 못한 경우
-   [`ToolTimeoutError`][agents.exceptions.ToolTimeoutError]: 함수 도구 호출이 구성된 타임아웃을 초과했고 도구가 `timeout_behavior="raise_exception"`을 사용할 때 발생합니다
-   [`UserError`][agents.exceptions.UserError]: SDK를 사용하는 코드 작성자(사용자)가 SDK 사용 중 오류를 낼 때 발생합니다. 일반적으로 잘못된 코드 구현, 유효하지 않은 구성, SDK API 오용에서 비롯됩니다
-   [`InputGuardrailTripwireTriggered`][agents.exceptions.InputGuardrailTripwireTriggered], [`OutputGuardrailTripwireTriggered`][agents.exceptions.OutputGuardrailTripwireTriggered]: 입력 가드레일 또는 출력 가드레일 조건이 각각 충족될 때 발생합니다. 입력 가드레일은 처리 전 들어오는 메시지를 점검하고, 출력 가드레일은 전달 전 에이전트의 최종 응답을 점검합니다

================
File: docs/ko/streaming.md
================
---
search:
  exclude: true
---
# 스트리밍

스트리밍을 사용하면 에이전트 실행이 진행되는 동안 업데이트를 구독할 수 있습니다. 이는 최종 사용자에게 진행 상황 업데이트와 부분 응답을 보여주는 데 유용합니다.

스트리밍하려면 [`Runner.run_streamed()`][agents.run.Runner.run_streamed]를 호출하면 되며, 그러면 [`RunResultStreaming`][agents.result.RunResultStreaming]을 받게 됩니다. `result.stream_events()`를 호출하면 아래에 설명된 [`StreamEvent`][agents.stream_events.StreamEvent] 객체의 비동기 스트림을 얻을 수 있습니다.

비동기 이터레이터가 종료될 때까지 `result.stream_events()`를 계속 소비하세요. 스트리밍 실행은 이터레이터가 끝나기 전까지 완료되지 않으며, 세션 영속성, 승인 기록 관리, 히스토리 압축과 같은 후처리는 마지막으로 보이는 토큰이 도착한 뒤에 완료될 수 있습니다. 루프가 종료되면 `result.is_complete`가 최종 실행 상태를 반영합니다.

## 원문 응답 이벤트

[`RawResponsesStreamEvent`][agents.stream_events.RawResponsesStreamEvent]는 LLM에서 직접 전달되는 원문 이벤트입니다. OpenAI Responses API 형식이므로 각 이벤트에는 타입(예: `response.created`, `response.output_text.delta` 등)과 데이터가 있습니다. 이 이벤트는 응답 메시지가 생성되는 즉시 사용자에게 스트리밍하고 싶을 때 유용합니다.

예를 들어, 다음은 LLM이 생성한 텍스트를 토큰 단위로 출력합니다.

```python
import asyncio
from openai.types.responses import ResponseTextDeltaEvent
from agents import Agent, Runner

async def main():
    agent = Agent(
        name="Joker",
        instructions="You are a helpful assistant.",
    )

    result = Runner.run_streamed(agent, input="Please tell me 5 jokes.")
    async for event in result.stream_events():
        if event.type == "raw_response_event" and isinstance(event.data, ResponseTextDeltaEvent):
            print(event.data.delta, end="", flush=True)


if __name__ == "__main__":
    asyncio.run(main())
```

## 스트리밍과 승인

스트리밍은 도구 승인을 위해 일시 중지되는 실행과 호환됩니다. 도구에 승인이 필요하면 `result.stream_events()`가 종료되고, 보류 중인 승인은 [`RunResultStreaming.interruptions`][agents.result.RunResultStreaming.interruptions]에 노출됩니다. `result.to_state()`로 결과를 [`RunState`][agents.run_state.RunState]로 변환하고 인터럽션(중단 처리)을 승인 또는 거부한 다음, `Runner.run_streamed(...)`로 재개하세요.

```python
result = Runner.run_streamed(agent, "Delete temporary files if they are no longer needed.")
async for _event in result.stream_events():
    pass

if result.interruptions:
    state = result.to_state()
    for interruption in result.interruptions:
        state.approve(interruption)
    result = Runner.run_streamed(agent, state)
    async for _event in result.stream_events():
        pass
```

전체 일시 중지/재개 흐름은 [휴먼인더루프 (HITL) 가이드](human_in_the_loop.md)를 참고하세요.

## 실행 항목 이벤트와 에이전트 이벤트

[`RunItemStreamEvent`][agents.stream_events.RunItemStreamEvent]는 더 높은 수준의 이벤트입니다. 항목이 완전히 생성되었을 때 이를 알려줍니다. 이를 통해 각 토큰 단위가 아니라 "메시지 생성됨", "도구 실행됨" 등의 수준에서 진행 상황 업데이트를 푸시할 수 있습니다. 마찬가지로, [`AgentUpdatedStreamEvent`][agents.stream_events.AgentUpdatedStreamEvent]는 현재 에이전트가 변경될 때(예: 핸드오프 결과) 업데이트를 제공합니다.

### 실행 항목 이벤트 이름

`RunItemStreamEvent.name`은 고정된 의미론적 이벤트 이름 집합을 사용합니다:

-   `message_output_created`
-   `handoff_requested`
-   `handoff_occured`
-   `tool_called`
-   `tool_output`
-   `reasoning_item_created`
-   `mcp_approval_requested`
-   `mcp_approval_response`
-   `mcp_list_tools`

`handoff_occured`는 하위 호환성을 위해 의도적으로 철자가 잘못되어 있습니다.

예를 들어, 다음은 원문 이벤트를 무시하고 사용자에게 업데이트를 스트리밍합니다.

```python
import asyncio
import random
from agents import Agent, ItemHelpers, Runner, function_tool

@function_tool
def how_many_jokes() -> int:
    return random.randint(1, 10)


async def main():
    agent = Agent(
        name="Joker",
        instructions="First call the `how_many_jokes` tool, then tell that many jokes.",
        tools=[how_many_jokes],
    )

    result = Runner.run_streamed(
        agent,
        input="Hello",
    )
    print("=== Run starting ===")

    async for event in result.stream_events():
        # We'll ignore the raw responses event deltas
        if event.type == "raw_response_event":
            continue
        # When the agent updates, print that
        elif event.type == "agent_updated_stream_event":
            print(f"Agent updated: {event.new_agent.name}")
            continue
        # When items are generated, print them
        elif event.type == "run_item_stream_event":
            if event.item.type == "tool_call_item":
                print("-- Tool was called")
            elif event.item.type == "tool_call_output_item":
                print(f"-- Tool output: {event.item.output}")
            elif event.item.type == "message_output_item":
                print(f"-- Message output:\n {ItemHelpers.text_message_output(event.item)}")
            else:
                pass  # Ignore other event types

    print("=== Run complete ===")


if __name__ == "__main__":
    asyncio.run(main())
```

================
File: docs/ko/tools.md
================
---
search:
  exclude: true
---
# 도구

도구를 사용하면 에이전트가 데이터 가져오기, 코드 실행, 외부 API 호출, 심지어 컴퓨터 사용 같은 작업을 수행할 수 있습니다. SDK는 다섯 가지 카테고리를 지원합니다:

-   OpenAI 호스티드 툴: OpenAI 서버에서 모델과 함께 실행됩니다
-   로컬/런타임 실행 도구: `ComputerTool` 및 `ApplyPatchTool`은 항상 사용자 환경에서 실행되며, `ShellTool`은 로컬 또는 호스티드 컨테이너에서 실행될 수 있습니다
-   함수 호출: 어떤 Python 함수든 도구로 래핑할 수 있습니다
-   Agents as tools: 전체 핸드오프 없이 에이전트를 호출 가능한 도구로 노출합니다
-   실험적 기능: Codex 도구: 도구 호출에서 워크스페이스 범위 Codex 작업을 실행합니다

## 도구 유형 선택

이 페이지를 카탈로그로 사용한 다음, 제어하는 런타임에 맞는 섹션으로 이동하세요

| 원하는 작업 | 시작 위치 |
| --- | --- |
| OpenAI 관리형 도구 사용 (웹 검색, 파일 검색, 코드 인터프리터, 호스티드 MCP, 이미지 생성) | [호스티드 도구](#hosted-tools) |
| 자체 프로세스 또는 환경에서 도구 실행 | [로컬 런타임 도구](#local-runtime-tools) |
| Python 함수를 도구로 래핑 | [함수 도구](#function-tools) |
| 핸드오프 없이 한 에이전트가 다른 에이전트를 호출 | [Agents as tools](#agents-as-tools) |
| 에이전트에서 워크스페이스 범위 Codex 작업 실행 | [실험적 기능: Codex 도구](#experimental-codex-tool) |

## 호스티드 도구

[`OpenAIResponsesModel`][agents.models.openai_responses.OpenAIResponsesModel]을 사용할 때 OpenAI는 몇 가지 내장 도구를 제공합니다:

-   [`WebSearchTool`][agents.tool.WebSearchTool]은 에이전트가 웹을 검색할 수 있게 합니다
-   [`FileSearchTool`][agents.tool.FileSearchTool]은 OpenAI 벡터 스토어에서 정보를 검색할 수 있게 합니다
-   [`CodeInterpreterTool`][agents.tool.CodeInterpreterTool]은 LLM이 샌드박스 환경에서 코드를 실행할 수 있게 합니다
-   [`HostedMCPTool`][agents.tool.HostedMCPTool]은 원격 MCP 서버의 도구를 모델에 노출합니다
-   [`ImageGenerationTool`][agents.tool.ImageGenerationTool]은 프롬프트에서 이미지를 생성합니다

고급 호스티드 검색 옵션:

-   `FileSearchTool`은 `vector_store_ids`와 `max_num_results` 외에도 `filters`, `ranking_options`, `include_search_results`를 지원합니다
-   `WebSearchTool`은 `filters`, `user_location`, `search_context_size`를 지원합니다

```python
from agents import Agent, FileSearchTool, Runner, WebSearchTool

agent = Agent(
    name="Assistant",
    tools=[
        WebSearchTool(),
        FileSearchTool(
            max_num_results=3,
            vector_store_ids=["VECTOR_STORE_ID"],
        ),
    ],
)

async def main():
    result = await Runner.run(agent, "Which coffee shop should I go to, taking into account my preferences and the weather today in SF?")
    print(result.final_output)
```

### 호스티드 컨테이너 셸 + 스킬

`ShellTool`은 OpenAI 호스팅 컨테이너 실행도 지원합니다. 모델이 로컬 런타임 대신 관리형 컨테이너에서 셸 명령을 실행하도록 하려면 이 모드를 사용하세요

```python
from agents import Agent, Runner, ShellTool, ShellToolSkillReference

csv_skill: ShellToolSkillReference = {
    "type": "skill_reference",
    "skill_id": "skill_698bbe879adc81918725cbc69dcae7960bc5613dadaed377",
    "version": "1",
}

agent = Agent(
    name="Container shell agent",
    model="gpt-5.2",
    instructions="Use the mounted skill when helpful.",
    tools=[
        ShellTool(
            environment={
                "type": "container_auto",
                "network_policy": {"type": "disabled"},
                "skills": [csv_skill],
            }
        )
    ],
)

result = await Runner.run(
    agent,
    "Use the configured skill to analyze CSV files in /mnt/data and summarize totals by region.",
)
print(result.final_output)
```

이후 실행에서 기존 컨테이너를 재사용하려면 `environment={"type": "container_reference", "container_id": "cntr_..."}`를 설정하세요

알아둘 점:

-   호스티드 셸은 Responses API 셸 도구를 통해 사용할 수 있습니다
-   `container_auto`는 요청을 위해 컨테이너를 프로비저닝하며, `container_reference`는 기존 컨테이너를 재사용합니다
-   `container_auto`에는 `file_ids`와 `memory_limit`도 포함할 수 있습니다
-   `environment.skills`는 스킬 참조와 인라인 스킬 번들을 허용합니다
-   호스티드 환경에서는 `ShellTool`에 `executor`, `needs_approval`, `on_approval`를 설정하지 마세요
-   `network_policy`는 `disabled` 및 `allowlist` 모드를 지원합니다
-   allowlist 모드에서 `network_policy.domain_secrets`는 이름으로 도메인 범위 시크릿을 주입할 수 있습니다
-   전체 코드 예제는 `examples/tools/container_shell_skill_reference.py` 및 `examples/tools/container_shell_inline_skill.py`를 참조하세요
-   OpenAI 플랫폼 가이드: [Shell](https://platform.openai.com/docs/guides/tools-shell) 및 [Skills](https://platform.openai.com/docs/guides/tools-skills)

## 로컬 런타임 도구

로컬 런타임 도구는 모델 응답 자체 외부에서 실행됩니다. 모델은 여전히 호출 시점을 결정하지만, 실제 작업은 사용자 애플리케이션이나 구성된 실행 환경이 수행합니다

`ComputerTool`과 `ApplyPatchTool`은 항상 사용자가 제공한 로컬 구현이 필요합니다. `ShellTool`은 두 모드를 모두 지원합니다. 관리형 실행을 원하면 위의 호스티드 컨테이너 구성을, 자체 프로세스에서 명령 실행을 원하면 아래 로컬 런타임 구성을 사용하세요

로컬 런타임 도구는 구현 제공이 필요합니다:

-   [`ComputerTool`][agents.tool.ComputerTool]: GUI/브라우저 자동화를 활성화하려면 [`Computer`][agents.computer.Computer] 또는 [`AsyncComputer`][agents.computer.AsyncComputer] 인터페이스를 구현하세요
-   [`ShellTool`][agents.tool.ShellTool]: 로컬 실행과 호스티드 컨테이너 실행 모두를 위한 최신 셸 도구
-   [`LocalShellTool`][agents.tool.LocalShellTool]: 레거시 로컬 셸 통합
-   [`ApplyPatchTool`][agents.tool.ApplyPatchTool]: 로컬에서 diff를 적용하려면 [`ApplyPatchEditor`][agents.editor.ApplyPatchEditor]를 구현하세요
-   로컬 셸 스킬은 `ShellTool(environment={"type": "local", "skills": [...]})`로 사용할 수 있습니다

```python
from agents import Agent, ApplyPatchTool, ShellTool
from agents.computer import AsyncComputer
from agents.editor import ApplyPatchResult, ApplyPatchOperation, ApplyPatchEditor


class NoopComputer(AsyncComputer):
    environment = "browser"
    dimensions = (1024, 768)
    async def screenshot(self): return ""
    async def click(self, x, y, button): ...
    async def double_click(self, x, y): ...
    async def scroll(self, x, y, scroll_x, scroll_y): ...
    async def type(self, text): ...
    async def wait(self): ...
    async def move(self, x, y): ...
    async def keypress(self, keys): ...
    async def drag(self, path): ...


class NoopEditor(ApplyPatchEditor):
    async def create_file(self, op: ApplyPatchOperation): return ApplyPatchResult(status="completed")
    async def update_file(self, op: ApplyPatchOperation): return ApplyPatchResult(status="completed")
    async def delete_file(self, op: ApplyPatchOperation): return ApplyPatchResult(status="completed")


async def run_shell(request):
    return "shell output"


agent = Agent(
    name="Local tools agent",
    tools=[
        ShellTool(executor=run_shell),
        ApplyPatchTool(editor=NoopEditor()),
        # ComputerTool expects a Computer/AsyncComputer implementation; omitted here for brevity.
    ],
)
```

## 함수 도구

어떤 Python 함수든 도구로 사용할 수 있습니다. Agents SDK가 도구를 자동으로 설정합니다:

-   도구 이름은 Python 함수 이름이 됩니다(또는 이름을 직접 제공할 수 있습니다)
-   도구 설명은 함수 docstring에서 가져옵니다(또는 설명을 직접 제공할 수 있습니다)
-   함수 입력 스키마는 함수 인수로부터 자동 생성됩니다
-   각 입력에 대한 설명은 비활성화하지 않는 한 함수 docstring에서 가져옵니다

함수 시그니처 추출에는 Python의 `inspect` 모듈을 사용하고, docstring 파싱에는 [`griffe`](https://mkdocstrings.github.io/griffe/), 스키마 생성에는 `pydantic`을 사용합니다

```python
import json

from typing_extensions import TypedDict, Any

from agents import Agent, FunctionTool, RunContextWrapper, function_tool


class Location(TypedDict):
    lat: float
    long: float

@function_tool  # (1)!
async def fetch_weather(location: Location) -> str:
    # (2)!
    """Fetch the weather for a given location.

    Args:
        location: The location to fetch the weather for.
    """
    # In real life, we'd fetch the weather from a weather API
    return "sunny"


@function_tool(name_override="fetch_data")  # (3)!
def read_file(ctx: RunContextWrapper[Any], path: str, directory: str | None = None) -> str:
    """Read the contents of a file.

    Args:
        path: The path to the file to read.
        directory: The directory to read the file from.
    """
    # In real life, we'd read the file from the file system
    return "<file contents>"


agent = Agent(
    name="Assistant",
    tools=[fetch_weather, read_file],  # (4)!
)

for tool in agent.tools:
    if isinstance(tool, FunctionTool):
        print(tool.name)
        print(tool.description)
        print(json.dumps(tool.params_json_schema, indent=2))
        print()

```

1.  함수 인수로 어떤 Python 타입이든 사용할 수 있으며, 함수는 sync 또는 async일 수 있습니다
2.  docstring이 있으면 설명 및 인수 설명 추출에 사용됩니다
3.  함수는 선택적으로 `context`를 받을 수 있습니다(첫 번째 인수여야 함). 도구 이름, 설명, 사용할 docstring 스타일 등 재정의도 설정할 수 있습니다
4.  데코레이트된 함수를 도구 목록에 전달할 수 있습니다

??? note "출력 펼쳐보기"

    ```
    fetch_weather
    Fetch the weather for a given location.
    {
    "$defs": {
      "Location": {
        "properties": {
          "lat": {
            "title": "Lat",
            "type": "number"
          },
          "long": {
            "title": "Long",
            "type": "number"
          }
        },
        "required": [
          "lat",
          "long"
        ],
        "title": "Location",
        "type": "object"
      }
    },
    "properties": {
      "location": {
        "$ref": "#/$defs/Location",
        "description": "The location to fetch the weather for."
      }
    },
    "required": [
      "location"
    ],
    "title": "fetch_weather_args",
    "type": "object"
    }

    fetch_data
    Read the contents of a file.
    {
    "properties": {
      "path": {
        "description": "The path to the file to read.",
        "title": "Path",
        "type": "string"
      },
      "directory": {
        "anyOf": [
          {
            "type": "string"
          },
          {
            "type": "null"
          }
        ],
        "default": null,
        "description": "The directory to read the file from.",
        "title": "Directory"
      }
    },
    "required": [
      "path"
    ],
    "title": "fetch_data_args",
    "type": "object"
    }
    ```

### 함수 도구에서 이미지 또는 파일 반환

텍스트 출력 반환 외에도, 함수 도구 출력으로 하나 이상의 이미지나 파일을 반환할 수 있습니다. 이를 위해 다음 중 하나를 반환할 수 있습니다:

-   이미지: [`ToolOutputImage`][agents.tool.ToolOutputImage] (또는 TypedDict 버전 [`ToolOutputImageDict`][agents.tool.ToolOutputImageDict])
-   파일: [`ToolOutputFileContent`][agents.tool.ToolOutputFileContent] (또는 TypedDict 버전 [`ToolOutputFileContentDict`][agents.tool.ToolOutputFileContentDict])
-   텍스트: 문자열 또는 문자열화 가능한 객체, 혹은 [`ToolOutputText`][agents.tool.ToolOutputText] (또는 TypedDict 버전 [`ToolOutputTextDict`][agents.tool.ToolOutputTextDict])

### 커스텀 함수 도구

때로는 Python 함수를 도구로 사용하고 싶지 않을 수 있습니다. 그런 경우 원하면 [`FunctionTool`][agents.tool.FunctionTool]을 직접 생성할 수 있습니다. 다음을 제공해야 합니다:

-   `name`
-   `description`
-   `params_json_schema`: 인수용 JSON 스키마
-   `on_invoke_tool`: [`ToolContext`][agents.tool_context.ToolContext]와 JSON 문자열 형태의 인수를 받아 도구 출력을 반환하는 async 함수(예: 텍스트, 구조화된 도구 출력 객체 또는 출력 목록)

```python
from typing import Any

from pydantic import BaseModel

from agents import RunContextWrapper, FunctionTool



def do_some_work(data: str) -> str:
    return "done"


class FunctionArgs(BaseModel):
    username: str
    age: int


async def run_function(ctx: RunContextWrapper[Any], args: str) -> str:
    parsed = FunctionArgs.model_validate_json(args)
    return do_some_work(data=f"{parsed.username} is {parsed.age} years old")


tool = FunctionTool(
    name="process_user",
    description="Processes extracted user data",
    params_json_schema=FunctionArgs.model_json_schema(),
    on_invoke_tool=run_function,
)
```

### 자동 인수 및 docstring 파싱

앞서 언급했듯이, 도구 스키마 추출을 위해 함수 시그니처를 자동 파싱하고, 도구 및 개별 인수 설명 추출을 위해 docstring을 파싱합니다. 참고 사항은 다음과 같습니다:

1. 시그니처 파싱은 `inspect` 모듈로 수행합니다. 인수 타입 이해를 위해 타입 애너테이션을 사용하며, 전체 스키마 표현을 위해 Pydantic 모델을 동적으로 생성합니다. Python 기본 타입, Pydantic 모델, TypedDict 등 대부분 타입을 지원합니다
2. docstring 파싱에는 `griffe`를 사용합니다. 지원되는 docstring 형식은 `google`, `sphinx`, `numpy`입니다. docstring 형식을 자동 감지하려고 시도하지만 최선의 노력 수준이며, `function_tool` 호출 시 명시적으로 설정할 수 있습니다. `use_docstring_info`를 `False`로 설정해 docstring 파싱을 비활성화할 수도 있습니다

스키마 추출 코드는 [`agents.function_schema`][]에 있습니다

### Pydantic Field를 사용한 인수 제약 및 설명

Pydantic의 [`Field`](https://docs.pydantic.dev/latest/concepts/fields/)를 사용해 도구 인수에 제약(예: 숫자의 min/max, 문자열 길이 또는 패턴)과 설명을 추가할 수 있습니다. Pydantic과 마찬가지로 두 형식을 모두 지원합니다: 기본값 기반(`arg: int = Field(..., ge=1)`)과 `Annotated`(`arg: Annotated[int, Field(..., ge=1)]`). 생성된 JSON 스키마와 검증에는 이러한 제약이 포함됩니다

```python
from typing import Annotated
from pydantic import Field
from agents import function_tool

# Default-based form
@function_tool
def score_a(score: int = Field(..., ge=0, le=100, description="Score from 0 to 100")) -> str:
    return f"Score recorded: {score}"

# Annotated form
@function_tool
def score_b(score: Annotated[int, Field(..., ge=0, le=100, description="Score from 0 to 100")]) -> str:
    return f"Score recorded: {score}"
```

### 함수 도구 타임아웃

`@function_tool(timeout=...)`로 async 함수 도구에 호출별 타임아웃을 설정할 수 있습니다

```python
import asyncio
from agents import Agent, Runner, function_tool


@function_tool(timeout=2.0)
async def slow_lookup(query: str) -> str:
    await asyncio.sleep(10)
    return f"Result for {query}"


agent = Agent(
    name="Timeout demo",
    instructions="Use tools when helpful.",
    tools=[slow_lookup],
)
```

타임아웃에 도달하면 기본 동작은 `timeout_behavior="error_as_result"`이며, 모델이 볼 수 있는 타임아웃 메시지(예: `Tool 'slow_lookup' timed out after 2 seconds.`)를 전송합니다

타임아웃 처리를 제어할 수 있습니다:

-   `timeout_behavior="error_as_result"` (기본값): 모델이 복구할 수 있도록 타임아웃 메시지를 반환합니다
-   `timeout_behavior="raise_exception"`: [`ToolTimeoutError`][agents.exceptions.ToolTimeoutError]를 발생시키고 실행을 실패 처리합니다
-   `timeout_error_function=...`: `error_as_result` 사용 시 타임아웃 메시지를 커스터마이즈합니다

```python
import asyncio
from agents import Agent, Runner, ToolTimeoutError, function_tool


@function_tool(timeout=1.5, timeout_behavior="raise_exception")
async def slow_tool() -> str:
    await asyncio.sleep(5)
    return "done"


agent = Agent(name="Timeout hard-fail", tools=[slow_tool])

try:
    await Runner.run(agent, "Run the tool")
except ToolTimeoutError as e:
    print(f"{e.tool_name} timed out in {e.timeout_seconds} seconds")
```

!!! note

    타임아웃 설정은 async `@function_tool` 핸들러에서만 지원됩니다

### 함수 도구의 오류 처리

`@function_tool`로 함수 도구를 만들 때 `failure_error_function`을 전달할 수 있습니다. 이는 도구 호출이 충돌할 경우 LLM에 오류 응답을 제공하는 함수입니다

-   기본값(즉, 아무것도 전달하지 않은 경우)으로는 `default_tool_error_function`이 실행되어 LLM에 오류 발생을 알립니다
-   사용자 정의 오류 함수를 전달하면 그 함수가 대신 실행되고, 해당 응답이 LLM으로 전송됩니다
-   명시적으로 `None`을 전달하면 도구 호출 오류가 다시 발생되어 사용자가 처리하게 됩니다. 이는 모델이 잘못된 JSON을 생성한 경우 `ModelBehaviorError`, 사용자 코드가 충돌한 경우 `UserError` 등이 될 수 있습니다

```python
from agents import function_tool, RunContextWrapper
from typing import Any

def my_custom_error_function(context: RunContextWrapper[Any], error: Exception) -> str:
    """A custom function to provide a user-friendly error message."""
    print(f"A tool call failed with the following error: {error}")
    return "An internal server error occurred. Please try again later."

@function_tool(failure_error_function=my_custom_error_function)
def get_user_profile(user_id: str) -> str:
    """Fetches a user profile from a mock API.
     This function demonstrates a 'flaky' or failing API call.
    """
    if user_id == "user_123":
        return "User profile for user_123 successfully retrieved."
    else:
        raise ValueError(f"Could not retrieve profile for user_id: {user_id}. API returned an error.")

```

`FunctionTool` 객체를 수동으로 생성하는 경우에는 `on_invoke_tool` 함수 내부에서 오류를 처리해야 합니다

## Agents as tools

일부 워크플로에서는 제어를 핸드오프하는 대신, 중앙 에이전트가 전문화된 에이전트 네트워크를 에이전트 오케스트레이션하도록 만들고 싶을 수 있습니다. 이를 위해 에이전트를 도구로 모델링할 수 있습니다

```python
from agents import Agent, Runner
import asyncio

spanish_agent = Agent(
    name="Spanish agent",
    instructions="You translate the user's message to Spanish",
)

french_agent = Agent(
    name="French agent",
    instructions="You translate the user's message to French",
)

orchestrator_agent = Agent(
    name="orchestrator_agent",
    instructions=(
        "You are a translation agent. You use the tools given to you to translate."
        "If asked for multiple translations, you call the relevant tools."
    ),
    tools=[
        spanish_agent.as_tool(
            tool_name="translate_to_spanish",
            tool_description="Translate the user's message to Spanish",
        ),
        french_agent.as_tool(
            tool_name="translate_to_french",
            tool_description="Translate the user's message to French",
        ),
    ],
)

async def main():
    result = await Runner.run(orchestrator_agent, input="Say 'Hello, how are you?' in Spanish.")
    print(result.final_output)
```

### 도구-에이전트 커스터마이징

`agent.as_tool` 함수는 에이전트를 도구로 쉽게 변환하도록 돕는 편의 메서드입니다. `max_turns`, `run_config`, `hooks`, `previous_response_id`, `conversation_id`, `session`, `needs_approval` 같은 일반적인 런타임 옵션을 지원합니다. 또한 `parameters`, `input_builder`, `include_input_schema`를 통한 구조화된 입력도 지원합니다. 고급 에이전트 오케스트레이션(예: 조건부 재시도, 폴백 동작, 여러 에이전트 호출 체이닝)의 경우 도구 구현에서 `Runner.run`을 직접 사용하세요:

```python
@function_tool
async def run_my_agent() -> str:
    """A tool that runs the agent with custom configs"""

    agent = Agent(name="My agent", instructions="...")

    result = await Runner.run(
        agent,
        input="...",
        max_turns=5,
        run_config=...
    )

    return str(result.final_output)
```

### 도구-에이전트용 구조화 입력

기본적으로 `Agent.as_tool()`은 단일 문자열 입력(`{"input": "..."}`)을 기대하지만, `parameters`(Pydantic 모델 또는 dataclass 타입)를 전달해 구조화된 스키마를 노출할 수 있습니다

추가 옵션:

- `include_input_schema=True`는 생성된 중첩 입력에 전체 JSON 스키마를 포함합니다
- `input_builder=...`는 구조화된 도구 인수가 중첩 에이전트 입력으로 변환되는 방식을 완전히 커스터마이즈할 수 있게 합니다
- `RunContextWrapper.tool_input`은 중첩 실행 컨텍스트 내부의 파싱된 구조화 payload를 포함합니다

```python
from pydantic import BaseModel, Field


class TranslationInput(BaseModel):
    text: str = Field(description="Text to translate.")
    source: str = Field(description="Source language.")
    target: str = Field(description="Target language.")


translator_tool = translator_agent.as_tool(
    tool_name="translate_text",
    tool_description="Translate text between languages.",
    parameters=TranslationInput,
    include_input_schema=True,
)
```

전체 실행 가능한 예시는 `examples/agent_patterns/agents_as_tools_structured.py`를 참조하세요

### 도구-에이전트용 승인 게이트

`Agent.as_tool(..., needs_approval=...)`는 `function_tool`과 동일한 승인 흐름을 사용합니다. 승인이 필요하면 실행이 일시 중지되고 대기 항목이 `result.interruptions`에 나타납니다. 그런 다음 `result.to_state()`를 사용하고 `state.approve(...)` 또는 `state.reject(...)` 호출 후 재개하세요. 전체 일시중지/재개 패턴은 [휴먼인더루프 (HITL) 가이드](human_in_the_loop.md)를 참조하세요

### 커스텀 출력 추출

특정 경우에는 중앙 에이전트로 반환하기 전에 도구-에이전트의 출력을 수정하고 싶을 수 있습니다. 다음이 필요할 때 유용합니다:

-   하위 에이전트 채팅 기록에서 특정 정보(예: JSON payload) 추출
-   에이전트의 최종 답변 변환 또는 재포맷(예: Markdown을 일반 텍스트 또는 CSV로 변환)
-   출력 검증 또는 에이전트 응답이 누락되었거나 잘못된 형식일 때 폴백 값 제공

이를 위해 `as_tool` 메서드에 `custom_output_extractor` 인수를 제공할 수 있습니다:

```python
async def extract_json_payload(run_result: RunResult) -> str:
    # Scan the agent’s outputs in reverse order until we find a JSON-like message from a tool call.
    for item in reversed(run_result.new_items):
        if isinstance(item, ToolCallOutputItem) and item.output.strip().startswith("{"):
            return item.output.strip()
    # Fallback to an empty JSON object if nothing was found
    return "{}"


json_tool = data_agent.as_tool(
    tool_name="get_data_json",
    tool_description="Run the data agent and return only its JSON payload",
    custom_output_extractor=extract_json_payload,
)
```

커스텀 추출기 내부에서 중첩된 [`RunResult`][agents.result.RunResult]는
[`agent_tool_invocation`][agents.result.RunResultBase.agent_tool_invocation]도 노출하며, 이는
중첩 결과 후처리 시 외부 도구 이름, 호출 ID 또는 원문 인수가 필요할 때 유용합니다
자세한 내용은 [결과 가이드](results.md#agent-as-tool-metadata)를 참조하세요

### 중첩 에이전트 실행 스트리밍

`as_tool`에 `on_stream` 콜백을 전달하면, 스트림 완료 후 최종 출력을 반환하면서 중첩 에이전트가 내보내는 스트리밍 이벤트를 수신할 수 있습니다

```python
from agents import AgentToolStreamEvent


async def handle_stream(event: AgentToolStreamEvent) -> None:
    # Inspect the underlying StreamEvent along with agent metadata.
    print(f"[stream] {event['agent'].name} :: {event['event'].type}")


billing_agent_tool = billing_agent.as_tool(
    tool_name="billing_helper",
    tool_description="Answer billing questions.",
    on_stream=handle_stream,  # Can be sync or async.
)
```

예상 동작:

- 이벤트 타입은 `StreamEvent["type"]`을 반영합니다: `raw_response_event`, `run_item_stream_event`, `agent_updated_stream_event`
- `on_stream`을 제공하면 중첩 에이전트가 자동으로 스트리밍 모드로 실행되며, 최종 출력 반환 전에 스트림을 소비합니다
- 핸들러는 동기 또는 비동기일 수 있으며, 각 이벤트는 도착 순서대로 전달됩니다
- 도구가 모델 도구 호출을 통해 호출되는 경우 `tool_call`이 존재하며, 직접 호출에서는 `None`일 수 있습니다
- 전체 실행 가능한 샘플은 `examples/agent_patterns/agents_as_tools_streaming.py`를 참조하세요

### 조건부 도구 활성화

`is_enabled` 매개변수를 사용해 런타임에서 에이전트 도구를 조건부로 활성화 또는 비활성화할 수 있습니다. 이를 통해 컨텍스트, 사용자 선호, 또는 런타임 조건에 따라 LLM에서 사용 가능한 도구를 동적으로 필터링할 수 있습니다

```python
import asyncio
from agents import Agent, AgentBase, Runner, RunContextWrapper
from pydantic import BaseModel

class LanguageContext(BaseModel):
    language_preference: str = "french_spanish"

def french_enabled(ctx: RunContextWrapper[LanguageContext], agent: AgentBase) -> bool:
    """Enable French for French+Spanish preference."""
    return ctx.context.language_preference == "french_spanish"

# Create specialized agents
spanish_agent = Agent(
    name="spanish_agent",
    instructions="You respond in Spanish. Always reply to the user's question in Spanish.",
)

french_agent = Agent(
    name="french_agent",
    instructions="You respond in French. Always reply to the user's question in French.",
)

# Create orchestrator with conditional tools
orchestrator = Agent(
    name="orchestrator",
    instructions=(
        "You are a multilingual assistant. You use the tools given to you to respond to users. "
        "You must call ALL available tools to provide responses in different languages. "
        "You never respond in languages yourself, you always use the provided tools."
    ),
    tools=[
        spanish_agent.as_tool(
            tool_name="respond_spanish",
            tool_description="Respond to the user's question in Spanish",
            is_enabled=True,  # Always enabled
        ),
        french_agent.as_tool(
            tool_name="respond_french",
            tool_description="Respond to the user's question in French",
            is_enabled=french_enabled,
        ),
    ],
)

async def main():
    context = RunContextWrapper(LanguageContext(language_preference="french_spanish"))
    result = await Runner.run(orchestrator, "How are you?", context=context.context)
    print(result.final_output)

asyncio.run(main())
```

`is_enabled` 매개변수는 다음을 허용합니다:

-   **불리언 값**: `True`(항상 활성화) 또는 `False`(항상 비활성화)
-   **호출 가능한 함수**: `(context, agent)`를 받아 불리언을 반환하는 함수
-   **비동기 함수**: 복잡한 조건 로직을 위한 async 함수

비활성화된 도구는 런타임에서 LLM에 완전히 숨겨지므로 다음에 유용합니다:

-   사용자 권한 기반 기능 게이팅
-   환경별 도구 가용성(dev vs prod)
-   서로 다른 도구 구성의 A/B 테스트
-   런타임 상태 기반 동적 도구 필터링

## 실험적 기능: Codex 도구

`codex_tool`은 Codex CLI를 래핑하여 에이전트가 도구 호출 중 워크스페이스 범위 작업(셸, 파일 편집, MCP 도구)을 실행할 수 있게 합니다. 이 표면은 실험적이며 변경될 수 있습니다

현재 실행을 벗어나지 않고 메인 에이전트가 경계가 있는 워크스페이스 작업을 Codex에 위임하도록 하려면 사용하세요. 기본 도구 이름은 `codex`입니다. 커스텀 이름을 설정하는 경우 `codex`이거나 `codex_`로 시작해야 합니다. 에이전트에 여러 Codex 도구를 포함할 때는 각각 고유한 이름을 사용해야 합니다

```python
from agents import Agent
from agents.extensions.experimental.codex import ThreadOptions, TurnOptions, codex_tool

agent = Agent(
    name="Codex Agent",
    instructions="Use the codex tool to inspect the workspace and answer the question.",
    tools=[
        codex_tool(
            sandbox_mode="workspace-write",
            working_directory="/path/to/repo",
            default_thread_options=ThreadOptions(
                model="gpt-5.2-codex",
                model_reasoning_effort="low",
                network_access_enabled=True,
                web_search_mode="disabled",
                approval_policy="never",
            ),
            default_turn_options=TurnOptions(
                idle_timeout_seconds=60,
            ),
            persist_session=True,
        )
    ],
)
```

다음 옵션 그룹부터 시작하세요:

-   실행 표면: `sandbox_mode`와 `working_directory`는 Codex가 동작할 위치를 정의합니다. 둘을 함께 설정하고, 작업 디렉터리가 Git 리포지토리 내부가 아니면 `skip_git_repo_check=True`를 설정하세요
-   스레드 기본값: `default_thread_options=ThreadOptions(...)`는 모델, reasoning effort, 승인 정책, 추가 디렉터리, 네트워크 액세스, 웹 검색 모드를 구성합니다. 레거시 `web_search_enabled` 대신 `web_search_mode`를 권장합니다
-   턴 기본값: `default_turn_options=TurnOptions(...)`는 `idle_timeout_seconds`와 선택적 취소 `signal` 같은 턴별 동작을 구성합니다
-   도구 I/O: 도구 호출에는 `{ "type": "text", "text": ... }` 또는 `{ "type": "local_image", "path": ... }` 형식의 `inputs` 항목이 최소 하나 포함되어야 합니다. `output_schema`를 사용하면 구조화된 Codex 응답을 요구할 수 있습니다

스레드 재사용과 영속성은 별도 제어입니다:

-   `persist_session=True`는 동일한 도구 인스턴스에 대한 반복 호출에서 하나의 Codex 스레드를 재사용합니다
-   `use_run_context_thread_id=True`는 동일한 가변 컨텍스트 객체를 공유하는 실행 간에 run context에 스레드 ID를 저장하고 재사용합니다
-   스레드 ID 우선순위는 호출별 `thread_id`, 그다음 run-context 스레드 ID(활성화된 경우), 그다음 구성된 `thread_id` 옵션입니다
-   기본 run-context 키는 `name="codex"`일 때 `codex_thread_id`, `name="codex_<suffix>"`일 때 `codex_thread_id_<suffix>`입니다. `run_context_thread_id_key`로 재정의할 수 있습니다

런타임 구성:

-   인증: `CODEX_API_KEY`(권장) 또는 `OPENAI_API_KEY`를 설정하거나 `codex_options={"api_key": "..."}`를 전달하세요
-   런타임: `codex_options.base_url`은 CLI 기본 URL을 재정의합니다
-   바이너리 확인: CLI 경로를 고정하려면 `codex_options.codex_path_override`(또는 `CODEX_PATH`)를 설정하세요. 그렇지 않으면 SDK가 `PATH`에서 `codex`를 확인하고, 이후 번들된 vendor 바이너리로 폴백합니다
-   환경: `codex_options.env`는 하위 프로세스 환경을 완전히 제어합니다. 이를 제공하면 하위 프로세스는 `os.environ`을 상속하지 않습니다
-   스트림 제한: `codex_options.codex_subprocess_stream_limit_bytes`(또는 `OPENAI_AGENTS_CODEX_SUBPROCESS_STREAM_LIMIT_BYTES`)는 stdout/stderr 리더 제한을 제어합니다. 유효 범위는 `65536`~`67108864`이며 기본값은 `8388608`입니다
-   스트리밍: `on_stream`은 스레드/턴 라이프사이클 이벤트와 항목 이벤트(`reasoning`, `command_execution`, `mcp_tool_call`, `file_change`, `web_search`, `todo_list`, `error` 항목 업데이트)를 수신합니다
-   출력: 결과에는 `response`, `usage`, `thread_id`가 포함되며, usage는 `RunContextWrapper.usage`에 추가됩니다

참고 자료:

-   [Codex 도구 API 레퍼런스](ref/extensions/experimental/codex/codex_tool.md)
-   [ThreadOptions 레퍼런스](ref/extensions/experimental/codex/thread_options.md)
-   [TurnOptions 레퍼런스](ref/extensions/experimental/codex/turn_options.md)
-   전체 실행 가능한 샘플은 `examples/tools/codex.py` 및 `examples/tools/codex_same_thread.py`를 참조하세요

================
File: docs/ko/tracing.md
================
---
search:
  exclude: true
---
# 트레이싱

Agents SDK에는 내장 트레이싱이 포함되어 있으며, 에이전트 실행 중 발생하는 이벤트(LLM 생성, 도구 호출, 핸드오프, 가드레일, 사용자 정의 이벤트 포함)의 포괄적인 기록을 수집합니다. [Traces dashboard](https://platform.openai.com/traces)를 사용하면 개발 중과 프로덕션에서 워크플로를 디버그, 시각화, 모니터링할 수 있습니다.

!!!note

    트레이싱은 기본적으로 활성화되어 있습니다. 일반적으로 다음 세 가지 방법으로 비활성화할 수 있습니다:

    1. 환경 변수 `OPENAI_AGENTS_DISABLE_TRACING=1`을 설정하여 전역적으로 트레이싱을 비활성화할 수 있습니다
    2. 코드에서 [`set_tracing_disabled(True)`][agents.set_tracing_disabled]를 사용해 전역적으로 트레이싱을 비활성화할 수 있습니다
    3. 단일 실행에 대해 [`agents.run.RunConfig.tracing_disabled`][]를 `True`로 설정하여 트레이싱을 비활성화할 수 있습니다

***OpenAI API를 사용하면서 Zero Data Retention(ZDR) 정책을 적용하는 조직의 경우, 트레이싱을 사용할 수 없습니다.***

## 트레이스와 스팬

-   **Traces**는 하나의 "워크플로"에 대한 단일 종단 간 작업을 나타냅니다. Traces는 Spans로 구성됩니다. Traces에는 다음 속성이 있습니다:
    -   `workflow_name`: 논리적 워크플로나 앱입니다. 예: "Code generation", "Customer service"
    -   `trace_id`: 트레이스의 고유 ID입니다. 전달하지 않으면 자동 생성됩니다. 형식은 `trace_<32_alphanumeric>`이어야 합니다
    -   `group_id`: 선택적 그룹 ID로, 동일한 대화의 여러 트레이스를 연결합니다. 예를 들어 채팅 스레드 ID를 사용할 수 있습니다
    -   `disabled`: True이면 트레이스가 기록되지 않습니다
    -   `metadata`: 트레이스용 선택적 메타데이터입니다
-   **Spans**는 시작 시점과 종료 시점이 있는 작업을 나타냅니다. Spans에는 다음이 있습니다:
    -   `started_at` 및 `ended_at` 타임스탬프
    -   `trace_id`: 해당 스팬이 속한 트레이스를 나타냅니다
    -   `parent_id`: 이 스팬의 상위 스팬(있는 경우)을 가리킵니다
    -   `span_data`: 스팬 관련 정보입니다. 예를 들어 `AgentSpanData`는 Agent 정보를, `GenerationSpanData`는 LLM 생성 정보를 포함합니다

## 기본 트레이싱

기본적으로 SDK는 다음을 트레이싱합니다:

-   전체 `Runner.{run, run_sync, run_streamed}()`는 `trace()`로 감싸집니다
-   에이전트가 실행될 때마다 `agent_span()`으로 감싸집니다
-   LLM 생성은 `generation_span()`으로 감싸집니다
-   함수 도구 호출은 각각 `function_span()`으로 감싸집니다
-   가드레일은 `guardrail_span()`으로 감싸집니다
-   핸드오프는 `handoff_span()`으로 감싸집니다
-   오디오 입력(음성-텍스트)은 `transcription_span()`으로 감싸집니다
-   오디오 출력(텍스트-음성)은 `speech_span()`으로 감싸집니다
-   관련 오디오 스팬은 `speech_group_span()` 하위로 중첩될 수 있습니다

기본적으로 트레이스 이름은 "Agent workflow"입니다. `trace`를 사용하면 이 이름을 설정할 수 있고, [`RunConfig`][agents.run.RunConfig]로 이름 및 기타 속성을 구성할 수도 있습니다.

또한 [사용자 정의 트레이스 프로세서](#custom-tracing-processors)를 설정하여 트레이스를 다른 대상으로 전송할 수 있습니다(대체 또는 보조 대상).

## 상위 수준 트레이스

경우에 따라 여러 `run()` 호출을 단일 트레이스의 일부로 만들고 싶을 수 있습니다. 이때 전체 코드를 `trace()`로 감싸면 됩니다.

```python
from agents import Agent, Runner, trace

async def main():
    agent = Agent(name="Joke generator", instructions="Tell funny jokes.")

    with trace("Joke workflow"): # (1)!
        first_result = await Runner.run(agent, "Tell me a joke")
        second_result = await Runner.run(agent, f"Rate this joke: {first_result.final_output}")
        print(f"Joke: {first_result.final_output}")
        print(f"Rating: {second_result.final_output}")
```

1. 두 번의 `Runner.run` 호출이 `with trace()`로 감싸져 있으므로, 각각의 실행은 별도 트레이스 2개를 만드는 대신 전체 트레이스의 일부가 됩니다

## 트레이스 생성

[`trace()`][agents.tracing.trace] 함수를 사용해 트레이스를 생성할 수 있습니다. 트레이스는 시작과 종료가 필요합니다. 방법은 두 가지입니다:

1. **권장**: `with trace(...) as my_trace`처럼 컨텍스트 매니저로 사용합니다. 이렇게 하면 적절한 시점에 트레이스가 자동으로 시작/종료됩니다
2. [`trace.start()`][agents.tracing.Trace.start] 및 [`trace.finish()`][agents.tracing.Trace.finish]를 수동으로 호출할 수도 있습니다

현재 트레이스는 Python [`contextvar`](https://docs.python.org/3/library/contextvars.html)로 추적됩니다. 즉, 동시성 환경에서도 자동으로 동작합니다. 트레이스를 수동 시작/종료하는 경우 현재 트레이스를 갱신하려면 `start()`/`finish()`에 `mark_as_current`와 `reset_current`를 전달해야 합니다.

## 스팬 생성

다양한 [`*_span()`][agents.tracing.create] 메서드를 사용해 스팬을 생성할 수 있습니다. 일반적으로 스팬을 수동 생성할 필요는 없습니다. 사용자 정의 스팬 정보 추적을 위해 [`custom_span()`][agents.tracing.custom_span] 함수가 제공됩니다.

스팬은 자동으로 현재 트레이스에 포함되며, Python [`contextvar`](https://docs.python.org/3/library/contextvars.html)로 추적되는 가장 가까운 현재 스팬 아래에 중첩됩니다.

## 민감한 데이터

일부 스팬은 잠재적으로 민감한 데이터를 캡처할 수 있습니다.

`generation_span()`은 LLM 생성의 입력/출력을 저장하고, `function_span()`은 함수 호출의 입력/출력을 저장합니다. 여기에 민감한 데이터가 포함될 수 있으므로 [`RunConfig.trace_include_sensitive_data`][agents.run.RunConfig.trace_include_sensitive_data]를 통해 해당 데이터 캡처를 비활성화할 수 있습니다.

마찬가지로 오디오 스팬에는 기본적으로 입력 및 출력 오디오에 대한 base64 인코딩 PCM 데이터가 포함됩니다. [`VoicePipelineConfig.trace_include_sensitive_audio_data`][agents.voice.pipeline_config.VoicePipelineConfig.trace_include_sensitive_audio_data]를 구성하여 이 오디오 데이터 캡처를 비활성화할 수 있습니다.

기본적으로 `trace_include_sensitive_data`는 `True`입니다. 앱 실행 전에 `OPENAI_AGENTS_TRACE_INCLUDE_SENSITIVE_DATA` 환경 변수를 `true/1` 또는 `false/0`으로 설정해 코드 변경 없이 기본값을 지정할 수 있습니다.

## 사용자 정의 트레이싱 프로세서

트레이싱의 상위 수준 아키텍처는 다음과 같습니다:

-   초기화 시 트레이스를 생성하는 역할을 하는 전역 [`TraceProvider`][agents.tracing.setup.TraceProvider]를 생성합니다
-   `TraceProvider`를 [`BatchTraceProcessor`][agents.tracing.processors.BatchTraceProcessor]로 구성하고, 이는 트레이스/스팬을 배치로 [`BackendSpanExporter`][agents.tracing.processors.BackendSpanExporter]에 전송하며, 해당 Exporter는 스팬과 트레이스를 배치로 OpenAI 백엔드로 내보냅니다

기본 설정을 사용자화하여 트레이스를 대체 또는 추가 백엔드로 전송하거나 exporter 동작을 수정하려면 두 가지 방법이 있습니다:

1. [`add_trace_processor()`][agents.tracing.add_trace_processor]를 사용하면 준비되는 즉시 트레이스와 스팬을 받는 **추가** 트레이스 프로세서를 더할 수 있습니다. 이를 통해 OpenAI 백엔드 전송과 별도로 자체 처리를 수행할 수 있습니다
2. [`set_trace_processors()`][agents.tracing.set_trace_processors]를 사용하면 기본 프로세서를 사용자 정의 트레이스 프로세서로 **대체**할 수 있습니다. 이 경우 해당 작업을 수행하는 `TracingProcessor`를 포함하지 않으면 트레이스는 OpenAI 백엔드로 전송되지 않습니다


## 비 OpenAI 모델에서의 트레이싱

비 OpenAI 모델에서도 OpenAI API 키를 사용해 트레이싱 비활성화 없이 OpenAI Traces dashboard에서 무료 트레이싱을 활성화할 수 있습니다.

```python
import os
from agents import set_tracing_export_api_key, Agent, Runner
from agents.extensions.models.litellm_model import LitellmModel

tracing_api_key = os.environ["OPENAI_API_KEY"]
set_tracing_export_api_key(tracing_api_key)

model = LitellmModel(
    model="your-model-name",
    api_key="your-api-key",
)

agent = Agent(
    name="Assistant",
    model=model,
)
```

단일 실행에 대해서만 다른 트레이싱 키가 필요하다면, 전역 exporter를 변경하는 대신 `RunConfig`를 통해 전달하세요.

```python
from agents import Runner, RunConfig

await Runner.run(
    agent,
    input="Hello",
    run_config=RunConfig(tracing={"api_key": "sk-tracing-123"}),
)
```

## 추가 참고 사항
- Openai Traces dashboard에서 무료 트레이스를 확인하세요


## 에코시스템 통합

다음 커뮤니티 및 벤더 통합은 OpenAI Agents SDK 트레이싱 표면을 지원합니다.

### 외부 트레이싱 프로세서 목록

-   [Weights & Biases](https://weave-docs.wandb.ai/guides/integrations/openai_agents)
-   [Arize-Phoenix](https://docs.arize.com/phoenix/tracing/integrations-tracing/openai-agents-sdk)
-   [Future AGI](https://docs.futureagi.com/future-agi/products/observability/auto-instrumentation/openai_agents)
-   [MLflow (self-hosted/OSS)](https://mlflow.org/docs/latest/tracing/integrations/openai-agent)
-   [MLflow (Databricks hosted)](https://docs.databricks.com/aws/en/mlflow/mlflow-tracing#-automatic-tracing)
-   [Braintrust](https://braintrust.dev/docs/guides/traces/integrations#openai-agents-sdk)
-   [Pydantic Logfire](https://logfire.pydantic.dev/docs/integrations/llms/openai/#openai-agents)
-   [AgentOps](https://docs.agentops.ai/v1/integrations/agentssdk)
-   [Scorecard](https://docs.scorecard.io/docs/documentation/features/tracing#openai-agents-sdk-integration)
-   [Keywords AI](https://docs.keywordsai.co/integration/development-frameworks/openai-agent)
-   [LangSmith](https://docs.smith.langchain.com/observability/how_to_guides/trace_with_openai_agents_sdk)
-   [Maxim AI](https://www.getmaxim.ai/docs/observe/integrations/openai-agents-sdk)
-   [Comet Opik](https://www.comet.com/docs/opik/tracing/integrations/openai_agents)
-   [Langfuse](https://langfuse.com/docs/integrations/openaiagentssdk/openai-agents)
-   [Langtrace](https://docs.langtrace.ai/supported-integrations/llm-frameworks/openai-agents-sdk)
-   [Okahu-Monocle](https://github.com/monocle2ai/monocle)
-   [Galileo](https://v2docs.galileo.ai/integrations/openai-agent-integration#openai-agent-integration)
-   [Portkey AI](https://portkey.ai/docs/integrations/agents/openai-agents)
-   [LangDB AI](https://docs.langdb.ai/getting-started/working-with-agent-frameworks/working-with-openai-agents-sdk)
-   [Agenta](https://docs.agenta.ai/observability/integrations/openai-agents)
-   [PostHog](https://posthog.com/docs/llm-analytics/installation/openai-agents)
-   [Traccia](https://traccia.ai/docs/integrations/openai-agents)

================
File: docs/ko/usage.md
================
---
search:
  exclude: true
---
# 사용량

Agents SDK는 모든 실행의 토큰 사용량을 자동으로 추적합니다. 실행 컨텍스트에서 이를 확인하여 비용 모니터링, 제한 적용, 분석 기록에 활용할 수 있습니다.

## 추적 항목

- **requests**: 수행된 LLM API 호출 수
- **input_tokens**: 전송된 전체 입력 토큰 수
- **output_tokens**: 수신된 전체 출력 토큰 수
- **total_tokens**: 입력 + 출력
- **request_usage_entries**: 요청별 사용량 상세 내역 목록
- **details**:
  - `input_tokens_details.cached_tokens`
  - `output_tokens_details.reasoning_tokens`

## 실행에서 사용량 접근

`Runner.run(...)` 이후 `result.context_wrapper.usage`를 통해 사용량에 접근할 수 있습니다.

```python
result = await Runner.run(agent, "What's the weather in Tokyo?")
usage = result.context_wrapper.usage

print("Requests:", usage.requests)
print("Input tokens:", usage.input_tokens)
print("Output tokens:", usage.output_tokens)
print("Total tokens:", usage.total_tokens)
```

사용량은 실행 중 발생한 모든 모델 호출(도구 호출 및 핸드오프 포함)에 대해 집계됩니다.

### LiteLLM 모델에서 사용량 활성화

LiteLLM provider는 기본적으로 사용량 메트릭을 보고하지 않습니다. [`LitellmModel`](models/litellm.md)을 사용하는 경우, 에이전트에 `ModelSettings(include_usage=True)`를 전달하여 LiteLLM 응답이 `result.context_wrapper.usage`를 채우도록 하세요.

```python
from agents import Agent, ModelSettings, Runner
from agents.extensions.models.litellm_model import LitellmModel

agent = Agent(
    name="Assistant",
    model=LitellmModel(model="your/model", api_key="..."),
    model_settings=ModelSettings(include_usage=True),
)

result = await Runner.run(agent, "What's the weather in Tokyo?")
print(result.context_wrapper.usage.total_tokens)
```

## 요청별 사용량 추적

SDK는 각 API 요청의 사용량을 `request_usage_entries`에서 자동으로 추적하므로, 상세한 비용 계산과 컨텍스트 윈도우 소비량 모니터링에 유용합니다.

```python
result = await Runner.run(agent, "What's the weather in Tokyo?")

for i, request in enumerate(result.context_wrapper.usage.request_usage_entries):
    print(f"Request {i + 1}: {request.input_tokens} in, {request.output_tokens} out")
```

## 세션에서 사용량 접근

`Session`(예: `SQLiteSession`)을 사용할 때 `Runner.run(...)`를 호출할 때마다 해당 실행에 대한 사용량이 반환됩니다. 세션은 컨텍스트를 위해 대화 기록을 유지하지만, 각 실행의 사용량은 서로 독립적입니다.

```python
session = SQLiteSession("my_conversation")

first = await Runner.run(agent, "Hi!", session=session)
print(first.context_wrapper.usage.total_tokens)  # Usage for first run

second = await Runner.run(agent, "Can you elaborate?", session=session)
print(second.context_wrapper.usage.total_tokens)  # Usage for second run
```

세션은 실행 간 대화 컨텍스트를 유지하지만, 각 `Runner.run()` 호출에서 반환되는 사용량 메트릭은 해당 실행만을 나타냅니다. 세션에서는 이전 메시지가 각 실행의 입력으로 다시 제공될 수 있으며, 이는 이후 턴의 입력 토큰 수에 영향을 줍니다.

## 훅에서 사용량 사용

`RunHooks`를 사용하는 경우, 각 훅에 전달되는 `context` 객체에 `usage`가 포함됩니다. 이를 통해 라이프사이클의 주요 시점에서 사용량을 로깅할 수 있습니다.

```python
class MyHooks(RunHooks):
    async def on_agent_end(self, context: RunContextWrapper, agent: Agent, output: Any) -> None:
        u = context.usage
        print(f"{agent.name} → {u.requests} requests, {u.total_tokens} total tokens")
```

## API 레퍼런스

자세한 API 문서는 다음을 참조하세요:

-   [`Usage`][agents.usage.Usage] - 사용량 추적 데이터 구조
-   [`RequestUsage`][agents.usage.RequestUsage] - 요청별 사용량 세부 정보
-   [`RunContextWrapper`][agents.run.RunContextWrapper] - 실행 컨텍스트에서 사용량 접근
-   [`RunHooks`][agents.run.RunHooks] - 사용량 추적 라이프사이클에 훅 연결

================
File: docs/ko/visualization.md
================
---
search:
  exclude: true
---
# 에이전트 시각화

에이전트 시각화를 사용하면 **Graphviz**를 통해 에이전트와 그 관계를 구조화된 그래픽 표현으로 생성할 수 있습니다. 이는 애플리케이션 내에서 에이전트, 도구, 핸드오프가 어떻게 상호작용하는지 이해하는 데 유용합니다.

## 설치

선택 사항인 `viz` 의존성 그룹을 설치하세요:

```bash
pip install "openai-agents[viz]"
```

## 그래프 생성

`draw_graph` 함수를 사용해 에이전트 시각화를 생성할 수 있습니다. 이 함수는 다음과 같은 방향 그래프를 만듭니다:

- **에이전트**는 노란색 상자로 표시됩니다
- **MCP 서버**는 회색 상자로 표시됩니다
- **도구**는 초록색 타원으로 표시됩니다
- **핸드오프**는 한 에이전트에서 다른 에이전트로 향하는 방향성 간선으로 표시됩니다

### 사용 예시

```python
import os

from agents import Agent, function_tool
from agents.mcp.server import MCPServerStdio
from agents.extensions.visualization import draw_graph

@function_tool
def get_weather(city: str) -> str:
    return f"The weather in {city} is sunny."

spanish_agent = Agent(
    name="Spanish agent",
    instructions="You only speak Spanish.",
)

english_agent = Agent(
    name="English agent",
    instructions="You only speak English",
)

current_dir = os.path.dirname(os.path.abspath(__file__))
samples_dir = os.path.join(current_dir, "sample_files")
mcp_server = MCPServerStdio(
    name="Filesystem Server, via npx",
    params={
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-filesystem", samples_dir],
    },
)

triage_agent = Agent(
    name="Triage agent",
    instructions="Handoff to the appropriate agent based on the language of the request.",
    handoffs=[spanish_agent, english_agent],
    tools=[get_weather],
    mcp_servers=[mcp_server],
)

draw_graph(triage_agent)
```

![Agent Graph](../assets/images/graph.png)

이렇게 하면 **triage agent**의 구조와 하위 에이전트 및 도구와의 연결을 시각적으로 나타내는 그래프가 생성됩니다.

## 시각화 이해

생성된 그래프에는 다음이 포함됩니다:

- 진입 지점을 나타내는 **시작 노드** (`__start__`)
- 노란색 채움의 **직사각형**으로 표시된 에이전트
- 초록색 채움의 **타원**으로 표시된 도구
- 회색 채움의 **직사각형**으로 표시된 MCP 서버
- 상호작용을 나타내는 방향성 간선:
  - 에이전트 간 핸드오프를 위한 **실선 화살표**
  - 도구 호출을 위한 **점선 화살표**
  - MCP 서버 호출을 위한 **파선 화살표**
- 실행이 종료되는 지점을 나타내는 **종료 노드** (`__end__`)

**참고:** MCP 서버는 `agents` 패키지의 최신 버전에서 렌더링됩니다(**v0.2.8**에서 확인됨). 시각화에서 MCP 상자가 보이지 않으면 최신 릴리스로 업그레이드하세요.

## 그래프 사용자 지정

### 그래프 표시
기본적으로 `draw_graph`는 그래프를 인라인으로 표시합니다. 그래프를 별도 창에서 표시하려면 다음과 같이 작성하세요:

```python
draw_graph(triage_agent).view()
```

### 그래프 저장
기본적으로 `draw_graph`는 그래프를 인라인으로 표시합니다. 파일로 저장하려면 파일명을 지정하세요:

```python
draw_graph(triage_agent, filename="agent_graph")
```

이렇게 하면 작업 디렉터리에 `agent_graph.png`가 생성됩니다.

================
File: docs/models/index.md
================
# Models

The Agents SDK comes with out-of-the-box support for OpenAI models in two flavors:

-   **Recommended**: the [`OpenAIResponsesModel`][agents.models.openai_responses.OpenAIResponsesModel], which calls OpenAI APIs using the new [Responses API](https://platform.openai.com/docs/api-reference/responses).
-   The [`OpenAIChatCompletionsModel`][agents.models.openai_chatcompletions.OpenAIChatCompletionsModel], which calls OpenAI APIs using the [Chat Completions API](https://platform.openai.com/docs/api-reference/chat).

## Choosing a model setup

Use this page in the following order depending on your setup:

| Goal | Start here |
| --- | --- |
| Use OpenAI-hosted models with SDK defaults | [OpenAI models](#openai-models) |
| Use OpenAI Responses API over websocket transport | [Responses WebSocket transport](#responses-websocket-transport) |
| Use non-OpenAI providers | [Non-OpenAI models](#non-openai-models) |
| Mix models/providers in one workflow | [Advanced model selection and mixing](#advanced-model-selection-and-mixing) and [Mixing models across providers](#mixing-models-across-providers) |
| Debug provider compatibility issues | [Troubleshooting non-OpenAI providers](#troubleshooting-non-openai-providers) |

## OpenAI models

When you don't specify a model when initializing an `Agent`, the default model will be used. The default is currently [`gpt-4.1`](https://platform.openai.com/docs/models/gpt-4.1) for compatibility and low latency. If you have access, we recommend setting your agents to [`gpt-5.2`](https://platform.openai.com/docs/models/gpt-5.2) for higher quality while keeping explicit `model_settings`.

If you want to switch to other models like [`gpt-5.2`](https://platform.openai.com/docs/models/gpt-5.2), there are two ways to configure your agents.

### Default model

First, if you want to consistently use a specific model for all agents that do not set a custom model, set the `OPENAI_DEFAULT_MODEL` environment variable before running your agents.

```bash
export OPENAI_DEFAULT_MODEL=gpt-5.2
python3 my_awesome_agent.py
```

Second, you can set a default model for a run via `RunConfig`. If you don't set a model for an agent, this run's model will be used.

```python
from agents import Agent, RunConfig, Runner

agent = Agent(
    name="Assistant",
    instructions="You're a helpful agent.",
)

result = await Runner.run(
    agent,
    "Hello",
    run_config=RunConfig(model="gpt-5.2"),
)
```

#### GPT-5.x models

When you use any GPT-5.x model such as [`gpt-5.2`](https://platform.openai.com/docs/models/gpt-5.2) in this way, the SDK applies default `ModelSettings`. It sets the ones that work the best for most use cases. To adjust the reasoning effort for the default model, pass your own `ModelSettings`:

```python
from openai.types.shared import Reasoning
from agents import Agent, ModelSettings

my_agent = Agent(
    name="My Agent",
    instructions="You're a helpful agent.",
    # If OPENAI_DEFAULT_MODEL=gpt-5.2 is set, passing only model_settings works.
    # It's also fine to pass a GPT-5.x model name explicitly:
    model="gpt-5.2",
    model_settings=ModelSettings(reasoning=Reasoning(effort="high"), verbosity="low")
)
```

For lower latency, using `reasoning.effort="none"` with `gpt-5.2` is recommended. The gpt-4.1 family (including mini and nano variants) also remains a solid choice for building interactive agent apps.

#### Non-GPT-5 models

If you pass a non–GPT-5 model name without custom `model_settings`, the SDK reverts to generic `ModelSettings` compatible with any model.

### Responses WebSocket transport

By default, OpenAI Responses API requests use HTTP transport. You can opt in to websocket transport when using OpenAI-backed models.

```python
from agents import set_default_openai_responses_transport

set_default_openai_responses_transport("websocket")
```

This affects OpenAI Responses models resolved by the default OpenAI provider (including string model names such as `"gpt-5.2"`).

Transport selection happens when the SDK resolves a model name into a model instance. If you pass a concrete [`Model`][agents.models.interface.Model] object, its transport is already fixed: [`OpenAIResponsesWSModel`][agents.models.openai_responses.OpenAIResponsesWSModel] uses websocket, [`OpenAIResponsesModel`][agents.models.openai_responses.OpenAIResponsesModel] uses HTTP, and [`OpenAIChatCompletionsModel`][agents.models.openai_chatcompletions.OpenAIChatCompletionsModel] stays on Chat Completions. If you pass `RunConfig(model_provider=...)`, that provider controls transport selection instead of the global default.

You can also configure websocket transport per provider or per run:

```python
from agents import Agent, OpenAIProvider, RunConfig, Runner

provider = OpenAIProvider(
    use_responses_websocket=True,
    # Optional; if omitted, OPENAI_WEBSOCKET_BASE_URL is used when set.
    websocket_base_url="wss://your-proxy.example/v1",
)

agent = Agent(name="Assistant")
result = await Runner.run(
    agent,
    "Hello",
    run_config=RunConfig(model_provider=provider),
)
```

If you need prefix-based model routing (for example mixing `openai/...` and `litellm/...` model names in one run), use [`MultiProvider`][agents.MultiProvider] and set `openai_use_responses_websocket=True` there instead.

If you use a custom OpenAI-compatible endpoint or proxy, websocket transport also requires a compatible websocket `/responses` endpoint. In those setups you may need to set `websocket_base_url` explicitly.

Notes:

-   This is the Responses API over websocket transport, not the [Realtime API](../realtime/guide.md). It does not apply to Chat Completions or non-OpenAI providers unless they support the Responses websocket `/responses` endpoint.
-   Install the `websockets` package if it is not already available in your environment.
-   You can use [`Runner.run_streamed()`][agents.run.Runner.run_streamed] directly after enabling websocket transport. For multi-turn workflows where you want to reuse the same websocket connection across turns (and nested agent-as-tool calls), the [`responses_websocket_session()`][agents.responses_websocket_session] helper is recommended. See the [Running agents](../running_agents.md) guide and [`examples/basic/stream_ws.py`](https://github.com/openai/openai-agents-python/tree/main/examples/basic/stream_ws.py).

## Non-OpenAI models

You can use most other non-OpenAI models via the [LiteLLM integration](./litellm.md). First, install the litellm dependency group:

```bash
pip install "openai-agents[litellm]"
```

Then, use any of the [supported models](https://docs.litellm.ai/docs/providers) with the `litellm/` prefix:

```python
claude_agent = Agent(model="litellm/anthropic/claude-3-5-sonnet-20240620", ...)
gemini_agent = Agent(model="litellm/gemini/gemini-2.5-flash-preview-04-17", ...)
```

### Other ways to use non-OpenAI models

You can integrate other LLM providers in 3 more ways (examples [here](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/)):

1. [`set_default_openai_client`][agents.set_default_openai_client] is useful in cases where you want to globally use an instance of `AsyncOpenAI` as the LLM client. This is for cases where the LLM provider has an OpenAI compatible API endpoint, and you can set the `base_url` and `api_key`. See a configurable example in [examples/model_providers/custom_example_global.py](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/custom_example_global.py).
2. [`ModelProvider`][agents.models.interface.ModelProvider] is at the `Runner.run` level. This lets you say "use a custom model provider for all agents in this run". See a configurable example in [examples/model_providers/custom_example_provider.py](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/custom_example_provider.py).
3. [`Agent.model`][agents.agent.Agent.model] lets you specify the model on a specific Agent instance. This enables you to mix and match different providers for different agents. See a configurable example in [examples/model_providers/custom_example_agent.py](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/custom_example_agent.py). An easy way to use most available models is via the [LiteLLM integration](./litellm.md).

In cases where you do not have an API key from `platform.openai.com`, we recommend disabling tracing via `set_tracing_disabled()`, or setting up a [different tracing processor](../tracing.md).

!!! note

    In these examples, we use the Chat Completions API/model, because most LLM providers don't yet support the Responses API. If your LLM provider does support it, we recommend using Responses.

## Advanced model selection and mixing

Within a single workflow, you may want to use different models for each agent. For example, you could use a smaller, faster model for triage, while using a larger, more capable model for complex tasks. When configuring an [`Agent`][agents.Agent], you can select a specific model by either:

1. Passing the name of a model.
2. Passing any model name + a [`ModelProvider`][agents.models.interface.ModelProvider] that can map that name to a Model instance.
3. Directly providing a [`Model`][agents.models.interface.Model] implementation.

!!!note

    While our SDK supports both the [`OpenAIResponsesModel`][agents.models.openai_responses.OpenAIResponsesModel] and the [`OpenAIChatCompletionsModel`][agents.models.openai_chatcompletions.OpenAIChatCompletionsModel] shapes, we recommend using a single model shape for each workflow because the two shapes support a different set of features and tools. If your workflow requires mixing and matching model shapes, make sure that all the features you're using are available on both.

```python
from agents import Agent, Runner, AsyncOpenAI, OpenAIChatCompletionsModel
import asyncio

spanish_agent = Agent(
    name="Spanish agent",
    instructions="You only speak Spanish.",
    model="gpt-5-mini", # (1)!
)

english_agent = Agent(
    name="English agent",
    instructions="You only speak English",
    model=OpenAIChatCompletionsModel( # (2)!
        model="gpt-5-nano",
        openai_client=AsyncOpenAI()
    ),
)

triage_agent = Agent(
    name="Triage agent",
    instructions="Handoff to the appropriate agent based on the language of the request.",
    handoffs=[spanish_agent, english_agent],
    model="gpt-5",
)

async def main():
    result = await Runner.run(triage_agent, input="Hola, ¿cómo estás?")
    print(result.final_output)
```

1.  Sets the name of an OpenAI model directly.
2.  Provides a [`Model`][agents.models.interface.Model] implementation.

When you want to further configure the model used for an agent, you can pass [`ModelSettings`][agents.models.interface.ModelSettings], which provides optional model configuration parameters such as temperature.

```python
from agents import Agent, ModelSettings

english_agent = Agent(
    name="English agent",
    instructions="You only speak English",
    model="gpt-4.1",
    model_settings=ModelSettings(temperature=0.1),
)
```

#### Common advanced `ModelSettings` options

When you are using the OpenAI Responses API, several request fields already have direct `ModelSettings` fields, so you do not need `extra_args` for them.

| Field | Use it for |
| --- | --- |
| `parallel_tool_calls` | Allow or forbid multiple tool calls in the same turn. |
| `truncation` | Set `"auto"` to let the Responses API drop the oldest conversation items instead of failing when context would overflow. |
| `prompt_cache_retention` | Keep cached prompt prefixes around longer, for example with `"24h"`. |
| `response_include` | Request richer response payloads such as `web_search_call.action.sources`, `file_search_call.results`, or `reasoning.encrypted_content`. |
| `top_logprobs` | Request top-token logprobs for output text. The SDK also adds `message.output_text.logprobs` automatically. |

```python
from agents import Agent, ModelSettings

research_agent = Agent(
    name="Research agent",
    model="gpt-5.2",
    model_settings=ModelSettings(
        parallel_tool_calls=False,
        truncation="auto",
        prompt_cache_retention="24h",
        response_include=["web_search_call.action.sources"],
        top_logprobs=5,
    ),
)
```

Use `extra_args` when you need provider-specific or newer request fields that the SDK does not expose directly at the top level yet.

Also, when you use OpenAI's Responses API, [there are a few other optional parameters](https://platform.openai.com/docs/api-reference/responses/create) (e.g., `user`, `service_tier`, and so on). If they are not available at the top level, you can use `extra_args` to pass them as well.

```python
from agents import Agent, ModelSettings

english_agent = Agent(
    name="English agent",
    instructions="You only speak English",
    model="gpt-4.1",
    model_settings=ModelSettings(
        temperature=0.1,
        extra_args={"service_tier": "flex", "user": "user_12345"},
    ),
)
```

## Troubleshooting non-OpenAI providers

### Tracing client error 401

If you get errors related to tracing, this is because traces are uploaded to OpenAI servers, and you don't have an OpenAI API key. You have three options to resolve this:

1. Disable tracing entirely: [`set_tracing_disabled(True)`][agents.set_tracing_disabled].
2. Set an OpenAI key for tracing: [`set_tracing_export_api_key(...)`][agents.set_tracing_export_api_key]. This API key will only be used for uploading traces, and must be from [platform.openai.com](https://platform.openai.com/).
3. Use a non-OpenAI trace processor. See the [tracing docs](../tracing.md#custom-tracing-processors).

### Responses API support

The SDK uses the Responses API by default, but most other LLM providers don't yet support it. You may see 404s or similar issues as a result. To resolve, you have two options:

1. Call [`set_default_openai_api("chat_completions")`][agents.set_default_openai_api]. This works if you are setting `OPENAI_API_KEY` and `OPENAI_BASE_URL` via environment vars.
2. Use [`OpenAIChatCompletionsModel`][agents.models.openai_chatcompletions.OpenAIChatCompletionsModel]. There are examples [here](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/).

### Structured outputs support

Some model providers don't have support for [structured outputs](https://platform.openai.com/docs/guides/structured-outputs). This sometimes results in an error that looks something like this:

```

BadRequestError: Error code: 400 - {'error': {'message': "'response_format.type' : value is not one of the allowed values ['text','json_object']", 'type': 'invalid_request_error'}}

```

This is a shortcoming of some model providers - they support JSON outputs, but don't allow you to specify the `json_schema` to use for the output. We are working on a fix for this, but we suggest relying on providers that do have support for JSON schema output, because otherwise your app will often break because of malformed JSON.

## Mixing models across providers

You need to be aware of feature differences between model providers, or you may run into errors. For example, OpenAI supports structured outputs, multimodal input, and hosted file search and web search, but many other providers don't support these features. Be aware of these limitations:

-   Don't send unsupported `tools` to providers that don't understand them
-   Filter out multimodal inputs before calling models that are text-only
-   Be aware that providers that don't support structured JSON outputs will occasionally produce invalid JSON.

================
File: docs/models/litellm.md
================
# Using any model via LiteLLM

!!! note

    The LiteLLM integration is in beta. You may run into issues with some model providers, especially smaller ones. Please report any issues via [Github issues](https://github.com/openai/openai-agents-python/issues) and we'll fix quickly.

[LiteLLM](https://docs.litellm.ai/docs/) is a library that allows you to use 100+ models via a single interface. We've added a LiteLLM integration to allow you to use any AI model in the Agents SDK.

## Setup

You'll need to ensure `litellm` is available. You can do this by installing the optional `litellm` dependency group:

```bash
pip install "openai-agents[litellm]"
```

Once done, you can use [`LitellmModel`][agents.extensions.models.litellm_model.LitellmModel] in any agent.

## Example

This is a fully working example. When you run it, you'll be prompted for a model name and API key. For example, you could enter:

-   `openai/gpt-4.1` for the model, and your OpenAI API key
-   `anthropic/claude-3-5-sonnet-20240620` for the model, and your Anthropic API key
-   etc

For a full list of models supported in LiteLLM, see the [litellm providers docs](https://docs.litellm.ai/docs/providers).

```python
from __future__ import annotations

import asyncio

from agents import Agent, Runner, function_tool, set_tracing_disabled
from agents.extensions.models.litellm_model import LitellmModel

@function_tool
def get_weather(city: str):
    print(f"[debug] getting weather for {city}")
    return f"The weather in {city} is sunny."


async def main(model: str, api_key: str):
    agent = Agent(
        name="Assistant",
        instructions="You only respond in haikus.",
        model=LitellmModel(model=model, api_key=api_key),
        tools=[get_weather],
    )

    result = await Runner.run(agent, "What's the weather in Tokyo?")
    print(result.final_output)


if __name__ == "__main__":
    # First try to get model/api key from args
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--model", type=str, required=False)
    parser.add_argument("--api-key", type=str, required=False)
    args = parser.parse_args()

    model = args.model
    if not model:
        model = input("Enter a model name for Litellm: ")

    api_key = args.api_key
    if not api_key:
        api_key = input("Enter an API key for Litellm: ")

    asyncio.run(main(model, api_key))
```

## Tracking usage data

If you want LiteLLM responses to populate the Agents SDK usage metrics, pass `ModelSettings(include_usage=True)` when creating your agent.

```python
from agents import Agent, ModelSettings
from agents.extensions.models.litellm_model import LitellmModel

agent = Agent(
    name="Assistant",
    model=LitellmModel(model="your/model", api_key="..."),
    model_settings=ModelSettings(include_usage=True),
)
```

With `include_usage=True`, LiteLLM requests report token and request counts through `result.context_wrapper.usage` just like the built-in OpenAI models.

## Troubleshooting

If you see Pydantic serializer warnings from LiteLLM responses, enable a small compatibility patch by setting:

```bash
export OPENAI_AGENTS_ENABLE_LITELLM_SERIALIZER_PATCH=true
```

This opt-in flag suppresses known LiteLLM serializer warnings while preserving normal behavior. Turn it off (unset or `false`) if you do not need it.

================
File: docs/realtime/guide.md
================
# Realtime agents guide

This guide explains how the OpenAI Agents SDK's realtime layer maps onto the OpenAI Realtime API, and what extra behavior the Python SDK adds on top.

!!! warning "Beta feature"

    Realtime agents are in beta. Expect some breaking changes as we improve the implementation.

!!! note "Start here"

    If you want the default Python path, read the [quickstart](quickstart.md) first. If you are deciding whether your app should use server-side WebSocket or SIP, read [Realtime transport](transport.md). Browser WebRTC transport is not part of the Python SDK.

## Overview

Realtime agents keep a long-lived connection open to the Realtime API so the model can process text and audio incrementally, stream audio output, call tools, and handle interruptions without restarting a fresh request on every turn.

The main SDK components are:

-   **RealtimeAgent**: Instructions, tools, output guardrails, and handoffs for one realtime specialist
-   **RealtimeRunner**: Session factory that wires a starting agent to a realtime transport
-   **RealtimeSession**: A live session that sends input, receives events, tracks history, and executes tools
-   **RealtimeModel**: The transport abstraction. The default is OpenAI's server-side WebSocket implementation.

## Session lifecycle

A typical realtime session looks like this:

1. Create one or more `RealtimeAgent`s.
2. Create a `RealtimeRunner` with the starting agent.
3. Call `await runner.run()` to get a `RealtimeSession`.
4. Enter the session with `async with session:` or `await session.enter()`.
5. Send user input with `send_message()` or `send_audio()`.
6. Iterate over session events until the conversation ends.

Unlike text-only runs, `runner.run()` does not produce a final result immediately. It returns a live session object that keeps local history, background tool execution, guardrail state, and the active agent configuration in sync with the transport layer.

By default, `RealtimeRunner` uses `OpenAIRealtimeWebSocketModel`, so the default Python path is a server-side WebSocket connection to the Realtime API. If you pass a different `RealtimeModel`, the same session lifecycle and agent features still apply, while the connection mechanics can change.

## Agent and session configuration

`RealtimeAgent` is intentionally narrower than the regular `Agent` type:

-   Model choice is configured at the session level, not per agent.
-   Structured outputs are not supported.
-   Voice can be configured, but it cannot change after the session has already produced spoken audio.
-   Instructions, function tools, handoffs, hooks, and output guardrails all still work.

`RealtimeSessionModelSettings` supports both a newer nested `audio` config and older flat aliases. Prefer the nested shape for new code:

```python
runner = RealtimeRunner(
    starting_agent=agent,
    config={
        "model_settings": {
            "model_name": "gpt-realtime",
            "audio": {
                "input": {
                    "format": "pcm16",
                    "transcription": {"model": "gpt-4o-mini-transcribe"},
                    "turn_detection": {"type": "semantic_vad", "interrupt_response": True},
                },
                "output": {"format": "pcm16", "voice": "ash"},
            },
            "tool_choice": "auto",
        }
    },
)
```

Useful session-level settings include:

-   `audio.input.format`, `audio.output.format`
-   `audio.input.transcription`
-   `audio.input.noise_reduction`
-   `audio.input.turn_detection`
-   `audio.output.voice`, `audio.output.speed`
-   `output_modalities`
-   `tool_choice`
-   `prompt`
-   `tracing`

Useful run-level settings on `RealtimeRunner(config=...)` include:

-   `async_tool_calls`
-   `output_guardrails`
-   `guardrails_settings.debounce_text_length`
-   `tool_error_formatter`
-   `tracing_disabled`

See [`RealtimeRunConfig`][agents.realtime.config.RealtimeRunConfig] and [`RealtimeSessionModelSettings`][agents.realtime.config.RealtimeSessionModelSettings] for the full typed surface.

## Inputs and outputs

### Text and structured user messages

Use [`session.send_message()`][agents.realtime.session.RealtimeSession.send_message] for plain text or structured realtime messages.

```python
from agents.realtime import RealtimeUserInputMessage

await session.send_message("Summarize what we discussed so far.")

message: RealtimeUserInputMessage = {
    "type": "message",
    "role": "user",
    "content": [
        {"type": "input_text", "text": "Describe this image."},
        {"type": "input_image", "image_url": image_data_url, "detail": "high"},
    ],
}
await session.send_message(message)
```

Structured messages are the main way to include image input in a realtime conversation. The example web demo in [`examples/realtime/app/server.py`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/app/server.py) forwards `input_image` messages this way.

### Audio input

Use [`session.send_audio()`][agents.realtime.session.RealtimeSession.send_audio] to stream raw audio bytes:

```python
await session.send_audio(audio_bytes)
```

If server-side turn detection is disabled, you are responsible for marking turn boundaries. The high-level convenience is:

```python
await session.send_audio(audio_bytes, commit=True)
```

If you need lower-level control, you can also send raw client events such as `input_audio_buffer.commit` through the underlying model transport.

### Manual response control

`session.send_message()` sends user input using the high-level path and starts a response for you. Raw audio buffering does **not** automatically do the same in every configuration.

At the Realtime API level, manual turn control means clearing `turn_detection` with a raw `session.update`, then sending `input_audio_buffer.commit` and `response.create` yourself.

If you are managing turns manually, you can send raw client events through the model transport:

```python
from agents.realtime.model_inputs import RealtimeModelSendRawMessage

await session.model.send_event(
    RealtimeModelSendRawMessage(
        message={
            "type": "response.create",
        }
    )
)
```

This pattern is useful when:

-   `turn_detection` is disabled and you want to decide when the model should respond
-   you want to inspect or gate user input before triggering a response
-   you need a custom prompt for an out-of-band response

The SIP example in [`examples/realtime/twilio_sip/server.py`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/twilio_sip/server.py) uses a raw `response.create` to force an opening greeting.

## Events, history, and interruptions

`RealtimeSession` emits higher-level SDK events while still forwarding raw model events when you need them.

High-value session events include:

-   `audio`, `audio_end`, `audio_interrupted`
-   `agent_start`, `agent_end`
-   `tool_start`, `tool_end`, `tool_approval_required`
-   `handoff`
-   `history_added`, `history_updated`
-   `guardrail_tripped`
-   `input_audio_timeout_triggered`
-   `error`
-   `raw_model_event`

The most useful events for UI state are usually `history_added` and `history_updated`. They expose the session's local history as `RealtimeItem` objects, including user messages, assistant messages, and tool calls.

### Interruptions and playback tracking

When the user interrupts the assistant, the session emits `audio_interrupted` and updates history so the server-side conversation stays aligned with what the user actually heard.

In low-latency local playback, the default playback tracker is often enough. In remote or delayed playback scenarios, especially telephony, use [`RealtimePlaybackTracker`][agents.realtime.model.RealtimePlaybackTracker] so interruption truncation is based on actual playback progress rather than assuming all generated audio has already been heard.

The Twilio example in [`examples/realtime/twilio/twilio_handler.py`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/twilio/twilio_handler.py) shows this pattern.

## Tools, approvals, handoffs, and guardrails

### Function tools

Realtime agents support function tools during live conversations:

```python
from agents import function_tool


@function_tool
def get_weather(city: str) -> str:
    """Get current weather for a city."""
    return f"The weather in {city} is sunny, 72F."


agent = RealtimeAgent(
    name="Assistant",
    instructions="You can answer weather questions.",
    tools=[get_weather],
)
```

### Tool approvals

Function tools can require human approval before execution. When that happens, the session emits `tool_approval_required` and pauses the tool run until you call `approve_tool_call()` or `reject_tool_call()`.

```python
async for event in session:
    if event.type == "tool_approval_required":
        await session.approve_tool_call(event.call_id)
```

For a concrete server-side approval loop, see [`examples/realtime/app/server.py`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/app/server.py). The human-in-the-loop docs also point back to this flow in [Human in the loop](../human_in_the_loop.md).

### Handoffs

Realtime handoffs let one agent transfer the live conversation to another specialist:

```python
from agents.realtime import RealtimeAgent, realtime_handoff

billing_agent = RealtimeAgent(
    name="Billing Support",
    instructions="You specialize in billing issues.",
)

main_agent = RealtimeAgent(
    name="Customer Service",
    instructions="Triage the request and hand off when needed.",
    handoffs=[realtime_handoff(billing_agent, tool_description="Transfer to billing support")],
)
```

Bare `RealtimeAgent` handoffs are auto-wrapped, and `realtime_handoff(...)` lets you customize names, descriptions, validation, callbacks, and availability. Realtime handoffs do **not** support the regular handoff `input_filter`.

### Guardrails

Only output guardrails are supported for realtime agents. They run on debounced transcript accumulation rather than on every partial token, and they emit `guardrail_tripped` instead of raising an exception.

```python
from agents.guardrail import GuardrailFunctionOutput, OutputGuardrail


def sensitive_data_check(context, agent, output):
    return GuardrailFunctionOutput(
        tripwire_triggered="password" in output,
        output_info=None,
    )


agent = RealtimeAgent(
    name="Assistant",
    instructions="...",
    output_guardrails=[OutputGuardrail(guardrail_function=sensitive_data_check)],
)
```

## SIP and telephony

The Python SDK includes a first-class SIP attach flow via [`OpenAIRealtimeSIPModel`][agents.realtime.openai_realtime.OpenAIRealtimeSIPModel].

Use it when a call arrives through the Realtime Calls API and you want to attach an agent session to the resulting `call_id`:

```python
from agents.realtime import RealtimeRunner
from agents.realtime.openai_realtime import OpenAIRealtimeSIPModel

runner = RealtimeRunner(starting_agent=agent, model=OpenAIRealtimeSIPModel())

async with await runner.run(
    model_config={
        "call_id": call_id_from_webhook,
    }
) as session:
    async for event in session:
        ...
```

If you need to accept the call first and want the accept payload to match the agent-derived session configuration, use `OpenAIRealtimeSIPModel.build_initial_session_payload(...)`. The complete flow is shown in [`examples/realtime/twilio_sip/server.py`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/twilio_sip/server.py).

## Low-level access and custom endpoints

You can access the underlying transport object through `session.model`.

Use this when you need:

-   custom listeners via `session.model.add_listener(...)`
-   raw client events such as `response.create` or `session.update`
-   custom `url`, `headers`, or `api_key` handling through `model_config`
-   `call_id` attach to an existing realtime call

`RealtimeModelConfig` supports:

-   `api_key`
-   `url`
-   `headers`
-   `initial_model_settings`
-   `playback_tracker`
-   `call_id`

This repository's shipped `call_id` example is SIP. The broader Realtime API also uses `call_id` for some server-side control flows, but those are not packaged as Python examples here.

When connecting to Azure OpenAI, pass a GA Realtime endpoint URL and explicit headers. For example:

```python
session = await runner.run(
    model_config={
        "url": "wss://<your-resource>.openai.azure.com/openai/v1/realtime?model=<deployment-name>",
        "headers": {"api-key": "<your-azure-api-key>"},
    }
)
```

For token-based authentication, use a bearer token in `headers`:

```python
session = await runner.run(
    model_config={
        "url": "wss://<your-resource>.openai.azure.com/openai/v1/realtime?model=<deployment-name>",
        "headers": {"authorization": f"Bearer {token}"},
    }
)
```

If you pass `headers`, the SDK does not add `Authorization` automatically. Avoid the legacy beta path (`/openai/realtime?api-version=...`) with realtime agents.

## Further reading

-   [Realtime transport](transport.md)
-   [Quickstart](quickstart.md)
-   [OpenAI Realtime conversations](https://developers.openai.com/api/docs/guides/realtime-conversations/)
-   [OpenAI Realtime server-side controls](https://developers.openai.com/api/docs/guides/realtime-server-controls/)
-   [`examples/realtime`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime)

================
File: docs/realtime/quickstart.md
================
# Quickstart

Realtime agents in the Python SDK are server-side, low-latency agents built on the OpenAI Realtime API over WebSocket transport.

!!! warning "Beta feature"

    Realtime agents are in beta. Expect some breaking changes as we improve the implementation.

!!! note "Python SDK boundary"

    The Python SDK does **not** provide a browser WebRTC transport. This page only covers Python-managed realtime sessions over server-side WebSockets. Use this SDK for server-side orchestration, tools, approvals, and telephony integrations. See also [Realtime transport](transport.md).

## Prerequisites

-   Python 3.10 or higher
-   OpenAI API key
-   Basic familiarity with the OpenAI Agents SDK

## Installation

If you haven't already, install the OpenAI Agents SDK:

```bash
pip install openai-agents
```

## Create a server-side realtime session

### 1. Import the realtime components

```python
import asyncio

from agents.realtime import RealtimeAgent, RealtimeRunner
```

### 2. Define the starting agent

```python
agent = RealtimeAgent(
    name="Assistant",
    instructions="You are a helpful voice assistant. Keep responses short and conversational.",
)
```

### 3. Configure the runner

Prefer the nested `audio.input` / `audio.output` session settings shape for new code.

```python
runner = RealtimeRunner(
    starting_agent=agent,
    config={
        "model_settings": {
            "model_name": "gpt-realtime",
            "audio": {
                "input": {
                    "format": "pcm16",
                    "transcription": {"model": "gpt-4o-mini-transcribe"},
                    "turn_detection": {
                        "type": "semantic_vad",
                        "interrupt_response": True,
                    },
                },
                "output": {
                    "format": "pcm16",
                    "voice": "ash",
                },
            },
        }
    },
)
```

### 4. Start the session and send input

`runner.run()` returns a `RealtimeSession`. The connection is opened when you enter the session context.

```python
async def main() -> None:
    session = await runner.run()

    async with session:
        await session.send_message("Say hello in one short sentence.")

        async for event in session:
            if event.type == "audio":
                # Forward or play event.audio.data.
                pass
            elif event.type == "history_added":
                print(event.item)
            elif event.type == "agent_end":
                # One assistant turn finished.
                break
            elif event.type == "error":
                print(f"Error: {event.error}")


if __name__ == "__main__":
    asyncio.run(main())
```

`session.send_message()` accepts either a plain string or a structured realtime message. For raw audio chunks, use [`session.send_audio()`][agents.realtime.session.RealtimeSession.send_audio].

## What this quickstart does not include

-   Microphone capture and speaker playback code. See the realtime examples in [`examples/realtime`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime).
-   SIP / telephony attach flows. See [Realtime transport](transport.md) and the [SIP section](guide.md#sip-and-telephony).

## Key settings

Once the basic session works, the settings most people reach for next are:

-   `model_name`
-   `audio.input.format`, `audio.output.format`
-   `audio.input.transcription`
-   `audio.input.noise_reduction`
-   `audio.input.turn_detection` for automatic turn detection
-   `audio.output.voice`
-   `tool_choice`, `prompt`, `tracing`
-   `async_tool_calls`, `guardrails_settings.debounce_text_length`, `tool_error_formatter`

The older flat aliases such as `input_audio_format`, `output_audio_format`, `input_audio_transcription`, and `turn_detection` still work, but nested `audio` settings are preferred for new code.

For manual turn control, use a raw `session.update` / `input_audio_buffer.commit` / `response.create` flow as described in the [Realtime agents guide](guide.md#manual-response-control).

For the full schema, see [`RealtimeRunConfig`][agents.realtime.config.RealtimeRunConfig] and [`RealtimeSessionModelSettings`][agents.realtime.config.RealtimeSessionModelSettings].

## Connection options

Set your API key in the environment:

```bash
export OPENAI_API_KEY="your-api-key-here"
```

Or pass it directly when starting the session:

```python
session = await runner.run(model_config={"api_key": "your-api-key"})
```

`model_config` also supports:

-   `url`: Custom WebSocket endpoint
-   `headers`: Custom request headers
-   `call_id`: Attach to an existing realtime call. In this repo, the documented attach flow is SIP.
-   `playback_tracker`: Report how much audio the user has actually heard

If you pass `headers` explicitly, the SDK will **not** inject an `Authorization` header for you.

When connecting to Azure OpenAI, pass a GA Realtime endpoint URL in `model_config["url"]` and explicit headers. Avoid the legacy beta path (`/openai/realtime?api-version=...`) with realtime agents. See the [Realtime agents guide](guide.md#low-level-access-and-custom-endpoints) for details.

## Next steps

-   Read [Realtime transport](transport.md) to choose between server-side WebSocket and SIP.
-   Read the [Realtime agents guide](guide.md) for lifecycle, structured input, approvals, handoffs, guardrails, and low-level control.
-   Browse the examples in [`examples/realtime`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime).

================
File: docs/realtime/transport.md
================
# Realtime transport

Use this page to decide how realtime agents fit into your Python application.

!!! note "Python SDK boundary"

    The Python SDK does **not** include a browser WebRTC transport. This page is only about Python SDK transport choices: server-side WebSockets and SIP attach flows. Browser WebRTC is a separate platform topic, documented in the official [Realtime API with WebRTC](https://developers.openai.com/api/docs/guides/realtime-webrtc/) guide.

## Decision guide

| Goal | Start with | Why |
| --- | --- | --- |
| Build a server-managed realtime app | [Quickstart](quickstart.md) | The default Python path is a server-side WebSocket session managed by `RealtimeRunner`. |
| Understand which transport and deployment shape to choose | This page | Use this before you commit to a transport or deployment shape. |
| Attach agents to phone or SIP calls | [Realtime guide](guide.md) and [`examples/realtime/twilio_sip`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/twilio_sip) | The repo ships a SIP attach flow driven by `call_id`. |

## Server-side WebSocket is the default Python path

`RealtimeRunner` uses `OpenAIRealtimeWebSocketModel` unless you pass a custom `RealtimeModel`.

That means the standard Python topology looks like this:

1. Your Python service creates a `RealtimeRunner`.
2. `await runner.run()` returns a `RealtimeSession`.
3. Enter the session and send text, structured messages, or audio.
4. Consume `RealtimeSessionEvent` items and forward audio or transcripts to your application.

This is the topology used by the core demo app, the CLI example, and the Twilio Media Streams example:

-   [`examples/realtime/app`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/app)
-   [`examples/realtime/cli`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/cli)
-   [`examples/realtime/twilio`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/twilio)

Use this path when your server owns the audio pipeline, tool execution, approval flow, and history handling.

## SIP attach is the telephony path

For the telephony flow documented in this repository, the Python SDK attaches to an existing realtime call via `call_id`.

This topology looks like:

1. OpenAI sends your service a webhook such as `realtime.call.incoming`.
2. Your service accepts the call through the Realtime Calls API.
3. Your Python service starts a `RealtimeRunner(..., model=OpenAIRealtimeSIPModel())`.
4. The session connects with `model_config={"call_id": ...}` and then processes events like any other realtime session.

This is the topology shown in [`examples/realtime/twilio_sip`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/twilio_sip).

The broader Realtime API also uses `call_id` for some server-side control patterns, but this repository's shipped attach example is SIP.

## Browser WebRTC is outside this SDK

If your app's primary client is a browser using Realtime WebRTC:

-   Treat it as outside the scope of the Python SDK docs in this repository.
-   Use the official [Realtime API with WebRTC](https://developers.openai.com/api/docs/guides/realtime-webrtc/) and [Realtime conversations](https://developers.openai.com/api/docs/guides/realtime-conversations/) docs for the client-side flow and event model.
-   Use the official [Realtime server-side controls](https://developers.openai.com/api/docs/guides/realtime-server-controls/) guide if you need a sideband server connection on top of a browser WebRTC client.
-   Do not expect this repository to provide a browser-side `RTCPeerConnection` abstraction or a ready-made browser WebRTC sample.

This repository also does not currently ship a browser WebRTC plus Python sideband example.

## Custom endpoints and attach points

The transport configuration surface in [`RealtimeModelConfig`][agents.realtime.model.RealtimeModelConfig] lets you adapt the default paths:

-   `url`: Override the WebSocket endpoint
-   `headers`: Provide explicit headers such as Azure auth headers
-   `api_key`: Pass an API key directly or via callback
-   `call_id`: Attach to an existing realtime call. In this repository, the documented example is SIP.
-   `playback_tracker`: Report actual playback progress for interruption handling

See the [Realtime agents guide](guide.md) for the detailed lifecycle and capability surface once you've chosen a topology.

================
File: docs/ref/extensions/experimental/codex/codex_options.md
================
# `Codex Options`

::: agents.extensions.experimental.codex.codex_options

================
File: docs/ref/extensions/experimental/codex/codex_tool.md
================
# `Codex Tool`

::: agents.extensions.experimental.codex.codex_tool

================
File: docs/ref/extensions/experimental/codex/codex.md
================
# `Codex`

::: agents.extensions.experimental.codex.codex

================
File: docs/ref/extensions/experimental/codex/events.md
================
# `Events`

::: agents.extensions.experimental.codex.events

================
File: docs/ref/extensions/experimental/codex/exec.md
================
# `Exec`

::: agents.extensions.experimental.codex.exec

================
File: docs/ref/extensions/experimental/codex/items.md
================
# `Items`

::: agents.extensions.experimental.codex.items

================
File: docs/ref/extensions/experimental/codex/output_schema_file.md
================
# `Output Schema File`

::: agents.extensions.experimental.codex.output_schema_file

================
File: docs/ref/extensions/experimental/codex/payloads.md
================
# `Payloads`

::: agents.extensions.experimental.codex.payloads

================
File: docs/ref/extensions/experimental/codex/thread_options.md
================
# `Thread Options`

::: agents.extensions.experimental.codex.thread_options

================
File: docs/ref/extensions/experimental/codex/thread.md
================
# `Thread`

::: agents.extensions.experimental.codex.thread

================
File: docs/ref/extensions/experimental/codex/turn_options.md
================
# `Turn Options`

::: agents.extensions.experimental.codex.turn_options

================
File: docs/ref/extensions/memory/advanced_sqlite_session.md
================
# `AdvancedSQLiteSession`

::: agents.extensions.memory.advanced_sqlite_session.AdvancedSQLiteSession

================
File: docs/ref/extensions/memory/async_sqlite_session.md
================
# `Async Sqlite Session`

::: agents.extensions.memory.async_sqlite_session

================
File: docs/ref/extensions/memory/dapr_session.md
================
# `DaprSession`

::: agents.extensions.memory.dapr_session.DaprSession

================
File: docs/ref/extensions/memory/encrypt_session.md
================
# `EncryptedSession`

::: agents.extensions.memory.encrypt_session.EncryptedSession

================
File: docs/ref/extensions/memory/redis_session.md
================
# `RedisSession`

::: agents.extensions.memory.redis_session.RedisSession

================
File: docs/ref/extensions/memory/sqlalchemy_session.md
================
# `SQLAlchemySession`

::: agents.extensions.memory.sqlalchemy_session.SQLAlchemySession

================
File: docs/ref/extensions/models/litellm_model.md
================
# `LiteLLM Model`

::: agents.extensions.models.litellm_model

================
File: docs/ref/extensions/models/litellm_provider.md
================
# `LiteLLM Provider`

::: agents.extensions.models.litellm_provider

================
File: docs/ref/extensions/handoff_filters.md
================
# `Handoff filters`

::: agents.extensions.handoff_filters

================
File: docs/ref/extensions/handoff_prompt.md
================
# `Handoff prompt`

::: agents.extensions.handoff_prompt

    options:
        members:
            - RECOMMENDED_PROMPT_PREFIX
            - prompt_with_handoff_instructions

================
File: docs/ref/extensions/litellm.md
================
# `LiteLLM Models`

::: agents.extensions.models.litellm_model

================
File: docs/ref/extensions/tool_output_trimmer.md
================
# `Tool Output Trimmer`

::: agents.extensions.tool_output_trimmer

================
File: docs/ref/extensions/visualization.md
================
# `Visualization`

::: agents.extensions.visualization

================
File: docs/ref/handoffs/history.md
================
# `History`

::: agents.handoffs.history

================
File: docs/ref/mcp/manager.md
================
# `Manager`

::: agents.mcp.manager

================
File: docs/ref/mcp/server.md
================
# `MCP Servers`

::: agents.mcp.server

================
File: docs/ref/mcp/util.md
================
# `MCP Util`

::: agents.mcp.util

================
File: docs/ref/memory/openai_conversations_session.md
================
# `Openai Conversations Session`

::: agents.memory.openai_conversations_session

================
File: docs/ref/memory/openai_responses_compaction_session.md
================
# `Openai Responses Compaction Session`

::: agents.memory.openai_responses_compaction_session

================
File: docs/ref/memory/session_settings.md
================
# `Session Settings`

::: agents.memory.session_settings

================
File: docs/ref/memory/session.md
================
# `Session`

::: agents.memory.session

================
File: docs/ref/memory/sqlite_session.md
================
# `Sqlite Session`

::: agents.memory.sqlite_session

================
File: docs/ref/memory/util.md
================
# `Util`

::: agents.memory.util

================
File: docs/ref/models/chatcmpl_converter.md
================
# `Chatcmpl Converter`

::: agents.models.chatcmpl_converter

================
File: docs/ref/models/chatcmpl_helpers.md
================
# `Chatcmpl Helpers`

::: agents.models.chatcmpl_helpers

================
File: docs/ref/models/chatcmpl_stream_handler.md
================
# `Chatcmpl Stream Handler`

::: agents.models.chatcmpl_stream_handler

================
File: docs/ref/models/default_models.md
================
# `Default Models`

::: agents.models.default_models

================
File: docs/ref/models/fake_id.md
================
# `Fake Id`

::: agents.models.fake_id

================
File: docs/ref/models/interface.md
================
# `Model interface`

::: agents.models.interface

================
File: docs/ref/models/multi_provider.md
================
# `Multi Provider`

::: agents.models.multi_provider

================
File: docs/ref/models/openai_chatcompletions.md
================
# `OpenAI Chat Completions model`

::: agents.models.openai_chatcompletions

================
File: docs/ref/models/openai_provider.md
================
# `OpenAI Provider`

::: agents.models.openai_provider

================
File: docs/ref/models/openai_responses.md
================
# `OpenAI Responses model`

::: agents.models.openai_responses

================
File: docs/ref/realtime/agent.md
================
# `RealtimeAgent`

::: agents.realtime.agent.RealtimeAgent

================
File: docs/ref/realtime/audio_formats.md
================
# `Audio Formats`

::: agents.realtime.audio_formats

================
File: docs/ref/realtime/config.md
================
# Realtime Configuration

## Run Configuration

::: agents.realtime.config.RealtimeRunConfig

## Model Settings

::: agents.realtime.config.RealtimeSessionModelSettings

## Audio Configuration

::: agents.realtime.config.RealtimeInputAudioTranscriptionConfig
::: agents.realtime.config.RealtimeInputAudioNoiseReductionConfig
::: agents.realtime.config.RealtimeTurnDetectionConfig

## Guardrails Settings

::: agents.realtime.config.RealtimeGuardrailsSettings

## Model Configuration

::: agents.realtime.model.RealtimeModelConfig

## Tracing Configuration

::: agents.realtime.config.RealtimeModelTracingConfig

## User Input Types

::: agents.realtime.config.RealtimeUserInput
::: agents.realtime.config.RealtimeUserInputText
::: agents.realtime.config.RealtimeUserInputMessage

## Client Messages

::: agents.realtime.config.RealtimeClientMessage

## Type Aliases

::: agents.realtime.config.RealtimeModelName
::: agents.realtime.config.RealtimeAudioFormat

================
File: docs/ref/realtime/events.md
================
# Realtime Events

## Session Events

::: agents.realtime.events.RealtimeSessionEvent

## Event Types

### Agent Events
::: agents.realtime.events.RealtimeAgentStartEvent
::: agents.realtime.events.RealtimeAgentEndEvent

### Audio Events
::: agents.realtime.events.RealtimeAudio
::: agents.realtime.events.RealtimeAudioEnd
::: agents.realtime.events.RealtimeAudioInterrupted

### Tool Events
::: agents.realtime.events.RealtimeToolStart
::: agents.realtime.events.RealtimeToolEnd

### Handoff Events
::: agents.realtime.events.RealtimeHandoffEvent

### Guardrail Events
::: agents.realtime.events.RealtimeGuardrailTripped

### History Events
::: agents.realtime.events.RealtimeHistoryAdded
::: agents.realtime.events.RealtimeHistoryUpdated

### Error Events
::: agents.realtime.events.RealtimeError

### Raw Model Events
::: agents.realtime.events.RealtimeRawModelEvent

================
File: docs/ref/realtime/handoffs.md
================
# `Handoffs`

::: agents.realtime.handoffs

================
File: docs/ref/realtime/items.md
================
# `Items`

::: agents.realtime.items

================
File: docs/ref/realtime/model_events.md
================
# `Model Events`

::: agents.realtime.model_events

================
File: docs/ref/realtime/model_inputs.md
================
# `Model Inputs`

::: agents.realtime.model_inputs

================
File: docs/ref/realtime/model.md
================
# `Model`

::: agents.realtime.model

================
File: docs/ref/realtime/openai_realtime.md
================
# `Openai Realtime`

::: agents.realtime.openai_realtime

================
File: docs/ref/realtime/runner.md
================
# `RealtimeRunner`

::: agents.realtime.runner.RealtimeRunner

================
File: docs/ref/realtime/session.md
================
# `RealtimeSession`

::: agents.realtime.session.RealtimeSession

================
File: docs/ref/run_internal/agent_runner_helpers.md
================
# `Agent Runner Helpers`

::: agents.run_internal.agent_runner_helpers

================
File: docs/ref/run_internal/approvals.md
================
# `Approvals`

::: agents.run_internal.approvals

================
File: docs/ref/run_internal/error_handlers.md
================
# `Error Handlers`

::: agents.run_internal.error_handlers

================
File: docs/ref/run_internal/guardrails.md
================
# `Guardrails`

::: agents.run_internal.guardrails

================
File: docs/ref/run_internal/items.md
================
# `Items`

::: agents.run_internal.items

================
File: docs/ref/run_internal/oai_conversation.md
================
# `Oai Conversation`

::: agents.run_internal.oai_conversation

================
File: docs/ref/run_internal/run_loop.md
================
# `Run Loop`

::: agents.run_internal.run_loop

================
File: docs/ref/run_internal/run_steps.md
================
# `Run Steps`

::: agents.run_internal.run_steps

================
File: docs/ref/run_internal/session_persistence.md
================
# `Session Persistence`

::: agents.run_internal.session_persistence

================
File: docs/ref/run_internal/streaming.md
================
# `Streaming`

::: agents.run_internal.streaming

================
File: docs/ref/run_internal/tool_actions.md
================
# `Tool Actions`

::: agents.run_internal.tool_actions

================
File: docs/ref/run_internal/tool_execution.md
================
# `Tool Execution`

::: agents.run_internal.tool_execution

================
File: docs/ref/run_internal/tool_planning.md
================
# `Tool Planning`

::: agents.run_internal.tool_planning

================
File: docs/ref/run_internal/tool_use_tracker.md
================
# `Tool Use Tracker`

::: agents.run_internal.tool_use_tracker

================
File: docs/ref/run_internal/turn_preparation.md
================
# `Turn Preparation`

::: agents.run_internal.turn_preparation

================
File: docs/ref/run_internal/turn_resolution.md
================
# `Turn Resolution`

::: agents.run_internal.turn_resolution

================
File: docs/ref/tracing/config.md
================
# `Config`

::: agents.tracing.config

================
File: docs/ref/tracing/context.md
================
# `Context`

::: agents.tracing.context

================
File: docs/ref/tracing/create.md
================
# `Creating traces/spans`

::: agents.tracing.create

================
File: docs/ref/tracing/index.md
================
# Tracing module

::: agents.tracing

================
File: docs/ref/tracing/logger.md
================
# `Logger`

::: agents.tracing.logger

================
File: docs/ref/tracing/model_tracing.md
================
# `Model Tracing`

::: agents.tracing.model_tracing

================
File: docs/ref/tracing/processor_interface.md
================
# `Processor interface`

::: agents.tracing.processor_interface

================
File: docs/ref/tracing/processors.md
================
# `Processors`

::: agents.tracing.processors

================
File: docs/ref/tracing/provider.md
================
# `Provider`

::: agents.tracing.provider

================
File: docs/ref/tracing/scope.md
================
# `Scope`

::: agents.tracing.scope

================
File: docs/ref/tracing/setup.md
================
# `Setup`

::: agents.tracing.setup

================
File: docs/ref/tracing/span_data.md
================
# `Span data`

::: agents.tracing.span_data

================
File: docs/ref/tracing/spans.md
================
# `Spans`

::: agents.tracing.spans

    options:
        members:
            - Span
            - NoOpSpan
            - SpanImpl

================
File: docs/ref/tracing/traces.md
================
# `Traces`

::: agents.tracing.traces

================
File: docs/ref/tracing/util.md
================
# `Util`

::: agents.tracing.util

================
File: docs/ref/voice/models/openai_model_provider.md
================
# `OpenAI Model Provider`

::: agents.voice.models.openai_model_provider

================
File: docs/ref/voice/models/openai_provider.md
================
# `OpenAIVoiceModelProvider`

::: agents.voice.models.openai_model_provider

================
File: docs/ref/voice/models/openai_stt.md
================
# `OpenAI STT`

::: agents.voice.models.openai_stt

================
File: docs/ref/voice/models/openai_tts.md
================
# `OpenAI TTS`

::: agents.voice.models.openai_tts

================
File: docs/ref/voice/events.md
================
# `Events`

::: agents.voice.events

================
File: docs/ref/voice/exceptions.md
================
# `Exceptions`

::: agents.voice.exceptions

================
File: docs/ref/voice/imports.md
================
# `Imports`

::: agents.voice.imports

================
File: docs/ref/voice/input.md
================
# `Input`

::: agents.voice.input

================
File: docs/ref/voice/model.md
================
# `Model`

::: agents.voice.model

================
File: docs/ref/voice/pipeline_config.md
================
# `Pipeline Config`

::: agents.voice.pipeline_config

================
File: docs/ref/voice/pipeline.md
================
# `Pipeline`

::: agents.voice.pipeline

================
File: docs/ref/voice/result.md
================
# `Result`

::: agents.voice.result

================
File: docs/ref/voice/utils.md
================
# `Utils`

::: agents.voice.utils

================
File: docs/ref/voice/workflow.md
================
# `Workflow`

::: agents.voice.workflow

================
File: docs/ref/agent_output.md
================
# `Agent output`

::: agents.agent_output

================
File: docs/ref/agent_tool_input.md
================
# `Agent Tool Input`

::: agents.agent_tool_input

================
File: docs/ref/agent_tool_state.md
================
# `Agent Tool State`

::: agents.agent_tool_state

================
File: docs/ref/agent.md
================
# `Agents`

::: agents.agent

================
File: docs/ref/apply_diff.md
================
# `Apply Diff`

::: agents.apply_diff

================
File: docs/ref/computer.md
================
# `Computer`

::: agents.computer

================
File: docs/ref/editor.md
================
# `Editor`

::: agents.editor

================
File: docs/ref/exceptions.md
================
# `Exceptions`

::: agents.exceptions

================
File: docs/ref/function_schema.md
================
# `Function schema`

::: agents.function_schema

================
File: docs/ref/guardrail.md
================
# `Guardrails`

::: agents.guardrail

================
File: docs/ref/handoffs.md
================
# `Handoffs`

::: agents.handoffs

================
File: docs/ref/index.md
================
# Agents module

::: agents

    options:
        members:
            - set_default_openai_key
            - set_default_openai_client
            - set_default_openai_api
            - set_default_openai_responses_transport
            - ResponsesWebSocketSession
            - responses_websocket_session
            - set_tracing_export_api_key
            - set_tracing_disabled
            - set_trace_processors
            - enable_verbose_stdout_logging

================
File: docs/ref/items.md
================
# `Items`

::: agents.items

================
File: docs/ref/lifecycle.md
================
# `Lifecycle`

::: agents.lifecycle

    options:
        show_source: false

================
File: docs/ref/logger.md
================
# `Logger`

::: agents.logger

================
File: docs/ref/memory.md
================
# Memory

::: agents.memory

    options:
        members:
            - Session
            - SQLiteSession
            - OpenAIConversationsSession

================
File: docs/ref/model_settings.md
================
# `Model settings`

::: agents.model_settings

================
File: docs/ref/prompts.md
================
# `Prompts`

::: agents.prompts

================
File: docs/ref/repl.md
================
# `repl`

::: agents.repl
    options:
        members:
            - run_demo_loop

================
File: docs/ref/responses_websocket_session.md
================
# `Responses WebSocket Session`

::: agents.responses_websocket_session

================
File: docs/ref/result.md
================
# `Results`

::: agents.result

================
File: docs/ref/run_config.md
================
# `Run Config`

::: agents.run_config

================
File: docs/ref/run_context.md
================
# `Run context`

::: agents.run_context

================
File: docs/ref/run_error_handlers.md
================
# `Run Error Handlers`

::: agents.run_error_handlers

================
File: docs/ref/run_state.md
================
# `Run State`

::: agents.run_state

================
File: docs/ref/run.md
================
# `Runner`

::: agents.run

    options:
        members:
            - Runner
            - RunConfig

================
File: docs/ref/stream_events.md
================
# `Streaming events`

::: agents.stream_events

================
File: docs/ref/strict_schema.md
================
# `Strict Schema`

::: agents.strict_schema

================
File: docs/ref/tool_context.md
================
# `Tool Context`

::: agents.tool_context

================
File: docs/ref/tool_guardrails.md
================
# `Tool Guardrails`

::: agents.tool_guardrails

================
File: docs/ref/tool.md
================
# `Tools`

::: agents.tool

================
File: docs/ref/usage.md
================
# `Usage`

::: agents.usage

================
File: docs/ref/version.md
================
# `Version`

::: agents.version

================
File: docs/sessions/advanced_sqlite_session.md
================
# Advanced SQLite sessions

`AdvancedSQLiteSession` is an enhanced version of the basic `SQLiteSession` that provides advanced conversation management capabilities including conversation branching, detailed usage analytics, and structured conversation queries.

## Features

- **Conversation branching**: Create alternative conversation paths from any user message
- **Usage tracking**: Detailed token usage analytics per turn with full JSON breakdowns
- **Structured queries**: Get conversations by turns, tool usage statistics, and more
- **Branch management**: Independent branch switching and management
- **Message structure metadata**: Track message types, tool usage, and conversation flow

## Quick start

```python
from agents import Agent, Runner
from agents.extensions.memory import AdvancedSQLiteSession

# Create agent
agent = Agent(
    name="Assistant",
    instructions="Reply very concisely.",
)

# Create an advanced session
session = AdvancedSQLiteSession(
    session_id="conversation_123",
    db_path="conversations.db",
    create_tables=True
)

# First conversation turn
result = await Runner.run(
    agent,
    "What city is the Golden Gate Bridge in?",
    session=session
)
print(result.final_output)  # "San Francisco"

# IMPORTANT: Store usage data
await session.store_run_usage(result)

# Continue conversation
result = await Runner.run(
    agent,
    "What state is it in?",
    session=session
)
print(result.final_output)  # "California"
await session.store_run_usage(result)
```

## Initialization

```python
from agents.extensions.memory import AdvancedSQLiteSession

# Basic initialization
session = AdvancedSQLiteSession(
    session_id="my_conversation",
    create_tables=True  # Auto-create advanced tables
)

# With persistent storage
session = AdvancedSQLiteSession(
    session_id="user_123",
    db_path="path/to/conversations.db",
    create_tables=True
)

# With custom logger
import logging
logger = logging.getLogger("my_app")
session = AdvancedSQLiteSession(
    session_id="session_456",
    create_tables=True,
    logger=logger
)
```

### Parameters

- `session_id` (str): Unique identifier for the conversation session
- `db_path` (str | Path): Path to SQLite database file. Defaults to `:memory:` for in-memory storage
- `create_tables` (bool): Whether to automatically create the advanced tables. Defaults to `False`
- `logger` (logging.Logger | None): Custom logger for the session. Defaults to module logger

## Usage tracking

AdvancedSQLiteSession provides detailed usage analytics by storing token usage data per conversation turn. **This is entirely dependent on the `store_run_usage` method being called after each agent run.**

### Storing usage data

```python
# After each agent run, store the usage data
result = await Runner.run(agent, "Hello", session=session)
await session.store_run_usage(result)

# This stores:
# - Total tokens used
# - Input/output token breakdown
# - Request count
# - Detailed JSON token information (if available)
```

### Retrieving usage statistics

```python
# Get session-level usage (all branches)
session_usage = await session.get_session_usage()
if session_usage:
    print(f"Total requests: {session_usage['requests']}")
    print(f"Total tokens: {session_usage['total_tokens']}")
    print(f"Input tokens: {session_usage['input_tokens']}")
    print(f"Output tokens: {session_usage['output_tokens']}")
    print(f"Total turns: {session_usage['total_turns']}")

# Get usage for specific branch
branch_usage = await session.get_session_usage(branch_id="main")

# Get usage by turn
turn_usage = await session.get_turn_usage()
for turn_data in turn_usage:
    print(f"Turn {turn_data['user_turn_number']}: {turn_data['total_tokens']} tokens")
    if turn_data['input_tokens_details']:
        print(f"  Input details: {turn_data['input_tokens_details']}")
    if turn_data['output_tokens_details']:
        print(f"  Output details: {turn_data['output_tokens_details']}")

# Get usage for specific turn
turn_2_usage = await session.get_turn_usage(user_turn_number=2)
```

## Conversation branching

One of the key features of AdvancedSQLiteSession is the ability to create conversation branches from any user message, allowing you to explore alternative conversation paths.

### Creating branches

```python
# Get available turns for branching
turns = await session.get_conversation_turns()
for turn in turns:
    print(f"Turn {turn['turn']}: {turn['content']}")
    print(f"Can branch: {turn['can_branch']}")

# Create a branch from turn 2
branch_id = await session.create_branch_from_turn(2)
print(f"Created branch: {branch_id}")

# Create a branch with custom name
branch_id = await session.create_branch_from_turn(
    2, 
    branch_name="alternative_path"
)

# Create branch by searching for content
branch_id = await session.create_branch_from_content(
    "weather", 
    branch_name="weather_focus"
)
```

### Branch management

```python
# List all branches
branches = await session.list_branches()
for branch in branches:
    current = " (current)" if branch["is_current"] else ""
    print(f"{branch['branch_id']}: {branch['user_turns']} turns, {branch['message_count']} messages{current}")

# Switch between branches
await session.switch_to_branch("main")
await session.switch_to_branch(branch_id)

# Delete a branch
await session.delete_branch(branch_id, force=True)  # force=True allows deleting current branch
```

### Branch workflow example

```python
# Original conversation
result = await Runner.run(agent, "What's the capital of France?", session=session)
await session.store_run_usage(result)

result = await Runner.run(agent, "What's the weather like there?", session=session)
await session.store_run_usage(result)

# Create branch from turn 2 (weather question)
branch_id = await session.create_branch_from_turn(2, "weather_focus")

# Continue in new branch with different question
result = await Runner.run(
    agent, 
    "What are the main tourist attractions in Paris?", 
    session=session
)
await session.store_run_usage(result)

# Switch back to main branch
await session.switch_to_branch("main")

# Continue original conversation
result = await Runner.run(
    agent, 
    "How expensive is it to visit?", 
    session=session
)
await session.store_run_usage(result)
```

## Structured queries

AdvancedSQLiteSession provides several methods for analyzing conversation structure and content.

### Conversation analysis

```python
# Get conversation organized by turns
conversation_by_turns = await session.get_conversation_by_turns()
for turn_num, items in conversation_by_turns.items():
    print(f"Turn {turn_num}: {len(items)} items")
    for item in items:
        if item["tool_name"]:
            print(f"  - {item['type']} (tool: {item['tool_name']})")
        else:
            print(f"  - {item['type']}")

# Get tool usage statistics
tool_usage = await session.get_tool_usage()
for tool_name, count, turn in tool_usage:
    print(f"{tool_name}: used {count} times in turn {turn}")

# Find turns by content
matching_turns = await session.find_turns_by_content("weather")
for turn in matching_turns:
    print(f"Turn {turn['turn']}: {turn['content']}")
```

### Message structure

The session automatically tracks message structure including:

- Message types (user, assistant, tool_call, etc.)
- Tool names for tool calls
- Turn numbers and sequence numbers
- Branch associations
- Timestamps

## Database schema

AdvancedSQLiteSession extends the basic SQLite schema with two additional tables:

### message_structure table

```sql
CREATE TABLE message_structure (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    message_id INTEGER NOT NULL,
    branch_id TEXT NOT NULL DEFAULT 'main',
    message_type TEXT NOT NULL,
    sequence_number INTEGER NOT NULL,
    user_turn_number INTEGER,
    branch_turn_number INTEGER,
    tool_name TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES agent_sessions(session_id) ON DELETE CASCADE,
    FOREIGN KEY (message_id) REFERENCES agent_messages(id) ON DELETE CASCADE
);
```

### turn_usage table

```sql
CREATE TABLE turn_usage (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    branch_id TEXT NOT NULL DEFAULT 'main',
    user_turn_number INTEGER NOT NULL,
    requests INTEGER DEFAULT 0,
    input_tokens INTEGER DEFAULT 0,
    output_tokens INTEGER DEFAULT 0,
    total_tokens INTEGER DEFAULT 0,
    input_tokens_details JSON,
    output_tokens_details JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES agent_sessions(session_id) ON DELETE CASCADE,
    UNIQUE(session_id, branch_id, user_turn_number)
);
```

## Complete example

Check out the [complete example](https://github.com/openai/openai-agents-python/tree/main/examples/memory/advanced_sqlite_session_example.py) for a comprehensive demonstration of all features.


## API reference

- [`AdvancedSQLiteSession`][agents.extensions.memory.advanced_sqlite_session.AdvancedSQLiteSession] - Main class
- [`Session`][agents.memory.session.Session] - Base session protocol

================
File: docs/sessions/encrypted_session.md
================
# Encrypted sessions

`EncryptedSession` provides transparent encryption for any session implementation, securing conversation data with automatic expiration of old items.

## Features

- **Transparent encryption**: Wraps any session with Fernet encryption
- **Per-session keys**: Uses HKDF key derivation for unique encryption per session
- **Automatic expiration**: Old items are silently skipped when TTL expires
- **Drop-in replacement**: Works with any existing session implementation

## Installation

Encrypted sessions require the `encrypt` extra:

```bash
pip install openai-agents[encrypt]
```

## Quick start

```python
import asyncio
from agents import Agent, Runner
from agents.extensions.memory import EncryptedSession, SQLAlchemySession

async def main():
    agent = Agent("Assistant")
    
    # Create underlying session
    underlying_session = SQLAlchemySession.from_url(
        "user-123",
        url="sqlite+aiosqlite:///:memory:",
        create_tables=True
    )
    
    # Wrap with encryption
    session = EncryptedSession(
        session_id="user-123",
        underlying_session=underlying_session,
        encryption_key="your-secret-key-here",
        ttl=600  # 10 minutes
    )
    
    result = await Runner.run(agent, "Hello", session=session)
    print(result.final_output)

if __name__ == "__main__":
    asyncio.run(main())
```

## Configuration

### Encryption key

The encryption key can be either a Fernet key or any string:

```python
from agents.extensions.memory import EncryptedSession

# Using a Fernet key (base64-encoded)
session = EncryptedSession(
    session_id="user-123",
    underlying_session=underlying_session,
    encryption_key="your-fernet-key-here",
    ttl=600
)

# Using a raw string (will be derived to a key)
session = EncryptedSession(
    session_id="user-123", 
    underlying_session=underlying_session,
    encryption_key="my-secret-password",
    ttl=600
)
```

### TTL (time to live)

Set how long encrypted items remain valid:

```python
# Items expire after 1 hour
session = EncryptedSession(
    session_id="user-123",
    underlying_session=underlying_session,
    encryption_key="secret",
    ttl=3600  # 1 hour in seconds
)

# Items expire after 1 day
session = EncryptedSession(
    session_id="user-123",
    underlying_session=underlying_session,
    encryption_key="secret", 
    ttl=86400  # 24 hours in seconds
)
```

## Usage with different session types

### With SQLite sessions

```python
from agents import SQLiteSession
from agents.extensions.memory import EncryptedSession

# Create encrypted SQLite session
underlying = SQLiteSession("user-123", "conversations.db")

session = EncryptedSession(
    session_id="user-123",
    underlying_session=underlying,
    encryption_key="secret-key"
)
```

### With SQLAlchemy sessions

```python
from agents.extensions.memory import EncryptedSession, SQLAlchemySession

# Create encrypted SQLAlchemy session
underlying = SQLAlchemySession.from_url(
    "user-123",
    url="postgresql+asyncpg://user:pass@localhost/db",
    create_tables=True
)

session = EncryptedSession(
    session_id="user-123",
    underlying_session=underlying,
    encryption_key="secret-key"
)
```

!!! warning "Advanced Session Features"

    When using `EncryptedSession` with advanced session implementations like `AdvancedSQLiteSession`, note that:

    - Methods like `find_turns_by_content()` won't work effectively since message content is encrypted
    - Content-based searches operate on encrypted data, limiting their effectiveness



## Key derivation

EncryptedSession uses HKDF (HMAC-based Key Derivation Function) to derive unique encryption keys per session:

- **Master key**: Your provided encryption key
- **Session salt**: The session ID
- **Info string**: `"agents.session-store.hkdf.v1"`
- **Output**: 32-byte Fernet key

This ensures that:
- Each session has a unique encryption key
- Keys cannot be derived without the master key
- Session data cannot be decrypted across different sessions

## Automatic expiration

When items exceed the TTL, they are automatically skipped during retrieval:

```python
# Items older than TTL are silently ignored
items = await session.get_items()  # Only returns non-expired items

# Expired items don't affect session behavior
result = await Runner.run(agent, "Continue conversation", session=session)
```

## API reference

- [`EncryptedSession`][agents.extensions.memory.encrypt_session.EncryptedSession] - Main class
- [`Session`][agents.memory.session.Session] - Base session protocol

================
File: docs/sessions/index.md
================
# Sessions

The Agents SDK provides built-in session memory to automatically maintain conversation history across multiple agent runs, eliminating the need to manually handle `.to_input_list()` between turns.

Sessions stores conversation history for a specific session, allowing agents to maintain context without requiring explicit manual memory management. This is particularly useful for building chat applications or multi-turn conversations where you want the agent to remember previous interactions.

Use sessions when you want the SDK to manage client-side memory for you. Sessions cannot be combined with `conversation_id`, `previous_response_id`, or `auto_previous_response_id` in the same run. If you want OpenAI server-managed continuation instead, choose one of those mechanisms rather than layering a session on top.

## Quick start

```python
from agents import Agent, Runner, SQLiteSession

# Create agent
agent = Agent(
    name="Assistant",
    instructions="Reply very concisely.",
)

# Create a session instance with a session ID
session = SQLiteSession("conversation_123")

# First turn
result = await Runner.run(
    agent,
    "What city is the Golden Gate Bridge in?",
    session=session
)
print(result.final_output)  # "San Francisco"

# Second turn - agent automatically remembers previous context
result = await Runner.run(
    agent,
    "What state is it in?",
    session=session
)
print(result.final_output)  # "California"

# Also works with synchronous runner
result = Runner.run_sync(
    agent,
    "What's the population?",
    session=session
)
print(result.final_output)  # "Approximately 39 million"
```

## Resuming interrupted runs with the same session

If a run pauses for approval, resume it with the same session instance (or another session instance that points at the same backing store) so the resumed turn continues the same stored conversation history.

```python
result = await Runner.run(agent, "Delete temporary files that are no longer needed.", session=session)

if result.interruptions:
    state = result.to_state()
    for interruption in result.interruptions:
        state.approve(interruption)
    result = await Runner.run(agent, state, session=session)
```

## Core session behavior

When session memory is enabled:

1. **Before each run**: The runner automatically retrieves the conversation history for the session and prepends it to the input items.
2. **After each run**: All new items generated during the run (user input, assistant responses, tool calls, etc.) are automatically stored in the session.
3. **Context preservation**: Each subsequent run with the same session includes the full conversation history, allowing the agent to maintain context.

This eliminates the need to manually call `.to_input_list()` and manage conversation state between runs.

## Control how history and new input merge

When you pass a session, the runner normally prepares model input as:

1. Session history (retrieved from `session.get_items(...)`)
2. New turn input

Use [`RunConfig.session_input_callback`][agents.run.RunConfig.session_input_callback] to customize that merge step before the model call. The callback receives two lists:

-   `history`: The retrieved session history (already normalized into input-item format)
-   `new_input`: The current turn's new input items

Return the final list of input items that should be sent to the model.

The callback receives copies of both lists, so you can safely mutate them. The returned list controls the model input for that turn, but the SDK still persists only items that belong to the new turn. Reordering or filtering old history therefore does not cause old session items to be saved again as fresh input.

```python
from agents import Agent, RunConfig, Runner, SQLiteSession


def keep_recent_history(history, new_input):
    # Keep only the last 10 history items, then append the new turn.
    return history[-10:] + new_input


agent = Agent(name="Assistant")
session = SQLiteSession("conversation_123")

result = await Runner.run(
    agent,
    "Continue from the latest updates only.",
    session=session,
    run_config=RunConfig(session_input_callback=keep_recent_history),
)
```

Use this when you need custom pruning, reordering, or selective inclusion of history without changing how the session stores items. If you need a later final pass immediately before the model call, use [`call_model_input_filter`][agents.run.RunConfig.call_model_input_filter] from the [running agents guide](../running_agents.md).

## Limiting retrieved history

Use [`SessionSettings`][agents.memory.SessionSettings] to control how much history is fetched before each run.

-   `SessionSettings(limit=None)` (default): retrieve all available session items
-   `SessionSettings(limit=N)`: retrieve only the most recent `N` items

You can apply this per run via [`RunConfig.session_settings`][agents.run.RunConfig.session_settings]:

```python
from agents import Agent, RunConfig, Runner, SessionSettings, SQLiteSession

agent = Agent(name="Assistant")
session = SQLiteSession("conversation_123")

result = await Runner.run(
    agent,
    "Summarize our recent discussion.",
    session=session,
    run_config=RunConfig(session_settings=SessionSettings(limit=50)),
)
```

If your session implementation exposes default session settings, `RunConfig.session_settings` overrides any non-`None` values for that run. This is useful for long conversations where you want to cap retrieval size without changing the session's default behavior.

## Memory operations

### Basic operations

Sessions supports several operations for managing conversation history:

```python
from agents import SQLiteSession

session = SQLiteSession("user_123", "conversations.db")

# Get all items in a session
items = await session.get_items()

# Add new items to a session
new_items = [
    {"role": "user", "content": "Hello"},
    {"role": "assistant", "content": "Hi there!"}
]
await session.add_items(new_items)

# Remove and return the most recent item
last_item = await session.pop_item()
print(last_item)  # {"role": "assistant", "content": "Hi there!"}

# Clear all items from a session
await session.clear_session()
```

### Using pop_item for corrections

The `pop_item` method is particularly useful when you want to undo or modify the last item in a conversation:

```python
from agents import Agent, Runner, SQLiteSession

agent = Agent(name="Assistant")
session = SQLiteSession("correction_example")

# Initial conversation
result = await Runner.run(
    agent,
    "What's 2 + 2?",
    session=session
)
print(f"Agent: {result.final_output}")

# User wants to correct their question
assistant_item = await session.pop_item()  # Remove agent's response
user_item = await session.pop_item()  # Remove user's question

# Ask a corrected question
result = await Runner.run(
    agent,
    "What's 2 + 3?",
    session=session
)
print(f"Agent: {result.final_output}")
```

## Built-in session implementations

The SDK provides several session implementations for different use cases:

### Choose a built-in session implementation

Use this table to pick a starting point before reading the detailed examples below.

| Session type | Best for | Notes |
| --- | --- | --- |
| `SQLiteSession` | Local development and simple apps | Built-in, lightweight, file-backed or in-memory |
| `AsyncSQLiteSession` | Async SQLite with `aiosqlite` | Extension backend with async driver support |
| `RedisSession` | Shared memory across workers/services | Good for low-latency distributed deployments |
| `SQLAlchemySession` | Production apps with existing databases | Works with SQLAlchemy-supported databases |
| `DaprSession` | Cloud-native deployments with Dapr sidecars | Supports multiple state stores plus TTL and consistency controls |
| `OpenAIConversationsSession` | Server-managed storage in OpenAI | OpenAI Conversations API-backed history |
| `OpenAIResponsesCompactionSession` | Long conversations with automatic compaction | Wrapper around another session backend |
| `AdvancedSQLiteSession` | SQLite plus branching/analytics | Heavier feature set; see dedicated page |
| `EncryptedSession` | Encryption + TTL on top of another session | Wrapper; choose an underlying backend first |

Some implementations have dedicated pages with additional details; those are linked inline in their subsections.

### OpenAI Conversations API sessions

Use [OpenAI's Conversations API](https://platform.openai.com/docs/api-reference/conversations) through `OpenAIConversationsSession`.

```python
from agents import Agent, Runner, OpenAIConversationsSession

# Create agent
agent = Agent(
    name="Assistant",
    instructions="Reply very concisely.",
)

# Create a new conversation
session = OpenAIConversationsSession()

# Optionally resume a previous conversation by passing a conversation ID
# session = OpenAIConversationsSession(conversation_id="conv_123")

# Start conversation
result = await Runner.run(
    agent,
    "What city is the Golden Gate Bridge in?",
    session=session
)
print(result.final_output)  # "San Francisco"

# Continue the conversation
result = await Runner.run(
    agent,
    "What state is it in?",
    session=session
)
print(result.final_output)  # "California"
```

### OpenAI Responses compaction sessions

Use `OpenAIResponsesCompactionSession` to compact stored conversation history with the Responses API (`responses.compact`). It wraps an underlying session and can automatically compact after each turn based on `should_trigger_compaction`. Do not wrap `OpenAIConversationsSession` with it; those two features manage history in different ways.

#### Typical usage (auto-compaction)

```python
from agents import Agent, Runner, SQLiteSession
from agents.memory import OpenAIResponsesCompactionSession

underlying = SQLiteSession("conversation_123")
session = OpenAIResponsesCompactionSession(
    session_id="conversation_123",
    underlying_session=underlying,
)

agent = Agent(name="Assistant")
result = await Runner.run(agent, "Hello", session=session)
print(result.final_output)
```

By default, compaction runs after each turn once the candidate threshold is reached.

`compaction_mode="previous_response_id"` works best when you are already chaining turns with Responses API response IDs. `compaction_mode="input"` rebuilds the compaction request from the current session items instead, which is useful when the response chain is unavailable or you want the session contents to be the source of truth. The default `"auto"` chooses the safest available option.

#### auto-compaction can block streaming

Compaction clears and rewrites the session history, so the SDK waits for compaction to finish before considering the run complete. In streaming mode, this means `run.stream_events()` can stay open for a few seconds after the last output token if compaction is heavy.

If you want low-latency streaming or fast turn-taking, disable auto-compaction and call `run_compaction()` yourself between turns (or during idle time). You can decide when to force compaction based on your own criteria.

```python
from agents import Agent, Runner, SQLiteSession
from agents.memory import OpenAIResponsesCompactionSession

underlying = SQLiteSession("conversation_123")
session = OpenAIResponsesCompactionSession(
    session_id="conversation_123",
    underlying_session=underlying,
    # Disable triggering the auto compaction
    should_trigger_compaction=lambda _: False,
)

agent = Agent(name="Assistant")
result = await Runner.run(agent, "Hello", session=session)

# Decide when to compact (e.g., on idle, every N turns, or size thresholds).
await session.run_compaction({"force": True})
```

### SQLite sessions

The default, lightweight session implementation using SQLite:

```python
from agents import SQLiteSession

# In-memory database (lost when process ends)
session = SQLiteSession("user_123")

# Persistent file-based database
session = SQLiteSession("user_123", "conversations.db")

# Use the session
result = await Runner.run(
    agent,
    "Hello",
    session=session
)
```

### Async SQLite sessions

Use `AsyncSQLiteSession` when you want SQLite persistence backed by `aiosqlite`.

```bash
pip install aiosqlite
```

```python
from agents import Agent, Runner
from agents.extensions.memory import AsyncSQLiteSession

agent = Agent(name="Assistant")
session = AsyncSQLiteSession("user_123", db_path="conversations.db")
result = await Runner.run(agent, "Hello", session=session)
```

### Redis sessions

Use `RedisSession` for shared session memory across multiple workers or services.

```bash
pip install openai-agents[redis]
```

```python
from agents import Agent, Runner
from agents.extensions.memory import RedisSession

agent = Agent(name="Assistant")
session = RedisSession.from_url(
    "user_123",
    url="redis://localhost:6379/0",
)
result = await Runner.run(agent, "Hello", session=session)
```

### SQLAlchemy sessions

Production-ready sessions using any SQLAlchemy-supported database:

```python
from agents.extensions.memory import SQLAlchemySession

# Using database URL
session = SQLAlchemySession.from_url(
    "user_123",
    url="postgresql+asyncpg://user:pass@localhost/db",
    create_tables=True
)

# Using existing engine
from sqlalchemy.ext.asyncio import create_async_engine
engine = create_async_engine("postgresql+asyncpg://user:pass@localhost/db")
session = SQLAlchemySession("user_123", engine=engine, create_tables=True)
```

See [SQLAlchemy Sessions](sqlalchemy_session.md) for detailed documentation.

### Dapr sessions

Use `DaprSession` when you already run Dapr sidecars or want session storage that can move across different state-store backends without changing your agent code.

```bash
pip install openai-agents[dapr]
```

```python
from agents import Agent, Runner
from agents.extensions.memory import DaprSession

agent = Agent(name="Assistant")

async with DaprSession.from_address(
    "user_123",
    state_store_name="statestore",
    dapr_address="localhost:50001",
) as session:
    result = await Runner.run(agent, "Hello", session=session)
    print(result.final_output)
```

Notes:

-   `from_address(...)` creates and owns the Dapr client for you. If your app already manages one, construct `DaprSession(...)` directly with `dapr_client=...`.
-   Pass `ttl=...` to let the backing state store expire old session data automatically when the store supports TTL.
-   Pass `consistency=DAPR_CONSISTENCY_STRONG` when you need stronger read-after-write guarantees.
-   The Dapr Python SDK also checks the HTTP sidecar endpoint. In local development, start Dapr with `--dapr-http-port 3500` as well as the gRPC port used in `dapr_address`.
-   See [`examples/memory/dapr_session_example.py`](https://github.com/openai/openai-agents-python/tree/main/examples/memory/dapr_session_example.py) for a full setup walkthrough, including local components and troubleshooting.


### Advanced SQLite sessions

Enhanced SQLite sessions with conversation branching, usage analytics, and structured queries:

```python
from agents.extensions.memory import AdvancedSQLiteSession

# Create with advanced features
session = AdvancedSQLiteSession(
    session_id="user_123",
    db_path="conversations.db",
    create_tables=True
)

# Automatic usage tracking
result = await Runner.run(agent, "Hello", session=session)
await session.store_run_usage(result)  # Track token usage

# Conversation branching
await session.create_branch_from_turn(2)  # Branch from turn 2
```

See [Advanced SQLite Sessions](advanced_sqlite_session.md) for detailed documentation.

### Encrypted sessions

Transparent encryption wrapper for any session implementation:

```python
from agents.extensions.memory import EncryptedSession, SQLAlchemySession

# Create underlying session
underlying_session = SQLAlchemySession.from_url(
    "user_123",
    url="sqlite+aiosqlite:///conversations.db",
    create_tables=True
)

# Wrap with encryption and TTL
session = EncryptedSession(
    session_id="user_123",
    underlying_session=underlying_session,
    encryption_key="your-secret-key",
    ttl=600  # 10 minutes
)

result = await Runner.run(agent, "Hello", session=session)
```

See [Encrypted Sessions](encrypted_session.md) for detailed documentation.

### Other session types

There are a few more built-in options. Please refer to `examples/memory/` and source code under `extensions/memory/`.

## Operational patterns

### Session ID naming

Use meaningful session IDs that help you organize conversations:

-   User-based: `"user_12345"`
-   Thread-based: `"thread_abc123"`
-   Context-based: `"support_ticket_456"`

### Memory persistence

-   Use in-memory SQLite (`SQLiteSession("session_id")`) for temporary conversations
-   Use file-based SQLite (`SQLiteSession("session_id", "path/to/db.sqlite")`) for persistent conversations
-   Use async SQLite (`AsyncSQLiteSession("session_id", db_path="...")`) when you need an `aiosqlite`-based implementation
-   Use Redis-backed sessions (`RedisSession.from_url("session_id", url="redis://...")`) for shared, low-latency session memory
-   Use SQLAlchemy-powered sessions (`SQLAlchemySession("session_id", engine=engine, create_tables=True)`) for production systems with existing databases supported by SQLAlchemy
-   Use Dapr state store sessions (`DaprSession.from_address("session_id", state_store_name="statestore", dapr_address="localhost:50001")`) for production cloud-native deployments with support for 30+ database backends with built-in telemetry, tracing, and data isolation
-   Use OpenAI-hosted storage (`OpenAIConversationsSession()`) when you prefer to store history in the OpenAI Conversations API
-   Use encrypted sessions (`EncryptedSession(session_id, underlying_session, encryption_key)`) to wrap any session with transparent encryption and TTL-based expiration
-   Consider implementing custom session backends for other production systems (for example, Django) for more advanced use cases

### Multiple sessions

```python
from agents import Agent, Runner, SQLiteSession

agent = Agent(name="Assistant")

# Different sessions maintain separate conversation histories
session_1 = SQLiteSession("user_123", "conversations.db")
session_2 = SQLiteSession("user_456", "conversations.db")

result1 = await Runner.run(
    agent,
    "Help me with my account",
    session=session_1
)
result2 = await Runner.run(
    agent,
    "What are my charges?",
    session=session_2
)
```

### Session sharing

```python
# Different agents can share the same session
support_agent = Agent(name="Support")
billing_agent = Agent(name="Billing")
session = SQLiteSession("user_123")

# Both agents will see the same conversation history
result1 = await Runner.run(
    support_agent,
    "Help me with my account",
    session=session
)
result2 = await Runner.run(
    billing_agent,
    "What are my charges?",
    session=session
)
```

## Complete example

Here's a complete example showing session memory in action:

```python
import asyncio
from agents import Agent, Runner, SQLiteSession


async def main():
    # Create an agent
    agent = Agent(
        name="Assistant",
        instructions="Reply very concisely.",
    )

    # Create a session instance that will persist across runs
    session = SQLiteSession("conversation_123", "conversation_history.db")

    print("=== Sessions Example ===")
    print("The agent will remember previous messages automatically.\n")

    # First turn
    print("First turn:")
    print("User: What city is the Golden Gate Bridge in?")
    result = await Runner.run(
        agent,
        "What city is the Golden Gate Bridge in?",
        session=session
    )
    print(f"Assistant: {result.final_output}")
    print()

    # Second turn - the agent will remember the previous conversation
    print("Second turn:")
    print("User: What state is it in?")
    result = await Runner.run(
        agent,
        "What state is it in?",
        session=session
    )
    print(f"Assistant: {result.final_output}")
    print()

    # Third turn - continuing the conversation
    print("Third turn:")
    print("User: What's the population of that state?")
    result = await Runner.run(
        agent,
        "What's the population of that state?",
        session=session
    )
    print(f"Assistant: {result.final_output}")
    print()

    print("=== Conversation Complete ===")
    print("Notice how the agent remembered the context from previous turns!")
    print("Sessions automatically handles conversation history.")


if __name__ == "__main__":
    asyncio.run(main())
```

## Custom session implementations

You can implement your own session memory by creating a class that follows the [`Session`][agents.memory.session.Session] protocol:

```python
from agents.memory.session import SessionABC
from agents.items import TResponseInputItem
from typing import List

class MyCustomSession(SessionABC):
    """Custom session implementation following the Session protocol."""

    def __init__(self, session_id: str):
        self.session_id = session_id
        # Your initialization here

    async def get_items(self, limit: int | None = None) -> List[TResponseInputItem]:
        """Retrieve conversation history for this session."""
        # Your implementation here
        pass

    async def add_items(self, items: List[TResponseInputItem]) -> None:
        """Store new items for this session."""
        # Your implementation here
        pass

    async def pop_item(self) -> TResponseInputItem | None:
        """Remove and return the most recent item from this session."""
        # Your implementation here
        pass

    async def clear_session(self) -> None:
        """Clear all items for this session."""
        # Your implementation here
        pass

# Use your custom session
agent = Agent(name="Assistant")
result = await Runner.run(
    agent,
    "Hello",
    session=MyCustomSession("my_session")
)
```

## Community session implementations

The community has developed additional session implementations:

| Package | Description |
|---------|-------------|
| [openai-django-sessions](https://pypi.org/project/openai-django-sessions/) | Django ORM-based sessions for any Django-supported database (PostgreSQL, MySQL, SQLite, and more) |

If you've built a session implementation, please feel free to submit a documentation PR to add it here!

## API reference

For detailed API documentation, see:

-   [`Session`][agents.memory.session.Session] - Protocol interface
-   [`OpenAIConversationsSession`][agents.memory.OpenAIConversationsSession] - OpenAI Conversations API implementation
-   [`OpenAIResponsesCompactionSession`][agents.memory.openai_responses_compaction_session.OpenAIResponsesCompactionSession] - Responses API compaction wrapper
-   [`SQLiteSession`][agents.memory.sqlite_session.SQLiteSession] - Basic SQLite implementation
-   [`AsyncSQLiteSession`][agents.extensions.memory.async_sqlite_session.AsyncSQLiteSession] - Async SQLite implementation based on `aiosqlite`
-   [`RedisSession`][agents.extensions.memory.redis_session.RedisSession] - Redis-backed session implementation
-   [`SQLAlchemySession`][agents.extensions.memory.sqlalchemy_session.SQLAlchemySession] - SQLAlchemy-powered implementation
-   [`DaprSession`][agents.extensions.memory.dapr_session.DaprSession] - Dapr state store implementation
-   [`AdvancedSQLiteSession`][agents.extensions.memory.advanced_sqlite_session.AdvancedSQLiteSession] - Enhanced SQLite with branching and analytics
-   [`EncryptedSession`][agents.extensions.memory.encrypt_session.EncryptedSession] - Encrypted wrapper for any session

================
File: docs/sessions/sqlalchemy_session.md
================
# SQLAlchemy sessions

`SQLAlchemySession` uses SQLAlchemy to provide a production-ready session implementation, allowing you to use any database supported by SQLAlchemy (PostgreSQL, MySQL, SQLite, etc.) for session storage.

## Installation

SQLAlchemy sessions require the `sqlalchemy` extra:

```bash
pip install openai-agents[sqlalchemy]
```

## Quick start

### Using database URL

The simplest way to get started:

```python
import asyncio
from agents import Agent, Runner
from agents.extensions.memory import SQLAlchemySession

async def main():
    agent = Agent("Assistant")
    
    # Create session using database URL
    session = SQLAlchemySession.from_url(
        "user-123",
        url="sqlite+aiosqlite:///:memory:",
        create_tables=True
    )
    
    result = await Runner.run(agent, "Hello", session=session)
    print(result.final_output)

if __name__ == "__main__":
    asyncio.run(main())
```

### Using existing engine

For applications with existing SQLAlchemy engines:

```python
import asyncio
from agents import Agent, Runner
from agents.extensions.memory import SQLAlchemySession
from sqlalchemy.ext.asyncio import create_async_engine

async def main():
    # Create your database engine
    engine = create_async_engine("postgresql+asyncpg://user:pass@localhost/db")
    
    agent = Agent("Assistant")
    session = SQLAlchemySession(
        "user-456",
        engine=engine,
        create_tables=True
    )
    
    result = await Runner.run(agent, "Hello", session=session)
    print(result.final_output)
    
    # Clean up
    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(main())
```


## API reference

- [`SQLAlchemySession`][agents.extensions.memory.sqlalchemy_session.SQLAlchemySession] - Main class
- [`Session`][agents.memory.session.Session] - Base session protocol

================
File: docs/voice/pipeline.md
================
# Pipelines and workflows

[`VoicePipeline`][agents.voice.pipeline.VoicePipeline] is a class that makes it easy to turn your agentic workflows into a voice app. You pass in a workflow to run, and the pipeline takes care of transcribing input audio, detecting when the audio ends, calling your workflow at the right time, and turning the workflow output back into audio.

```mermaid
graph LR
    %% Input
    A["🎤 Audio Input"]

    %% Voice Pipeline
    subgraph Voice_Pipeline [Voice Pipeline]
        direction TB
        B["Transcribe (speech-to-text)"]
        C["Your Code"]:::highlight
        D["Text-to-speech"]
        B --> C --> D
    end

    %% Output
    E["🎧 Audio Output"]

    %% Flow
    A --> Voice_Pipeline
    Voice_Pipeline --> E

    %% Custom styling
    classDef highlight fill:#ffcc66,stroke:#333,stroke-width:1px,font-weight:700;

```

## Configuring a pipeline

When you create a pipeline, you can set a few things:

1. The [`workflow`][agents.voice.workflow.VoiceWorkflowBase], which is the code that runs each time new audio is transcribed.
2. The [`speech-to-text`][agents.voice.model.STTModel] and [`text-to-speech`][agents.voice.model.TTSModel] models used
3. The [`config`][agents.voice.pipeline_config.VoicePipelineConfig], which lets you configure things like:
    - A model provider, which can map model names to models
    - Tracing, including whether to disable tracing, whether audio files are uploaded, the workflow name, trace IDs etc.
    - Settings on the TTS and STT models, like the prompt, language and data types used.

## Running a pipeline

You can run a pipeline via the [`run()`][agents.voice.pipeline.VoicePipeline.run] method, which lets you pass in audio input in two forms:

1. [`AudioInput`][agents.voice.input.AudioInput] is used when you have a full audio transcript, and just want to produce a result for it. This is useful in cases where you don't need to detect when a speaker is done speaking; for example, when you have pre-recorded audio or in push-to-talk apps where it's clear when the user is done speaking.
2. [`StreamedAudioInput`][agents.voice.input.StreamedAudioInput] is used when you might need to detect when a user is done speaking. It allows you to push audio chunks as they are detected, and the voice pipeline will automatically run the agent workflow at the right time, via a process called "activity detection".

## Results

The result of a voice pipeline run is a [`StreamedAudioResult`][agents.voice.result.StreamedAudioResult]. This is an object that lets you stream events as they occur. There are a few kinds of [`VoiceStreamEvent`][agents.voice.events.VoiceStreamEvent], including:

1. [`VoiceStreamEventAudio`][agents.voice.events.VoiceStreamEventAudio], which contains a chunk of audio.
2. [`VoiceStreamEventLifecycle`][agents.voice.events.VoiceStreamEventLifecycle], which informs you of lifecycle events like a turn starting or ending.
3. [`VoiceStreamEventError`][agents.voice.events.VoiceStreamEventError], is an error event.

```python

result = await pipeline.run(input)

async for event in result.stream():
    if event.type == "voice_stream_event_audio":
        # play audio
    elif event.type == "voice_stream_event_lifecycle":
        # lifecycle
    elif event.type == "voice_stream_event_error":
        # error
    ...
```

## Best practices

### Interruptions

The Agents SDK currently does not support any built-in interruptions support for [`StreamedAudioInput`][agents.voice.input.StreamedAudioInput]. Instead for every detected turn it will trigger a separate run of your workflow. If you want to handle interruptions inside your application you can listen to the [`VoiceStreamEventLifecycle`][agents.voice.events.VoiceStreamEventLifecycle] events. `turn_started` will indicate that a new turn was transcribed and processing is beginning. `turn_ended` will trigger after all the audio was dispatched for a respective turn. You could use these events to mute the microphone of the speaker when the model starts a turn and unmute it after you flushed all the related audio for a turn.

================
File: docs/voice/quickstart.md
================
# Quickstart

## Prerequisites

Make sure you've followed the base [quickstart instructions](../quickstart.md) for the Agents SDK, and set up a virtual environment. Then, install the optional voice dependencies from the SDK:

```bash
pip install 'openai-agents[voice]'
```

## Concepts

The main concept to know about is a [`VoicePipeline`][agents.voice.pipeline.VoicePipeline], which is a 3 step process:

1. Run a speech-to-text model to turn audio into text.
2. Run your code, which is usually an agentic workflow, to produce a result.
3. Run a text-to-speech model to turn the result text back into audio.

```mermaid
graph LR
    %% Input
    A["🎤 Audio Input"]

    %% Voice Pipeline
    subgraph Voice_Pipeline [Voice Pipeline]
        direction TB
        B["Transcribe (speech-to-text)"]
        C["Your Code"]:::highlight
        D["Text-to-speech"]
        B --> C --> D
    end

    %% Output
    E["🎧 Audio Output"]

    %% Flow
    A --> Voice_Pipeline
    Voice_Pipeline --> E

    %% Custom styling
    classDef highlight fill:#ffcc66,stroke:#333,stroke-width:1px,font-weight:700;

```

## Agents

First, let's set up some Agents. This should feel familiar to you if you've built any agents with this SDK. We'll have a couple of Agents, a handoff, and a tool.

```python
import asyncio
import random

from agents import (
    Agent,
    function_tool,
)
from agents.extensions.handoff_prompt import prompt_with_handoff_instructions



@function_tool
def get_weather(city: str) -> str:
    """Get the weather for a given city."""
    print(f"[debug] get_weather called with city: {city}")
    choices = ["sunny", "cloudy", "rainy", "snowy"]
    return f"The weather in {city} is {random.choice(choices)}."


spanish_agent = Agent(
    name="Spanish",
    handoff_description="A spanish speaking agent.",
    instructions=prompt_with_handoff_instructions(
        "You're speaking to a human, so be polite and concise. Speak in Spanish.",
    ),
    model="gpt-5.2",
)

agent = Agent(
    name="Assistant",
    instructions=prompt_with_handoff_instructions(
        "You're speaking to a human, so be polite and concise. If the user speaks in Spanish, handoff to the spanish agent.",
    ),
    model="gpt-5.2",
    handoffs=[spanish_agent],
    tools=[get_weather],
)
```

## Voice pipeline

We'll set up a simple voice pipeline, using [`SingleAgentVoiceWorkflow`][agents.voice.workflow.SingleAgentVoiceWorkflow] as the workflow.

```python
from agents.voice import SingleAgentVoiceWorkflow, VoicePipeline
pipeline = VoicePipeline(workflow=SingleAgentVoiceWorkflow(agent))
```

## Run the pipeline

```python
import numpy as np
import sounddevice as sd
from agents.voice import AudioInput

# For simplicity, we'll just create 3 seconds of silence
# In reality, you'd get microphone data
buffer = np.zeros(24000 * 3, dtype=np.int16)
audio_input = AudioInput(buffer=buffer)

result = await pipeline.run(audio_input)

# Create an audio player using `sounddevice`
player = sd.OutputStream(samplerate=24000, channels=1, dtype=np.int16)
player.start()

# Play the audio stream as it comes in
async for event in result.stream():
    if event.type == "voice_stream_event_audio":
        player.write(event.data)

```

## Put it all together

```python
import asyncio
import random

import numpy as np
import sounddevice as sd

from agents import (
    Agent,
    function_tool,
    set_tracing_disabled,
)
from agents.voice import (
    AudioInput,
    SingleAgentVoiceWorkflow,
    VoicePipeline,
)
from agents.extensions.handoff_prompt import prompt_with_handoff_instructions


@function_tool
def get_weather(city: str) -> str:
    """Get the weather for a given city."""
    print(f"[debug] get_weather called with city: {city}")
    choices = ["sunny", "cloudy", "rainy", "snowy"]
    return f"The weather in {city} is {random.choice(choices)}."


spanish_agent = Agent(
    name="Spanish",
    handoff_description="A spanish speaking agent.",
    instructions=prompt_with_handoff_instructions(
        "You're speaking to a human, so be polite and concise. Speak in Spanish.",
    ),
    model="gpt-5.2",
)

agent = Agent(
    name="Assistant",
    instructions=prompt_with_handoff_instructions(
        "You're speaking to a human, so be polite and concise. If the user speaks in Spanish, handoff to the spanish agent.",
    ),
    model="gpt-5.2",
    handoffs=[spanish_agent],
    tools=[get_weather],
)


async def main():
    pipeline = VoicePipeline(workflow=SingleAgentVoiceWorkflow(agent))
    buffer = np.zeros(24000 * 3, dtype=np.int16)
    audio_input = AudioInput(buffer=buffer)

    result = await pipeline.run(audio_input)

    # Create an audio player using `sounddevice`
    player = sd.OutputStream(samplerate=24000, channels=1, dtype=np.int16)
    player.start()

    # Play the audio stream as it comes in
    async for event in result.stream():
        if event.type == "voice_stream_event_audio":
            player.write(event.data)


if __name__ == "__main__":
    asyncio.run(main())
```

If you run this example, the agent will speak to you! Check out the example in [examples/voice/static](https://github.com/openai/openai-agents-python/tree/main/examples/voice/static) to see a demo where you can speak to the agent yourself.

================
File: docs/voice/tracing.md
================
# Tracing

Just like the way [agents are traced](../tracing.md), voice pipelines are also automatically traced.

You can read the tracing doc above for basic tracing information, but you can additionally configure tracing of a pipeline via [`VoicePipelineConfig`][agents.voice.pipeline_config.VoicePipelineConfig].

Key tracing related fields are:

-   [`tracing_disabled`][agents.voice.pipeline_config.VoicePipelineConfig.tracing_disabled]: controls whether tracing is disabled. By default, tracing is enabled.
-   [`trace_include_sensitive_data`][agents.voice.pipeline_config.VoicePipelineConfig.trace_include_sensitive_data]: controls whether traces include potentially sensitive data, like audio transcripts. This is specifically for the voice pipeline, and not for anything that goes on inside your Workflow.
-   [`trace_include_sensitive_audio_data`][agents.voice.pipeline_config.VoicePipelineConfig.trace_include_sensitive_audio_data]: controls whether traces include audio data.
-   [`workflow_name`][agents.voice.pipeline_config.VoicePipelineConfig.workflow_name]: The name of the trace workflow.
-   [`group_id`][agents.voice.pipeline_config.VoicePipelineConfig.group_id]: The `group_id` of the trace, which lets you link multiple traces.
-   [`trace_metadata`][agents.voice.pipeline_config.VoicePipelineConfig.trace_metadata]: Additional metadata to include with the trace.

================
File: docs/zh/models/index.md
================
---
search:
  exclude: true
---
# 模型

Agents SDK 开箱即用地支持两种 OpenAI 模型形态：

-   **推荐**：[`OpenAIResponsesModel`][agents.models.openai_responses.OpenAIResponsesModel]，使用新的 [Responses API](https://platform.openai.com/docs/api-reference/responses) 调用 OpenAI API。
-   [`OpenAIChatCompletionsModel`][agents.models.openai_chatcompletions.OpenAIChatCompletionsModel]，使用 [Chat Completions API](https://platform.openai.com/docs/api-reference/chat) 调用 OpenAI API。

## 模型设置选择

根据你的设置，按以下顺序使用本页：

| 目标 | 从这里开始 |
| --- | --- |
| 使用 SDK 默认设置的 OpenAI 托管模型 | [OpenAI 模型](#openai-models) |
| 通过 websocket 传输使用 OpenAI Responses API | [Responses WebSocket 传输](#responses-websocket-transport) |
| 使用非 OpenAI 提供方 | [非 OpenAI 模型](#non-openai-models) |
| 在一个工作流中混用模型/提供方 | [高级模型选择与混用](#advanced-model-selection-and-mixing) 和 [跨提供方混用模型](#mixing-models-across-providers) |
| 调试提供方兼容性问题 | [非 OpenAI 提供方故障排查](#troubleshooting-non-openai-providers) |

## OpenAI 模型

当你初始化 `Agent` 时未指定模型，将使用默认模型。当前默认值为 [`gpt-4.1`](https://platform.openai.com/docs/models/gpt-4.1)，以兼顾兼容性和低延迟。如果你有权限，我们建议将智能体设置为 [`gpt-5.2`](https://platform.openai.com/docs/models/gpt-5.2) 以获得更高质量，同时显式设置 `model_settings`。

如果你想切换到其他模型（如 [`gpt-5.2`](https://platform.openai.com/docs/models/gpt-5.2)），有两种方式配置智能体。

### 默认模型

首先，如果你希望所有未设置自定义模型的智能体始终使用某个特定模型，请在运行智能体前设置 `OPENAI_DEFAULT_MODEL` 环境变量。

```bash
export OPENAI_DEFAULT_MODEL=gpt-5.2
python3 my_awesome_agent.py
```

其次，你可以通过 `RunConfig` 为一次运行设置默认模型。如果你未为某个智能体设置模型，将使用此次运行的模型。

```python
from agents import Agent, RunConfig, Runner

agent = Agent(
    name="Assistant",
    instructions="You're a helpful agent.",
)

result = await Runner.run(
    agent,
    "Hello",
    run_config=RunConfig(model="gpt-5.2"),
)
```

#### GPT-5.x 模型

当你以这种方式使用任意 GPT-5.x 模型（如 [`gpt-5.2`](https://platform.openai.com/docs/models/gpt-5.2)）时，SDK 会应用默认 `ModelSettings`。它会设置在大多数用例下表现最好的配置。若要调整默认模型的推理强度，请传入你自己的 `ModelSettings`：

```python
from openai.types.shared import Reasoning
from agents import Agent, ModelSettings

my_agent = Agent(
    name="My Agent",
    instructions="You're a helpful agent.",
    # If OPENAI_DEFAULT_MODEL=gpt-5.2 is set, passing only model_settings works.
    # It's also fine to pass a GPT-5.x model name explicitly:
    model="gpt-5.2",
    model_settings=ModelSettings(reasoning=Reasoning(effort="high"), verbosity="low")
)
```

为获得更低延迟，建议在 `gpt-5.2` 上使用 `reasoning.effort="none"`。gpt-4.1 系列（包括 mini 和 nano 变体）也仍是构建交互式智能体应用的可靠选择。

#### 非 GPT-5 模型

如果你传入非 GPT-5 模型名称且未提供自定义 `model_settings`，SDK 会回退到与任意模型兼容的通用 `ModelSettings`。

### Responses WebSocket 传输

默认情况下，OpenAI Responses API 请求使用 HTTP 传输。使用 OpenAI 支持的模型时，你可以选择启用 websocket 传输。

```python
from agents import set_default_openai_responses_transport

set_default_openai_responses_transport("websocket")
```

这会影响由默认 OpenAI 提供方解析的 OpenAI Responses 模型（包括字符串模型名，如 `"gpt-5.2"`）。

传输方式的选择发生在 SDK 将模型名称解析为模型实例时。如果你传入具体的 [`Model`][agents.models.interface.Model] 对象，其传输方式已固定：[`OpenAIResponsesWSModel`][agents.models.openai_responses.OpenAIResponsesWSModel] 使用 websocket，[`OpenAIResponsesModel`][agents.models.openai_responses.OpenAIResponsesModel] 使用 HTTP，[`OpenAIChatCompletionsModel`][agents.models.openai_chatcompletions.OpenAIChatCompletionsModel] 则保持 Chat Completions。若你传入 `RunConfig(model_provider=...)`，则由该提供方控制传输选择，而不是全局默认值。

你还可以按提供方或按运行配置 websocket 传输：

```python
from agents import Agent, OpenAIProvider, RunConfig, Runner

provider = OpenAIProvider(
    use_responses_websocket=True,
    # Optional; if omitted, OPENAI_WEBSOCKET_BASE_URL is used when set.
    websocket_base_url="wss://your-proxy.example/v1",
)

agent = Agent(name="Assistant")
result = await Runner.run(
    agent,
    "Hello",
    run_config=RunConfig(model_provider=provider),
)
```

如果你需要基于前缀的模型路由（例如在一次运行中混用 `openai/...` 和 `litellm/...` 模型名），请改用 [`MultiProvider`][agents.MultiProvider]，并在其中设置 `openai_use_responses_websocket=True`。

如果你使用自定义 OpenAI 兼容端点或代理，websocket 传输还要求有兼容的 websocket `/responses` 端点。在这些设置下，你可能需要显式设置 `websocket_base_url`。

注意：

-   这是基于 websocket 传输的 Responses API，不是 [Realtime API](../realtime/guide.md)。除非支持 Responses websocket `/responses` 端点，否则它不适用于 Chat Completions 或非 OpenAI 提供方。
-   如果你的环境中尚未安装，请安装 `websockets` 包。
-   启用 websocket 传输后，你可以直接使用 [`Runner.run_streamed()`][agents.run.Runner.run_streamed]。对于希望在多轮工作流中复用同一 websocket 连接（以及嵌套的 agent-as-tool 调用）的场景，建议使用 [`responses_websocket_session()`][agents.responses_websocket_session] 辅助方法。参见 [运行智能体](../running_agents.md) 指南和 [`examples/basic/stream_ws.py`](https://github.com/openai/openai-agents-python/tree/main/examples/basic/stream_ws.py)。

## 非 OpenAI 模型

你可以通过 [LiteLLM 集成](./litellm.md) 使用大多数其他非 OpenAI 模型。首先，安装 litellm 依赖组：

```bash
pip install "openai-agents[litellm]"
```

然后，使用任意[受支持模型](https://docs.litellm.ai/docs/providers)，并加上 `litellm/` 前缀：

```python
claude_agent = Agent(model="litellm/anthropic/claude-3-5-sonnet-20240620", ...)
gemini_agent = Agent(model="litellm/gemini/gemini-2.5-flash-preview-04-17", ...)
```

### 使用非 OpenAI 模型的其他方式

你还可以通过另外 3 种方式集成其他 LLM 提供方（代码示例见[这里](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/)）：

1. [`set_default_openai_client`][agents.set_default_openai_client] 适用于你希望在全局使用某个 `AsyncOpenAI` 实例作为 LLM 客户端的场景。适用于 LLM 提供方提供 OpenAI 兼容 API 端点，且你可以设置 `base_url` 和 `api_key` 的情况。可配置示例见 [examples/model_providers/custom_example_global.py](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/custom_example_global.py)。
2. [`ModelProvider`][agents.models.interface.ModelProvider] 位于 `Runner.run` 层级。这让你可以指定“在本次运行中所有智能体都使用自定义模型提供方”。可配置示例见 [examples/model_providers/custom_example_provider.py](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/custom_example_provider.py)。
3. [`Agent.model`][agents.agent.Agent.model] 允许你在特定 Agent 实例上指定模型。这让你可以为不同智能体混合搭配不同提供方。可配置示例见 [examples/model_providers/custom_example_agent.py](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/custom_example_agent.py)。使用大多数可用模型的简便方式是通过 [LiteLLM 集成](./litellm.md)。

在你没有来自 `platform.openai.com` 的 API key 时，我们建议通过 `set_tracing_disabled()` 禁用追踪，或设置[不同的追踪进程](../tracing.md)。

!!! note

    在这些示例中，我们使用 Chat Completions API/模型，因为大多数 LLM 提供方尚不支持 Responses API。如果你的 LLM 提供方支持，我们建议使用 Responses。

## 高级模型选择与混用

在单个工作流中，你可能希望为每个智能体使用不同模型。例如，你可以在分流阶段使用更小、更快的模型，而在复杂任务中使用更大、能力更强的模型。配置 [`Agent`][agents.Agent] 时，你可以通过以下方式之一选择特定模型：

1. 传入模型名称。
2. 传入任意模型名称 + 可将该名称映射为 Model 实例的 [`ModelProvider`][agents.models.interface.ModelProvider]。
3. 直接提供一个 [`Model`][agents.models.interface.Model] 实现。

!!!note

    虽然我们的 SDK 同时支持 [`OpenAIResponsesModel`][agents.models.openai_responses.OpenAIResponsesModel] 和 [`OpenAIChatCompletionsModel`][agents.models.openai_chatcompletions.OpenAIChatCompletionsModel] 两种形态，但我们建议每个工作流使用单一模型形态，因为两种形态支持的功能和工具集合不同。如果你的工作流必须混用模型形态，请确保你使用的所有功能在两者中都可用。

```python
from agents import Agent, Runner, AsyncOpenAI, OpenAIChatCompletionsModel
import asyncio

spanish_agent = Agent(
    name="Spanish agent",
    instructions="You only speak Spanish.",
    model="gpt-5-mini", # (1)!
)

english_agent = Agent(
    name="English agent",
    instructions="You only speak English",
    model=OpenAIChatCompletionsModel( # (2)!
        model="gpt-5-nano",
        openai_client=AsyncOpenAI()
    ),
)

triage_agent = Agent(
    name="Triage agent",
    instructions="Handoff to the appropriate agent based on the language of the request.",
    handoffs=[spanish_agent, english_agent],
    model="gpt-5",
)

async def main():
    result = await Runner.run(triage_agent, input="Hola, ¿cómo estás?")
    print(result.final_output)
```

1.  直接设置 OpenAI 模型名称。
2.  提供一个 [`Model`][agents.models.interface.Model] 实现。

当你希望进一步配置智能体使用的模型时，可以传入 [`ModelSettings`][agents.models.interface.ModelSettings]，它提供了如 temperature 等可选模型配置参数。

```python
from agents import Agent, ModelSettings

english_agent = Agent(
    name="English agent",
    instructions="You only speak English",
    model="gpt-4.1",
    model_settings=ModelSettings(temperature=0.1),
)
```

#### 常见高级 `ModelSettings` 选项

当你使用 OpenAI Responses API 时，多个请求字段在 `ModelSettings` 中已有直接对应字段，因此无需为它们使用 `extra_args`。

| 字段 | 用途 |
| --- | --- |
| `parallel_tool_calls` | 允许或禁止在同一轮中进行多个工具调用。 |
| `truncation` | 设为 `"auto"`，可让 Responses API 在上下文将溢出时丢弃最旧的会话项，而不是直接失败。 |
| `prompt_cache_retention` | 让已缓存的提示词前缀保留更久，例如设为 `"24h"`。 |
| `response_include` | 请求更丰富的响应负载，例如 `web_search_call.action.sources`、`file_search_call.results` 或 `reasoning.encrypted_content`。 |
| `top_logprobs` | 为输出文本请求 top-token logprobs。SDK 也会自动添加 `message.output_text.logprobs`。 |

```python
from agents import Agent, ModelSettings

research_agent = Agent(
    name="Research agent",
    model="gpt-5.2",
    model_settings=ModelSettings(
        parallel_tool_calls=False,
        truncation="auto",
        prompt_cache_retention="24h",
        response_include=["web_search_call.action.sources"],
        top_logprobs=5,
    ),
)
```

当你需要提供方特有字段，或 SDK 尚未在顶层直接暴露的较新请求字段时，请使用 `extra_args`。

另外，当你使用 OpenAI 的 Responses API 时，[还有一些其他可选参数](https://platform.openai.com/docs/api-reference/responses/create)（例如 `user`、`service_tier` 等）。如果它们在顶层不可用，也可以通过 `extra_args` 传入。

```python
from agents import Agent, ModelSettings

english_agent = Agent(
    name="English agent",
    instructions="You only speak English",
    model="gpt-4.1",
    model_settings=ModelSettings(
        temperature=0.1,
        extra_args={"service_tier": "flex", "user": "user_12345"},
    ),
)
```

## 非 OpenAI 提供方故障排查

### 追踪客户端错误 401

如果你遇到与追踪相关的错误，这是因为追踪数据会上传到 OpenAI 服务，而你没有 OpenAI API key。你有三种解决方式：

1. 完全禁用追踪：[`set_tracing_disabled(True)`][agents.set_tracing_disabled]。
2. 为追踪设置 OpenAI key：[`set_tracing_export_api_key(...)`][agents.set_tracing_export_api_key]。此 API key 仅用于上传追踪数据，且必须来自 [platform.openai.com](https://platform.openai.com/)。
3. 使用非 OpenAI 的追踪进程。参见[追踪文档](../tracing.md#custom-tracing-processors)。

### Responses API 支持

SDK 默认使用 Responses API，但大多数其他 LLM 提供方尚不支持。因此你可能会看到 404 或类似问题。你有两种解决方式：

1. 调用 [`set_default_openai_api("chat_completions")`][agents.set_default_openai_api]。当你通过环境变量设置 `OPENAI_API_KEY` 和 `OPENAI_BASE_URL` 时可用。
2. 使用 [`OpenAIChatCompletionsModel`][agents.models.openai_chatcompletions.OpenAIChatCompletionsModel]。代码示例见[这里](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/)。

### structured outputs 支持

某些模型提供方不支持 [structured outputs](https://platform.openai.com/docs/guides/structured-outputs)。这有时会导致类似如下错误：

```

BadRequestError: Error code: 400 - {'error': {'message': "'response_format.type' : value is not one of the allowed values ['text','json_object']", 'type': 'invalid_request_error'}}

```

这是某些模型提供方的短板——它们支持 JSON 输出，但不允许你指定用于输出的 `json_schema`。我们正在修复这一问题，但建议你依赖支持 JSON schema 输出的提供方，否则应用经常会因 JSON 格式错误而中断。

## 跨提供方混用模型

你需要了解不同模型提供方的功能差异，否则可能遇到错误。例如，OpenAI 支持 structured outputs、多模态输入，以及托管式文件检索和网络检索，但许多其他提供方不支持这些功能。请注意以下限制：

-   不要向不支持的提供方发送其无法理解的 `tools`
-   在调用纯文本模型前，过滤掉多模态输入
-   注意：不支持结构化 JSON 输出的提供方会偶尔产生无效 JSON

================
File: docs/zh/models/litellm.md
================
---
search:
  exclude: true
---
# 通过 LiteLLM 使用任意模型

!!! note

    LiteLLM 集成处于测试版。您可能会在某些模型提供商（尤其是较小的提供商）上遇到问题。请通过 [Github issues](https://github.com/openai/openai-agents-python/issues) 报告问题，我们会尽快修复。

[LiteLLM](https://docs.litellm.ai/docs/) 是一个库，允许您通过统一接口使用 100+ 款模型。我们在 Agents SDK 中加入了 LiteLLM 集成，以便您使用任意 AI 模型。

## 设置

您需要确保可用 `litellm`。可以通过安装可选的 `litellm` 依赖组实现：

```bash
pip install "openai-agents[litellm]"
```

完成后，您可以在任意智能体中使用 [`LitellmModel`][agents.extensions.models.litellm_model.LitellmModel]。

## 示例

这是一个可直接运行的示例。运行时会提示输入模型名称和 API 密钥。例如，您可以输入：

-   模型使用 `openai/gpt-4.1`，并提供您的 OpenAI API 密钥
-   模型使用 `anthropic/claude-3-5-sonnet-20240620`，并提供您的 Anthropic API 密钥
-   等等

有关 LiteLLM 支持的完整模型列表，请参见 [litellm providers 文档](https://docs.litellm.ai/docs/providers)。

```python
from __future__ import annotations

import asyncio

from agents import Agent, Runner, function_tool, set_tracing_disabled
from agents.extensions.models.litellm_model import LitellmModel

@function_tool
def get_weather(city: str):
    print(f"[debug] getting weather for {city}")
    return f"The weather in {city} is sunny."


async def main(model: str, api_key: str):
    agent = Agent(
        name="Assistant",
        instructions="You only respond in haikus.",
        model=LitellmModel(model=model, api_key=api_key),
        tools=[get_weather],
    )

    result = await Runner.run(agent, "What's the weather in Tokyo?")
    print(result.final_output)


if __name__ == "__main__":
    # First try to get model/api key from args
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--model", type=str, required=False)
    parser.add_argument("--api-key", type=str, required=False)
    args = parser.parse_args()

    model = args.model
    if not model:
        model = input("Enter a model name for Litellm: ")

    api_key = args.api_key
    if not api_key:
        api_key = input("Enter an API key for Litellm: ")

    asyncio.run(main(model, api_key))
```

## 使用数据追踪

如果希望 LiteLLM 的响应填充 Agents SDK 的使用指标，请在创建智能体时传入 `ModelSettings(include_usage=True)`。

```python
from agents import Agent, ModelSettings
from agents.extensions.models.litellm_model import LitellmModel

agent = Agent(
    name="Assistant",
    model=LitellmModel(model="your/model", api_key="..."),
    model_settings=ModelSettings(include_usage=True),
)
```

使用 `include_usage=True` 后，LiteLLM 请求会通过 `result.context_wrapper.usage` 报告 token 和请求计数，与内置的 OpenAI 模型一致。

## 疑难解答

如果您看到来自 LiteLLM 响应的 Pydantic 序列化器警告，请通过设置下述选项启用一个小型兼容性补丁：

```bash
export OPENAI_AGENTS_ENABLE_LITELLM_SERIALIZER_PATCH=true
```

该自选开关会抑制已知的 LiteLLM 序列化器警告，同时保持正常行为。如果不需要，可将其关闭（未设置或 `false`）。

================
File: docs/zh/realtime/guide.md
================
---
search:
  exclude: true
---
# Realtime 智能体指南

本指南说明 OpenAI Agents SDK 的实时层如何映射到 OpenAI Realtime API，以及 Python SDK 在其之上增加了哪些额外行为。

!!! warning "Beta 功能"

    Realtime 智能体处于 beta 阶段。随着我们改进实现，预计会有一些破坏性变更。

!!! note "从这里开始"

    如果你想走默认的 Python 路径，请先阅读[快速开始](quickstart.md)。如果你在决定应用应使用服务端 WebSocket 还是 SIP，请阅读[Realtime 传输](transport.md)。浏览器 WebRTC 传输不属于 Python SDK 的一部分。

## 概览

Realtime 智能体会保持与 Realtime API 的长连接，使模型能够增量处理文本和音频、流式传输音频输出、调用工具，并在不中断每轮都重新发起新请求的情况下处理打断。

SDK 的主要组件有：

-   **RealtimeAgent**：一个实时专用智能体的 instructions、tools、输出安全防护措施和任务转移
-   **RealtimeRunner**：会话工厂，将起始智能体连接到实时传输
-   **RealtimeSession**：实时会话，发送输入、接收事件、追踪历史并执行工具
-   **RealtimeModel**：传输抽象。默认是 OpenAI 的服务端 WebSocket 实现。

## 会话生命周期

一个典型的实时会话如下：

1. 创建一个或多个 `RealtimeAgent`。
2. 使用起始智能体创建 `RealtimeRunner`。
3. 调用 `await runner.run()` 获取 `RealtimeSession`。
4. 通过 `async with session:` 或 `await session.enter()` 进入会话。
5. 使用 `send_message()` 或 `send_audio()` 发送用户输入。
6. 迭代处理会话事件，直到对话结束。

与纯文本运行不同，`runner.run()` 不会立即产生最终结果。它会返回一个实时会话对象，该对象会让本地历史、后台工具执行、安全防护状态以及活动智能体配置与传输层保持同步。

默认情况下，`RealtimeRunner` 使用 `OpenAIRealtimeWebSocketModel`，因此默认 Python 路径是到 Realtime API 的服务端 WebSocket 连接。如果你传入不同的 `RealtimeModel`，相同的会话生命周期和智能体功能仍然适用，但连接机制可发生变化。

## 智能体与会话配置

`RealtimeAgent` 有意比常规 `Agent` 类型更精简：

-   模型选择在会话级配置，而不是每个智能体配置。
-   不支持 structured outputs。
-   可以配置语音，但会话一旦已经产生语音输出后就不能再更改。
-   instructions、工具调用、任务转移、hooks 和输出安全防护措施仍然可用。

`RealtimeSessionModelSettings` 同时支持较新的嵌套 `audio` 配置和较旧的扁平别名。新代码优先使用嵌套结构：

```python
runner = RealtimeRunner(
    starting_agent=agent,
    config={
        "model_settings": {
            "model_name": "gpt-realtime",
            "audio": {
                "input": {
                    "format": "pcm16",
                    "transcription": {"model": "gpt-4o-mini-transcribe"},
                    "turn_detection": {"type": "semantic_vad", "interrupt_response": True},
                },
                "output": {"format": "pcm16", "voice": "ash"},
            },
            "tool_choice": "auto",
        }
    },
)
```

有用的会话级设置包括：

-   `audio.input.format`, `audio.output.format`
-   `audio.input.transcription`
-   `audio.input.noise_reduction`
-   `audio.input.turn_detection`
-   `audio.output.voice`, `audio.output.speed`
-   `output_modalities`
-   `tool_choice`
-   `prompt`
-   `tracing`

`RealtimeRunner(config=...)` 上有用的运行级设置包括：

-   `async_tool_calls`
-   `output_guardrails`
-   `guardrails_settings.debounce_text_length`
-   `tool_error_formatter`
-   `tracing_disabled`

完整的类型化接口请参见 [`RealtimeRunConfig`][agents.realtime.config.RealtimeRunConfig] 和 [`RealtimeSessionModelSettings`][agents.realtime.config.RealtimeSessionModelSettings]。

## 输入与输出

### 文本与结构化用户消息

对纯文本或结构化实时消息，使用 [`session.send_message()`][agents.realtime.session.RealtimeSession.send_message]。

```python
from agents.realtime import RealtimeUserInputMessage

await session.send_message("Summarize what we discussed so far.")

message: RealtimeUserInputMessage = {
    "type": "message",
    "role": "user",
    "content": [
        {"type": "input_text", "text": "Describe this image."},
        {"type": "input_image", "image_url": image_data_url, "detail": "high"},
    ],
}
await session.send_message(message)
```

结构化消息是在实时对话中包含图像输入的主要方式。[`examples/realtime/app/server.py`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/app/server.py) 中的示例 Web 演示就是通过这种方式转发 `input_image` 消息的。

### 音频输入

使用 [`session.send_audio()`][agents.realtime.session.RealtimeSession.send_audio] 流式发送原始音频字节：

```python
await session.send_audio(audio_bytes)
```

如果禁用了服务端回合检测，你需要自行标记回合边界。高层便捷方式是：

```python
await session.send_audio(audio_bytes, commit=True)
```

如果你需要更底层的控制，也可以通过底层模型传输发送原始客户端事件，例如 `input_audio_buffer.commit`。

### 手动响应控制

`session.send_message()` 通过高层路径发送用户输入，并为你启动响应。原始音频缓冲在所有配置下都**不会**自动执行同样的操作。

在 Realtime API 层面，手动回合控制意味着通过原始 `session.update` 清空 `turn_detection`，然后自行发送 `input_audio_buffer.commit` 和 `response.create`。

如果你在手动管理回合，可以通过模型传输发送原始客户端事件：

```python
from agents.realtime.model_inputs import RealtimeModelSendRawMessage

await session.model.send_event(
    RealtimeModelSendRawMessage(
        message={
            "type": "response.create",
        }
    )
)
```

该模式适用于以下情况：

-   `turn_detection` 已禁用，且你希望自行决定何时让模型响应
-   你希望在触发响应前检查或拦截用户输入
-   你需要为带外响应使用自定义提示词

[`examples/realtime/twilio_sip/server.py`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/twilio_sip/server.py) 中的 SIP 示例使用了原始 `response.create` 来强制发送开场问候。

## 事件、历史与打断

`RealtimeSession` 会发出更高层的 SDK 事件，同时在你需要时仍会转发原始模型事件。

高价值会话事件包括：

-   `audio`, `audio_end`, `audio_interrupted`
-   `agent_start`, `agent_end`
-   `tool_start`, `tool_end`, `tool_approval_required`
-   `handoff`
-   `history_added`, `history_updated`
-   `guardrail_tripped`
-   `input_audio_timeout_triggered`
-   `error`
-   `raw_model_event`

对 UI 状态最有用的事件通常是 `history_added` 和 `history_updated`。它们会以 `RealtimeItem` 对象暴露会话的本地历史，包括用户消息、助手消息和工具调用。

### 打断与播放追踪

当用户打断助手时，会话会发出 `audio_interrupted`，并更新历史，使服务端对话与用户实际听到的内容保持一致。

在低延迟本地播放中，默认播放追踪器通常已足够。在远程或延迟播放场景（尤其是电话场景）中，请使用 [`RealtimePlaybackTracker`][agents.realtime.model.RealtimePlaybackTracker]，这样打断截断会基于实际播放进度，而不是假设所有生成音频都已被听到。

[`examples/realtime/twilio/twilio_handler.py`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/twilio/twilio_handler.py) 的 Twilio 示例展示了这种模式。

## 工具、审批、任务转移与安全防护措施

### 工具调用

Realtime 智能体支持在实时对话中使用工具调用：

```python
from agents import function_tool


@function_tool
def get_weather(city: str) -> str:
    """Get current weather for a city."""
    return f"The weather in {city} is sunny, 72F."


agent = RealtimeAgent(
    name="Assistant",
    instructions="You can answer weather questions.",
    tools=[get_weather],
)
```

### 工具审批

工具调用可在执行前要求人工审批。发生这种情况时，会话会发出 `tool_approval_required`，并暂停工具运行，直到你调用 `approve_tool_call()` 或 `reject_tool_call()`。

```python
async for event in session:
    if event.type == "tool_approval_required":
        await session.approve_tool_call(event.call_id)
```

一个具体的服务端审批循环请参见 [`examples/realtime/app/server.py`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/app/server.py)。human-in-the-loop 文档也在[Human in the loop](../human_in_the_loop.md)中回指这一流程。

### 任务转移

Realtime 任务转移允许一个智能体将实时对话转交给另一个专长智能体：

```python
from agents.realtime import RealtimeAgent, realtime_handoff

billing_agent = RealtimeAgent(
    name="Billing Support",
    instructions="You specialize in billing issues.",
)

main_agent = RealtimeAgent(
    name="Customer Service",
    instructions="Triage the request and hand off when needed.",
    handoffs=[realtime_handoff(billing_agent, tool_description="Transfer to billing support")],
)
```

裸 `RealtimeAgent` 任务转移会自动包装，而 `realtime_handoff(...)` 可让你自定义名称、描述、校验、回调和可用性。Realtime 任务转移**不**支持常规任务转移的 `input_filter`。

### 安全防护措施

Realtime 智能体仅支持输出安全防护措施。它们基于去抖后的转录累积运行，而不是对每个部分 token 运行，并且会发出 `guardrail_tripped` 而不是抛出异常。

```python
from agents.guardrail import GuardrailFunctionOutput, OutputGuardrail


def sensitive_data_check(context, agent, output):
    return GuardrailFunctionOutput(
        tripwire_triggered="password" in output,
        output_info=None,
    )


agent = RealtimeAgent(
    name="Assistant",
    instructions="...",
    output_guardrails=[OutputGuardrail(guardrail_function=sensitive_data_check)],
)
```

## SIP 与电话通信

Python SDK 通过 [`OpenAIRealtimeSIPModel`][agents.realtime.openai_realtime.OpenAIRealtimeSIPModel] 提供一流的 SIP 附加流程。

当来电通过 Realtime Calls API 到达，且你希望将智能体会话附加到生成的 `call_id` 时使用它：

```python
from agents.realtime import RealtimeRunner
from agents.realtime.openai_realtime import OpenAIRealtimeSIPModel

runner = RealtimeRunner(starting_agent=agent, model=OpenAIRealtimeSIPModel())

async with await runner.run(
    model_config={
        "call_id": call_id_from_webhook,
    }
) as session:
    async for event in session:
        ...
```

如果你需要先接听电话，并希望接听载荷与智能体派生的会话配置一致，请使用 `OpenAIRealtimeSIPModel.build_initial_session_payload(...)`。完整流程见 [`examples/realtime/twilio_sip/server.py`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/twilio_sip/server.py)。

## 底层访问与自定义端点

你可以通过 `session.model` 访问底层传输对象。

在以下情况使用：

-   通过 `session.model.add_listener(...)` 添加自定义监听器
-   发送原始客户端事件，如 `response.create` 或 `session.update`
-   通过 `model_config` 处理自定义 `url`、`headers` 或 `api_key`
-   通过 `call_id` 附加到现有实时通话

`RealtimeModelConfig` 支持：

-   `api_key`
-   `url`
-   `headers`
-   `initial_model_settings`
-   `playback_tracker`
-   `call_id`

本仓库内置的 `call_id` 示例是 SIP。更广泛的 Realtime API 也会在某些服务端控制流程中使用 `call_id`，但这里未将其打包为 Python 示例。

连接到 Azure OpenAI 时，请传入 GA Realtime 端点 URL 和显式 headers。例如：

```python
session = await runner.run(
    model_config={
        "url": "wss://<your-resource>.openai.azure.com/openai/v1/realtime?model=<deployment-name>",
        "headers": {"api-key": "<your-azure-api-key>"},
    }
)
```

对于基于 token 的认证，请在 `headers` 中使用 bearer token：

```python
session = await runner.run(
    model_config={
        "url": "wss://<your-resource>.openai.azure.com/openai/v1/realtime?model=<deployment-name>",
        "headers": {"authorization": f"Bearer {token}"},
    }
)
```

如果你传入 `headers`，SDK 不会自动添加 `Authorization`。在 realtime 智能体中避免使用旧版 beta 路径（`/openai/realtime?api-version=...`）。

## 延伸阅读

-   [Realtime 传输](transport.md)
-   [快速开始](quickstart.md)
-   [OpenAI Realtime 对话](https://developers.openai.com/api/docs/guides/realtime-conversations/)
-   [OpenAI Realtime 服务端控制](https://developers.openai.com/api/docs/guides/realtime-server-controls/)
-   [`examples/realtime`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime)

================
File: docs/zh/realtime/quickstart.md
================
---
search:
  exclude: true
---
# 快速入门

Python SDK 中的实时智能体是服务端、低延迟的智能体，基于 OpenAI Realtime API 并通过 WebSocket 传输构建。

!!! warning "测试版功能"

    实时智能体目前处于测试版。随着我们改进实现，预计会有一些破坏性变更。

!!! note "Python SDK 边界"

    Python SDK **不**提供浏览器 WebRTC 传输。本页仅涵盖由 Python 管理的、基于服务端 WebSocket 的实时会话。可使用此 SDK 进行服务端编排、工具、审批和电话集成。另请参阅[实时传输](transport.md)。

## 前提条件

-   Python 3.10 或更高版本
-   OpenAI API key
-   对 OpenAI Agents SDK 的基本了解

## 安装

如果你还没有安装，请先安装 OpenAI Agents SDK：

```bash
pip install openai-agents
```

## 创建服务端实时会话

### 1. 导入实时组件

```python
import asyncio

from agents.realtime import RealtimeAgent, RealtimeRunner
```

### 2. 定义起始智能体

```python
agent = RealtimeAgent(
    name="Assistant",
    instructions="You are a helpful voice assistant. Keep responses short and conversational.",
)
```

### 3. 配置运行器

对于新代码，优先使用嵌套的 `audio.input` / `audio.output` 会话设置结构。

```python
runner = RealtimeRunner(
    starting_agent=agent,
    config={
        "model_settings": {
            "model_name": "gpt-realtime",
            "audio": {
                "input": {
                    "format": "pcm16",
                    "transcription": {"model": "gpt-4o-mini-transcribe"},
                    "turn_detection": {
                        "type": "semantic_vad",
                        "interrupt_response": True,
                    },
                },
                "output": {
                    "format": "pcm16",
                    "voice": "ash",
                },
            },
        }
    },
)
```

### 4. 启动会话并发送输入

`runner.run()` 返回一个 `RealtimeSession`。进入会话上下文时会打开连接。

```python
async def main() -> None:
    session = await runner.run()

    async with session:
        await session.send_message("Say hello in one short sentence.")

        async for event in session:
            if event.type == "audio":
                # Forward or play event.audio.data.
                pass
            elif event.type == "history_added":
                print(event.item)
            elif event.type == "agent_end":
                # One assistant turn finished.
                break
            elif event.type == "error":
                print(f"Error: {event.error}")


if __name__ == "__main__":
    asyncio.run(main())
```

`session.send_message()` 既可接受普通字符串，也可接受结构化实时消息。对于原始音频分片，请使用 [`session.send_audio()`][agents.realtime.session.RealtimeSession.send_audio]。

## 本快速入门未包含的内容

-   麦克风采集和扬声器播放代码。请参阅 [`examples/realtime`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime) 中的实时示例。
-   SIP / 电话附加流程。请参阅[实时传输](transport.md)和 [SIP 部分](guide.md#sip-and-telephony)。

## 关键设置

当基础会话可用后，大多数人下一步会用到的设置有：

-   `model_name`
-   `audio.input.format`, `audio.output.format`
-   `audio.input.transcription`
-   `audio.input.noise_reduction`
-   用于自动轮次检测的 `audio.input.turn_detection`
-   `audio.output.voice`
-   `tool_choice`, `prompt`, `tracing`
-   `async_tool_calls`, `guardrails_settings.debounce_text_length`, `tool_error_formatter`

较旧的扁平别名（例如 `input_audio_format`、`output_audio_format`、`input_audio_transcription` 和 `turn_detection`）仍可使用，但对于新代码更推荐使用嵌套的 `audio` 设置。

对于手动轮次控制，请使用原始的 `session.update` / `input_audio_buffer.commit` / `response.create` 流程，详见[实时智能体指南](guide.md#manual-response-control)。

完整 schema 请参阅 [`RealtimeRunConfig`][agents.realtime.config.RealtimeRunConfig] 和 [`RealtimeSessionModelSettings`][agents.realtime.config.RealtimeSessionModelSettings]。

## 连接选项

在环境中设置你的 API key：

```bash
export OPENAI_API_KEY="your-api-key-here"
```

或在启动会话时直接传入：

```python
session = await runner.run(model_config={"api_key": "your-api-key"})
```

`model_config` 还支持：

-   `url`：自定义 WebSocket 端点
-   `headers`：自定义请求头
-   `call_id`：附加到现有实时通话。在此仓库中，文档说明的附加流程是 SIP。
-   `playback_tracker`：报告用户实际已听到的音频量

如果你显式传入 `headers`，SDK 将**不会**为你注入 `Authorization` 请求头。

连接 Azure OpenAI 时，请在 `model_config["url"]` 中传入 GA Realtime 端点 URL，并显式传入请求头。对于实时智能体，避免使用旧版 beta 路径（`/openai/realtime?api-version=...`）。详情请参阅[实时智能体指南](guide.md#low-level-access-and-custom-endpoints)。

## 后续步骤

-   阅读[实时传输](transport.md)，在服务端 WebSocket 和 SIP 之间进行选择。
-   阅读[实时智能体指南](guide.md)，了解生命周期、结构化输入、审批、任务转移、安全防护措施和底层控制。
-   浏览 [`examples/realtime`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime) 中的示例。

================
File: docs/zh/realtime/transport.md
================
---
search:
  exclude: true
---
# Realtime 传输

使用本页面来判断 realtime 智能体如何适配你的 Python 应用。

!!! note "Python SDK 边界"

    Python SDK **不**包含浏览器 WebRTC 传输。本页面仅介绍 Python SDK 的传输选择：服务端 WebSockets 和 SIP 附加流程。浏览器 WebRTC 是独立的平台主题，文档见官方指南 [Realtime API with WebRTC](https://developers.openai.com/api/docs/guides/realtime-webrtc/)。

## 决策指南

| 目标 | 起步项 | 原因 |
| --- | --- | --- |
| 构建由服务端管理的 realtime 应用 | [Quickstart](quickstart.md) | 默认的 Python 路径是由 `RealtimeRunner` 管理的服务端 WebSocket 会话。 |
| 理解应选择哪种传输和部署形态 | 本页面 | 在你确定传输或部署形态之前先参考此页。 |
| 将智能体附加到电话或 SIP 通话 | [Realtime guide](guide.md) 和 [`examples/realtime/twilio_sip`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/twilio_sip) | 仓库提供了由 `call_id` 驱动的 SIP 附加流程。 |

## 服务端 WebSocket 是默认 Python 路径

除非你传入自定义 `RealtimeModel`，否则 `RealtimeRunner` 使用 `OpenAIRealtimeWebSocketModel`。

这意味着标准的 Python 拓扑如下：

1. 你的 Python 服务创建一个 `RealtimeRunner`。
2. `await runner.run()` 返回一个 `RealtimeSession`。
3. 进入该会话并发送文本、结构化消息或音频。
4. 消费 `RealtimeSessionEvent` 项，并将音频或转录转发到你的应用。

这是核心演示应用、CLI 示例和 Twilio Media Streams 示例使用的拓扑：

-   [`examples/realtime/app`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/app)
-   [`examples/realtime/cli`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/cli)
-   [`examples/realtime/twilio`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/twilio)

当你的服务负责音频管线、工具执行、审批流程和历史记录处理时，请使用此路径。

## SIP 附加是电话路径

对于本仓库中记录的电话流程，Python SDK 通过 `call_id` 附加到现有 realtime 通话。

该拓扑如下：

1. OpenAI 向你的服务发送 webhook，例如 `realtime.call.incoming`。
2. 你的服务通过 Realtime Calls API 接受通话。
3. 你的 Python 服务启动 `RealtimeRunner(..., model=OpenAIRealtimeSIPModel())`。
4. 会话使用 `model_config={"call_id": ...}` 建立连接，然后像其他 realtime 会话一样处理事件。

这是 [`examples/realtime/twilio_sip`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/twilio_sip) 中展示的拓扑。

更广义的 Realtime API 也会在某些服务端控制模式中使用 `call_id`，但本仓库提供的附加示例是 SIP。

## 浏览器 WebRTC 不属于此 SDK 范围

如果你应用的主要客户端是使用 Realtime WebRTC 的浏览器：

-   将其视为超出本仓库 Python SDK 文档范围。
-   使用官方文档 [Realtime API with WebRTC](https://developers.openai.com/api/docs/guides/realtime-webrtc/) 和 [Realtime conversations](https://developers.openai.com/api/docs/guides/realtime-conversations/) 来了解客户端流程和事件模型。
-   如果你需要在浏览器 WebRTC 客户端之上使用 sideband 服务端连接，请使用官方指南 [Realtime server-side controls](https://developers.openai.com/api/docs/guides/realtime-server-controls/)。
-   不要期待本仓库提供浏览器侧 `RTCPeerConnection` 抽象或现成的浏览器 WebRTC 示例。

本仓库目前也未提供浏览器 WebRTC 加 Python sideband 的示例。

## 自定义端点和附加点

[`RealtimeModelConfig`][agents.realtime.model.RealtimeModelConfig] 中的传输配置接口让你可以调整默认路径：

-   `url`: 覆盖 WebSocket 端点
-   `headers`: 提供显式请求头，例如 Azure 认证请求头
-   `api_key`: 直接传递 API key 或通过回调传递
-   `call_id`: 附加到现有 realtime 通话。在本仓库中，文档化示例是 SIP。
-   `playback_tracker`: 上报实际播放进度以处理中断

选定拓扑后，详细的生命周期和能力接口请参见 [Realtime agents guide](guide.md)。

================
File: docs/zh/sessions/advanced_sqlite_session.md
================
---
search:
  exclude: true
---
# 高级 SQLite 会话

`AdvancedSQLiteSession` 是基础 `SQLiteSession` 的增强版本，提供高级对话管理能力，包括对话分支、详细用量分析和结构化对话查询。

## 功能

- **对话分支**：可从任意用户消息创建替代对话路径
- **用量追踪**：按轮次提供详细的 token 用量分析，并包含完整 JSON 明细
- **结构化查询**：可按轮次获取对话、工具使用统计等信息
- **分支管理**：独立的分支切换与管理
- **消息结构元数据**：追踪消息类型、工具使用情况和对话流

## 快速开始

```python
from agents import Agent, Runner
from agents.extensions.memory import AdvancedSQLiteSession

# Create agent
agent = Agent(
    name="Assistant",
    instructions="Reply very concisely.",
)

# Create an advanced session
session = AdvancedSQLiteSession(
    session_id="conversation_123",
    db_path="conversations.db",
    create_tables=True
)

# First conversation turn
result = await Runner.run(
    agent,
    "What city is the Golden Gate Bridge in?",
    session=session
)
print(result.final_output)  # "San Francisco"

# IMPORTANT: Store usage data
await session.store_run_usage(result)

# Continue conversation
result = await Runner.run(
    agent,
    "What state is it in?",
    session=session
)
print(result.final_output)  # "California"
await session.store_run_usage(result)
```

## 初始化

```python
from agents.extensions.memory import AdvancedSQLiteSession

# Basic initialization
session = AdvancedSQLiteSession(
    session_id="my_conversation",
    create_tables=True  # Auto-create advanced tables
)

# With persistent storage
session = AdvancedSQLiteSession(
    session_id="user_123",
    db_path="path/to/conversations.db",
    create_tables=True
)

# With custom logger
import logging
logger = logging.getLogger("my_app")
session = AdvancedSQLiteSession(
    session_id="session_456",
    create_tables=True,
    logger=logger
)
```

### 参数

- `session_id` (str)：会话的唯一标识符
- `db_path` (str | Path)：SQLite 数据库文件路径。默认为 `:memory:`（内存存储）
- `create_tables` (bool)：是否自动创建高级表。默认为 `False`
- `logger` (logging.Logger | None)：会话的自定义日志记录器。默认为模块日志记录器

## 用量追踪

AdvancedSQLiteSession 通过按对话轮次存储 token 用量数据来提供详细的用量分析。**这完全依赖于在每次智能体运行后调用 `store_run_usage` 方法。**

### 存储用量数据

```python
# After each agent run, store the usage data
result = await Runner.run(agent, "Hello", session=session)
await session.store_run_usage(result)

# This stores:
# - Total tokens used
# - Input/output token breakdown
# - Request count
# - Detailed JSON token information (if available)
```

### 获取用量统计

```python
# Get session-level usage (all branches)
session_usage = await session.get_session_usage()
if session_usage:
    print(f"Total requests: {session_usage['requests']}")
    print(f"Total tokens: {session_usage['total_tokens']}")
    print(f"Input tokens: {session_usage['input_tokens']}")
    print(f"Output tokens: {session_usage['output_tokens']}")
    print(f"Total turns: {session_usage['total_turns']}")

# Get usage for specific branch
branch_usage = await session.get_session_usage(branch_id="main")

# Get usage by turn
turn_usage = await session.get_turn_usage()
for turn_data in turn_usage:
    print(f"Turn {turn_data['user_turn_number']}: {turn_data['total_tokens']} tokens")
    if turn_data['input_tokens_details']:
        print(f"  Input details: {turn_data['input_tokens_details']}")
    if turn_data['output_tokens_details']:
        print(f"  Output details: {turn_data['output_tokens_details']}")

# Get usage for specific turn
turn_2_usage = await session.get_turn_usage(user_turn_number=2)
```

## 对话分支

AdvancedSQLiteSession 的核心功能之一是能够从任意用户消息创建对话分支，让你可以探索替代性的对话路径。

### 创建分支

```python
# Get available turns for branching
turns = await session.get_conversation_turns()
for turn in turns:
    print(f"Turn {turn['turn']}: {turn['content']}")
    print(f"Can branch: {turn['can_branch']}")

# Create a branch from turn 2
branch_id = await session.create_branch_from_turn(2)
print(f"Created branch: {branch_id}")

# Create a branch with custom name
branch_id = await session.create_branch_from_turn(
    2, 
    branch_name="alternative_path"
)

# Create branch by searching for content
branch_id = await session.create_branch_from_content(
    "weather", 
    branch_name="weather_focus"
)
```

### 分支管理

```python
# List all branches
branches = await session.list_branches()
for branch in branches:
    current = " (current)" if branch["is_current"] else ""
    print(f"{branch['branch_id']}: {branch['user_turns']} turns, {branch['message_count']} messages{current}")

# Switch between branches
await session.switch_to_branch("main")
await session.switch_to_branch(branch_id)

# Delete a branch
await session.delete_branch(branch_id, force=True)  # force=True allows deleting current branch
```

### 分支工作流示例

```python
# Original conversation
result = await Runner.run(agent, "What's the capital of France?", session=session)
await session.store_run_usage(result)

result = await Runner.run(agent, "What's the weather like there?", session=session)
await session.store_run_usage(result)

# Create branch from turn 2 (weather question)
branch_id = await session.create_branch_from_turn(2, "weather_focus")

# Continue in new branch with different question
result = await Runner.run(
    agent, 
    "What are the main tourist attractions in Paris?", 
    session=session
)
await session.store_run_usage(result)

# Switch back to main branch
await session.switch_to_branch("main")

# Continue original conversation
result = await Runner.run(
    agent, 
    "How expensive is it to visit?", 
    session=session
)
await session.store_run_usage(result)
```

## 结构化查询

AdvancedSQLiteSession 提供了多种方法来分析对话结构和内容。

### 对话分析

```python
# Get conversation organized by turns
conversation_by_turns = await session.get_conversation_by_turns()
for turn_num, items in conversation_by_turns.items():
    print(f"Turn {turn_num}: {len(items)} items")
    for item in items:
        if item["tool_name"]:
            print(f"  - {item['type']} (tool: {item['tool_name']})")
        else:
            print(f"  - {item['type']}")

# Get tool usage statistics
tool_usage = await session.get_tool_usage()
for tool_name, count, turn in tool_usage:
    print(f"{tool_name}: used {count} times in turn {turn}")

# Find turns by content
matching_turns = await session.find_turns_by_content("weather")
for turn in matching_turns:
    print(f"Turn {turn['turn']}: {turn['content']}")
```

### 消息结构

会话会自动追踪消息结构，包括：

- 消息类型（user、assistant、tool_call 等）
- 工具调用的工具名称
- 轮次编号与序列编号
- 分支关联
- 时间戳

## 数据库架构

AdvancedSQLiteSession 在基础 SQLite 架构上扩展了两个附加表：

### message_structure 表

```sql
CREATE TABLE message_structure (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    message_id INTEGER NOT NULL,
    branch_id TEXT NOT NULL DEFAULT 'main',
    message_type TEXT NOT NULL,
    sequence_number INTEGER NOT NULL,
    user_turn_number INTEGER,
    branch_turn_number INTEGER,
    tool_name TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES agent_sessions(session_id) ON DELETE CASCADE,
    FOREIGN KEY (message_id) REFERENCES agent_messages(id) ON DELETE CASCADE
);
```

### turn_usage 表

```sql
CREATE TABLE turn_usage (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    branch_id TEXT NOT NULL DEFAULT 'main',
    user_turn_number INTEGER NOT NULL,
    requests INTEGER DEFAULT 0,
    input_tokens INTEGER DEFAULT 0,
    output_tokens INTEGER DEFAULT 0,
    total_tokens INTEGER DEFAULT 0,
    input_tokens_details JSON,
    output_tokens_details JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES agent_sessions(session_id) ON DELETE CASCADE,
    UNIQUE(session_id, branch_id, user_turn_number)
);
```

## 完整示例

查看[完整示例](https://github.com/openai/openai-agents-python/tree/main/examples/memory/advanced_sqlite_session_example.py)，了解所有功能的完整演示。


## API 参考

- [`AdvancedSQLiteSession`][agents.extensions.memory.advanced_sqlite_session.AdvancedSQLiteSession] - 主类
- [`Session`][agents.memory.session.Session] - 基础会话协议

================
File: docs/zh/sessions/encrypted_session.md
================
---
search:
  exclude: true
---
# 加密会话

`EncryptedSession`为任意会话实现提供透明加密，通过自动过期旧条目来保护对话数据。

## 功能特性

- **透明加密**：使用 Fernet 加密包装任意会话
- **每会话密钥**：使用 HKDF 密钥派生为每个会话生成唯一加密密钥
- **自动过期**：当 TTL 到期时，旧条目会被静默跳过
- **即插即用替换**：可与任何现有会话实现配合使用

## 安装

加密会话需要 `encrypt` 扩展：

```bash
pip install openai-agents[encrypt]
```

## 快速开始

```python
import asyncio
from agents import Agent, Runner
from agents.extensions.memory import EncryptedSession, SQLAlchemySession

async def main():
    agent = Agent("Assistant")
    
    # Create underlying session
    underlying_session = SQLAlchemySession.from_url(
        "user-123",
        url="sqlite+aiosqlite:///:memory:",
        create_tables=True
    )
    
    # Wrap with encryption
    session = EncryptedSession(
        session_id="user-123",
        underlying_session=underlying_session,
        encryption_key="your-secret-key-here",
        ttl=600  # 10 minutes
    )
    
    result = await Runner.run(agent, "Hello", session=session)
    print(result.final_output)

if __name__ == "__main__":
    asyncio.run(main())
```

## 配置

### 加密密钥

加密密钥可以是 Fernet 密钥，也可以是任意字符串：

```python
from agents.extensions.memory import EncryptedSession

# Using a Fernet key (base64-encoded)
session = EncryptedSession(
    session_id="user-123",
    underlying_session=underlying_session,
    encryption_key="your-fernet-key-here",
    ttl=600
)

# Using a raw string (will be derived to a key)
session = EncryptedSession(
    session_id="user-123", 
    underlying_session=underlying_session,
    encryption_key="my-secret-password",
    ttl=600
)
```

### TTL（生存时间）

设置加密条目保持有效的时长：

```python
# Items expire after 1 hour
session = EncryptedSession(
    session_id="user-123",
    underlying_session=underlying_session,
    encryption_key="secret",
    ttl=3600  # 1 hour in seconds
)

# Items expire after 1 day
session = EncryptedSession(
    session_id="user-123",
    underlying_session=underlying_session,
    encryption_key="secret", 
    ttl=86400  # 24 hours in seconds
)
```

## 与不同会话类型配合使用

### 与 SQLite 会话配合使用

```python
from agents import SQLiteSession
from agents.extensions.memory import EncryptedSession

# Create encrypted SQLite session
underlying = SQLiteSession("user-123", "conversations.db")

session = EncryptedSession(
    session_id="user-123",
    underlying_session=underlying,
    encryption_key="secret-key"
)
```

### 与 SQLAlchemy 会话配合使用

```python
from agents.extensions.memory import EncryptedSession, SQLAlchemySession

# Create encrypted SQLAlchemy session
underlying = SQLAlchemySession.from_url(
    "user-123",
    url="postgresql+asyncpg://user:pass@localhost/db",
    create_tables=True
)

session = EncryptedSession(
    session_id="user-123",
    underlying_session=underlying,
    encryption_key="secret-key"
)
```

!!! warning "高级会话功能"

    使用 `EncryptedSession` 与 `AdvancedSQLiteSession` 等高级会话实现时，请注意：

    - 由于消息内容已加密，`find_turns_by_content()` 等方法将无法有效工作
    - 基于内容的搜索会在加密数据上执行，因此效果受限



## 密钥派生

EncryptedSession 使用 HKDF（基于 HMAC 的密钥派生函数）为每个会话派生唯一加密密钥：

- **主密钥**：你提供的加密密钥
- **会话盐值**：会话 ID
- **信息字符串**：`"agents.session-store.hkdf.v1"`
- **输出**：32 字节 Fernet 密钥

这可确保：
- 每个会话都有唯一的加密密钥
- 没有主密钥就无法派生密钥
- 不同会话之间的数据无法相互解密

## 自动过期

当条目超过 TTL 时，在检索期间会被自动跳过：

```python
# Items older than TTL are silently ignored
items = await session.get_items()  # Only returns non-expired items

# Expired items don't affect session behavior
result = await Runner.run(agent, "Continue conversation", session=session)
```

## API 参考

- [`EncryptedSession`][agents.extensions.memory.encrypt_session.EncryptedSession] - 主类
- [`Session`][agents.memory.session.Session] - 基础会话协议

================
File: docs/zh/sessions/index.md
================
---
search:
  exclude: true
---
# 会话

Agents SDK 提供内置的会话内存，可在多次智能体运行间自动维护对话历史，无需在每轮之间手动处理 `.to_input_list()`。

会话会为特定会话存储对话历史，使智能体无需显式手动管理内存即可保持上下文。这对于构建聊天应用或多轮对话特别有用，因为你希望智能体记住之前的交互。

当你希望 SDK 为你管理客户端内存时，请使用会话。会话不能与 `conversation_id`、`previous_response_id` 或 `auto_previous_response_id` 在同一次运行中组合使用。如果你想改用 OpenAI 服务端管理的续接方式，请选择其中一种机制，而不是在其之上叠加会话。

## 快速开始

```python
from agents import Agent, Runner, SQLiteSession

# Create agent
agent = Agent(
    name="Assistant",
    instructions="Reply very concisely.",
)

# Create a session instance with a session ID
session = SQLiteSession("conversation_123")

# First turn
result = await Runner.run(
    agent,
    "What city is the Golden Gate Bridge in?",
    session=session
)
print(result.final_output)  # "San Francisco"

# Second turn - agent automatically remembers previous context
result = await Runner.run(
    agent,
    "What state is it in?",
    session=session
)
print(result.final_output)  # "California"

# Also works with synchronous runner
result = Runner.run_sync(
    agent,
    "What's the population?",
    session=session
)
print(result.final_output)  # "Approximately 39 million"
```

## 使用同一会话恢复中断运行

如果某次运行因审批而暂停，请使用同一个会话实例（或另一个指向同一后端存储的会话实例）进行恢复，这样恢复后的轮次会延续相同的已存储对话历史。

```python
result = await Runner.run(agent, "Delete temporary files that are no longer needed.", session=session)

if result.interruptions:
    state = result.to_state()
    for interruption in result.interruptions:
        state.approve(interruption)
    result = await Runner.run(agent, state, session=session)
```

## 会话核心行为

启用会话内存后：

1. **每次运行前**：运行器会自动检索该会话的对话历史，并将其前置到输入项中。
2. **每次运行后**：运行期间产生的所有新项（用户输入、助手回复、工具调用等）都会自动存入会话。
3. **上下文保持**：后续每次使用同一会话的运行都会包含完整对话历史，使智能体能够保持上下文。

这消除了在多次运行之间手动调用 `.to_input_list()` 并管理对话状态的需要。

## 控制历史与新输入的合并方式

当你传入会话时，运行器通常会按以下方式准备模型输入：

1. 会话历史（从 `session.get_items(...)` 检索）
2. 新一轮输入

使用 [`RunConfig.session_input_callback`][agents.run.RunConfig.session_input_callback] 可在模型调用前自定义该合并步骤。该回调接收两个列表：

-   `history`：检索到的会话历史（已规范化为输入项格式）
-   `new_input`：当前轮次的新输入项

返回应发送给模型的最终输入项列表。

该回调接收的是两个列表的副本，因此你可以安全地修改它们。返回的列表会控制该轮次的模型输入，但 SDK 仍只持久化属于新轮次的项。因此，对旧历史重新排序或过滤不会导致旧会话项被再次作为新输入保存。

```python
from agents import Agent, RunConfig, Runner, SQLiteSession


def keep_recent_history(history, new_input):
    # Keep only the last 10 history items, then append the new turn.
    return history[-10:] + new_input


agent = Agent(name="Assistant")
session = SQLiteSession("conversation_123")

result = await Runner.run(
    agent,
    "Continue from the latest updates only.",
    session=session,
    run_config=RunConfig(session_input_callback=keep_recent_history),
)
```

当你需要自定义裁剪、重排或选择性包含历史，同时又不改变会话存储项的方式时，请使用此功能。如果你需要在模型调用前的更晚阶段再做一次最终处理，请使用[运行智能体指南](../running_agents.md)中的 [`call_model_input_filter`][agents.run.RunConfig.call_model_input_filter]。

## 限制检索历史

使用 [`SessionSettings`][agents.memory.SessionSettings] 控制每次运行前拉取多少历史。

-   `SessionSettings(limit=None)`（默认）：检索所有可用会话项
-   `SessionSettings(limit=N)`：仅检索最近的 `N` 个项

你可以通过 [`RunConfig.session_settings`][agents.run.RunConfig.session_settings] 在每次运行中应用此设置：

```python
from agents import Agent, RunConfig, Runner, SessionSettings, SQLiteSession

agent = Agent(name="Assistant")
session = SQLiteSession("conversation_123")

result = await Runner.run(
    agent,
    "Summarize our recent discussion.",
    session=session,
    run_config=RunConfig(session_settings=SessionSettings(limit=50)),
)
```

如果你的会话实现暴露了默认会话设置，`RunConfig.session_settings` 会在该次运行中覆盖所有非 `None` 的值。这对于长对话很有用：你可以限制检索大小，而无需改变会话默认行为。

## 内存操作

### 基础操作

会话支持多种管理对话历史的操作：

```python
from agents import SQLiteSession

session = SQLiteSession("user_123", "conversations.db")

# Get all items in a session
items = await session.get_items()

# Add new items to a session
new_items = [
    {"role": "user", "content": "Hello"},
    {"role": "assistant", "content": "Hi there!"}
]
await session.add_items(new_items)

# Remove and return the most recent item
last_item = await session.pop_item()
print(last_item)  # {"role": "assistant", "content": "Hi there!"}

# Clear all items from a session
await session.clear_session()
```

### 使用 pop_item 进行修正

当你想撤销或修改对话中的最后一项时，`pop_item` 方法特别有用：

```python
from agents import Agent, Runner, SQLiteSession

agent = Agent(name="Assistant")
session = SQLiteSession("correction_example")

# Initial conversation
result = await Runner.run(
    agent,
    "What's 2 + 2?",
    session=session
)
print(f"Agent: {result.final_output}")

# User wants to correct their question
assistant_item = await session.pop_item()  # Remove agent's response
user_item = await session.pop_item()  # Remove user's question

# Ask a corrected question
result = await Runner.run(
    agent,
    "What's 2 + 3?",
    session=session
)
print(f"Agent: {result.final_output}")
```

## 内置会话实现

SDK 为不同用例提供了多种会话实现：

### 选择内置会话实现

在阅读下面详细示例前，可先用此表选择起点。

| 会话类型 | 最适合 | 说明 |
| --- | --- | --- |
| `SQLiteSession` | 本地开发和简单应用 | 内置、轻量、基于文件或内存 |
| `AsyncSQLiteSession` | 使用 `aiosqlite` 的异步 SQLite | 扩展后端，支持异步驱动 |
| `RedisSession` | 跨 worker/服务共享内存 | 适合低延迟分布式部署 |
| `SQLAlchemySession` | 使用现有数据库的生产应用 | 适用于 SQLAlchemy 支持的数据库 |
| `DaprSession` | 使用 Dapr sidecar 的云原生部署 | 支持多种状态存储及 TTL、一致性控制 |
| `OpenAIConversationsSession` | OpenAI 中的服务端托管存储 | 基于 OpenAI Conversations API 的历史 |
| `OpenAIResponsesCompactionSession` | 需要自动压缩的长对话 | 对另一个会话后端的包装器 |
| `AdvancedSQLiteSession` | SQLite + 分支/分析 | 功能更重；见专门页面 |
| `EncryptedSession` | 在另一个会话之上提供加密 + TTL | 包装器；先选择底层后端 |

部分实现有包含更多细节的专门页面；其链接已在各小节内给出。

### OpenAI Conversations API 会话

通过 `OpenAIConversationsSession` 使用 [OpenAI 的 Conversations API](https://platform.openai.com/docs/api-reference/conversations)。

```python
from agents import Agent, Runner, OpenAIConversationsSession

# Create agent
agent = Agent(
    name="Assistant",
    instructions="Reply very concisely.",
)

# Create a new conversation
session = OpenAIConversationsSession()

# Optionally resume a previous conversation by passing a conversation ID
# session = OpenAIConversationsSession(conversation_id="conv_123")

# Start conversation
result = await Runner.run(
    agent,
    "What city is the Golden Gate Bridge in?",
    session=session
)
print(result.final_output)  # "San Francisco"

# Continue the conversation
result = await Runner.run(
    agent,
    "What state is it in?",
    session=session
)
print(result.final_output)  # "California"
```

### OpenAI Responses 压缩会话

使用 `OpenAIResponsesCompactionSession` 通过 Responses API（`responses.compact`）压缩已存储的对话历史。它包装一个底层会话，并可基于 `should_trigger_compaction` 在每轮后自动压缩。不要用它包装 `OpenAIConversationsSession`；这两种功能以不同方式管理历史。

#### 典型用法（自动压缩）

```python
from agents import Agent, Runner, SQLiteSession
from agents.memory import OpenAIResponsesCompactionSession

underlying = SQLiteSession("conversation_123")
session = OpenAIResponsesCompactionSession(
    session_id="conversation_123",
    underlying_session=underlying,
)

agent = Agent(name="Assistant")
result = await Runner.run(agent, "Hello", session=session)
print(result.final_output)
```

默认情况下，一旦达到候选阈值，就会在每轮后执行压缩。

当你已使用 Responses API 的 response ID 串联轮次时，`compaction_mode="previous_response_id"` 效果最佳。`compaction_mode="input"` 则会改为从当前会话项重建压缩请求，这在响应链不可用或你希望以会话内容为事实来源时很有用。默认 `"auto"` 会选择当前可用的最安全选项。

#### 自动压缩可能阻塞流式传输

压缩会清空并重写会话历史，因此 SDK 会等待压缩完成后才认为运行结束。在流式模式下，这意味着如果压缩负载较重，`run.stream_events()` 可能在最后一个输出 token 后仍保持打开数秒。

如果你需要低延迟流式传输或快速轮次切换，请禁用自动压缩，并在轮次之间（或空闲时间）自行调用 `run_compaction()`。你可以根据自己的标准决定何时强制压缩。

```python
from agents import Agent, Runner, SQLiteSession
from agents.memory import OpenAIResponsesCompactionSession

underlying = SQLiteSession("conversation_123")
session = OpenAIResponsesCompactionSession(
    session_id="conversation_123",
    underlying_session=underlying,
    # Disable triggering the auto compaction
    should_trigger_compaction=lambda _: False,
)

agent = Agent(name="Assistant")
result = await Runner.run(agent, "Hello", session=session)

# Decide when to compact (e.g., on idle, every N turns, or size thresholds).
await session.run_compaction({"force": True})
```

### SQLite 会话

默认的轻量级 SQLite 会话实现：

```python
from agents import SQLiteSession

# In-memory database (lost when process ends)
session = SQLiteSession("user_123")

# Persistent file-based database
session = SQLiteSession("user_123", "conversations.db")

# Use the session
result = await Runner.run(
    agent,
    "Hello",
    session=session
)
```

### 异步 SQLite 会话

当你需要由 `aiosqlite` 支持持久化的 SQLite 时，请使用 `AsyncSQLiteSession`。

```bash
pip install aiosqlite
```

```python
from agents import Agent, Runner
from agents.extensions.memory import AsyncSQLiteSession

agent = Agent(name="Assistant")
session = AsyncSQLiteSession("user_123", db_path="conversations.db")
result = await Runner.run(agent, "Hello", session=session)
```

### Redis 会话

使用 `RedisSession` 在多个 worker 或服务之间共享会话内存。

```bash
pip install openai-agents[redis]
```

```python
from agents import Agent, Runner
from agents.extensions.memory import RedisSession

agent = Agent(name="Assistant")
session = RedisSession.from_url(
    "user_123",
    url="redis://localhost:6379/0",
)
result = await Runner.run(agent, "Hello", session=session)
```

### SQLAlchemy 会话

基于任意 SQLAlchemy 支持数据库的生产级会话：

```python
from agents.extensions.memory import SQLAlchemySession

# Using database URL
session = SQLAlchemySession.from_url(
    "user_123",
    url="postgresql+asyncpg://user:pass@localhost/db",
    create_tables=True
)

# Using existing engine
from sqlalchemy.ext.asyncio import create_async_engine
engine = create_async_engine("postgresql+asyncpg://user:pass@localhost/db")
session = SQLAlchemySession("user_123", engine=engine, create_tables=True)
```

详见 [SQLAlchemy Sessions](sqlalchemy_session.md) 文档。

### Dapr 会话

当你已在运行 Dapr sidecar，或希望在不修改智能体代码的情况下跨不同状态存储后端迁移会话存储时，请使用 `DaprSession`。

```bash
pip install openai-agents[dapr]
```

```python
from agents import Agent, Runner
from agents.extensions.memory import DaprSession

agent = Agent(name="Assistant")

async with DaprSession.from_address(
    "user_123",
    state_store_name="statestore",
    dapr_address="localhost:50001",
) as session:
    result = await Runner.run(agent, "Hello", session=session)
    print(result.final_output)
```

说明：

-   `from_address(...)` 会为你创建并持有 Dapr 客户端。如果你的应用已自行管理客户端，请直接使用 `DaprSession(...)` 并传入 `dapr_client=...`。
-   传入 `ttl=...` 可在底层状态存储支持 TTL 时，让旧会话数据自动过期。
-   当你需要更强的写后读保障时，传入 `consistency=DAPR_CONSISTENCY_STRONG`。
-   Dapr Python SDK 还会检查 HTTP sidecar 端点。在本地开发中，除 `dapr_address` 使用的 gRPC 端口外，还需使用 `--dapr-http-port 3500` 启动 Dapr。
-   参见 [`examples/memory/dapr_session_example.py`](https://github.com/openai/openai-agents-python/tree/main/examples/memory/dapr_session_example.py) 获取完整配置流程，包括本地组件与故障排查。


### 高级 SQLite 会话

带有对话分支、用量分析和结构化查询的增强 SQLite 会话：

```python
from agents.extensions.memory import AdvancedSQLiteSession

# Create with advanced features
session = AdvancedSQLiteSession(
    session_id="user_123",
    db_path="conversations.db",
    create_tables=True
)

# Automatic usage tracking
result = await Runner.run(agent, "Hello", session=session)
await session.store_run_usage(result)  # Track token usage

# Conversation branching
await session.create_branch_from_turn(2)  # Branch from turn 2
```

详见 [Advanced SQLite Sessions](advanced_sqlite_session.md) 文档。

### 加密会话

适用于任意会话实现的透明加密包装器：

```python
from agents.extensions.memory import EncryptedSession, SQLAlchemySession

# Create underlying session
underlying_session = SQLAlchemySession.from_url(
    "user_123",
    url="sqlite+aiosqlite:///conversations.db",
    create_tables=True
)

# Wrap with encryption and TTL
session = EncryptedSession(
    session_id="user_123",
    underlying_session=underlying_session,
    encryption_key="your-secret-key",
    ttl=600  # 10 minutes
)

result = await Runner.run(agent, "Hello", session=session)
```

详见 [Encrypted Sessions](encrypted_session.md) 文档。

### 其他会话类型

还有一些额外的内置选项。请参阅 `examples/memory/` 和 `extensions/memory/` 下的源码。

## 运行模式

### 会话 ID 命名

使用有意义的会话 ID 以帮助组织对话：

-   基于用户：`"user_12345"`
-   基于线程：`"thread_abc123"`
-   基于上下文：`"support_ticket_456"`

### 内存持久化

-   临时对话使用内存 SQLite（`SQLiteSession("session_id")`）
-   持久对话使用文件 SQLite（`SQLiteSession("session_id", "path/to/db.sqlite")`）
-   需要基于 `aiosqlite` 的实现时，使用异步 SQLite（`AsyncSQLiteSession("session_id", db_path="...")`）
-   共享、低延迟会话内存使用 Redis 支撑的会话（`RedisSession.from_url("session_id", url="redis://...")`）
-   对于使用 SQLAlchemy 支持的现有数据库的生产系统，使用 SQLAlchemy 驱动的会话（`SQLAlchemySession("session_id", engine=engine, create_tables=True)`）
-   对于生产级云原生部署，使用 Dapr 状态存储会话（`DaprSession.from_address("session_id", state_store_name="statestore", dapr_address="localhost:50001")`），支持 30+ 数据库后端，并内置遥测、追踪和数据隔离
-   当你希望将历史存储在 OpenAI Conversations API 中时，使用 OpenAI 托管存储（`OpenAIConversationsSession()`）
-   使用加密会话（`EncryptedSession(session_id, underlying_session, encryption_key)`）为任意会话添加透明加密和基于 TTL 的过期能力
-   对于更高级场景，可考虑为其他生产系统（例如 Django）实现自定义会话后端

### 多会话

```python
from agents import Agent, Runner, SQLiteSession

agent = Agent(name="Assistant")

# Different sessions maintain separate conversation histories
session_1 = SQLiteSession("user_123", "conversations.db")
session_2 = SQLiteSession("user_456", "conversations.db")

result1 = await Runner.run(
    agent,
    "Help me with my account",
    session=session_1
)
result2 = await Runner.run(
    agent,
    "What are my charges?",
    session=session_2
)
```

### 会话共享

```python
# Different agents can share the same session
support_agent = Agent(name="Support")
billing_agent = Agent(name="Billing")
session = SQLiteSession("user_123")

# Both agents will see the same conversation history
result1 = await Runner.run(
    support_agent,
    "Help me with my account",
    session=session
)
result2 = await Runner.run(
    billing_agent,
    "What are my charges?",
    session=session
)
```

## 完整示例

下面是一个展示会话内存实际效果的完整示例：

```python
import asyncio
from agents import Agent, Runner, SQLiteSession


async def main():
    # Create an agent
    agent = Agent(
        name="Assistant",
        instructions="Reply very concisely.",
    )

    # Create a session instance that will persist across runs
    session = SQLiteSession("conversation_123", "conversation_history.db")

    print("=== Sessions Example ===")
    print("The agent will remember previous messages automatically.\n")

    # First turn
    print("First turn:")
    print("User: What city is the Golden Gate Bridge in?")
    result = await Runner.run(
        agent,
        "What city is the Golden Gate Bridge in?",
        session=session
    )
    print(f"Assistant: {result.final_output}")
    print()

    # Second turn - the agent will remember the previous conversation
    print("Second turn:")
    print("User: What state is it in?")
    result = await Runner.run(
        agent,
        "What state is it in?",
        session=session
    )
    print(f"Assistant: {result.final_output}")
    print()

    # Third turn - continuing the conversation
    print("Third turn:")
    print("User: What's the population of that state?")
    result = await Runner.run(
        agent,
        "What's the population of that state?",
        session=session
    )
    print(f"Assistant: {result.final_output}")
    print()

    print("=== Conversation Complete ===")
    print("Notice how the agent remembered the context from previous turns!")
    print("Sessions automatically handles conversation history.")


if __name__ == "__main__":
    asyncio.run(main())
```

## 自定义会话实现

你可以创建遵循 [`Session`][agents.memory.session.Session] 协议的类来实现自己的会话内存：

```python
from agents.memory.session import SessionABC
from agents.items import TResponseInputItem
from typing import List

class MyCustomSession(SessionABC):
    """Custom session implementation following the Session protocol."""

    def __init__(self, session_id: str):
        self.session_id = session_id
        # Your initialization here

    async def get_items(self, limit: int | None = None) -> List[TResponseInputItem]:
        """Retrieve conversation history for this session."""
        # Your implementation here
        pass

    async def add_items(self, items: List[TResponseInputItem]) -> None:
        """Store new items for this session."""
        # Your implementation here
        pass

    async def pop_item(self) -> TResponseInputItem | None:
        """Remove and return the most recent item from this session."""
        # Your implementation here
        pass

    async def clear_session(self) -> None:
        """Clear all items for this session."""
        # Your implementation here
        pass

# Use your custom session
agent = Agent(name="Assistant")
result = await Runner.run(
    agent,
    "Hello",
    session=MyCustomSession("my_session")
)
```

## 社区会话实现

社区已开发了额外的会话实现：

| Package | Description |
|---------|-------------|
| [openai-django-sessions](https://pypi.org/project/openai-django-sessions/) | 基于 Django ORM 的会话，适用于任何 Django 支持的数据库（PostgreSQL、MySQL、SQLite 等） |

如果你构建了会话实现，欢迎提交文档 PR，将其添加到这里！

## API 参考

详细 API 文档见：

-   [`Session`][agents.memory.session.Session] - 协议接口
-   [`OpenAIConversationsSession`][agents.memory.OpenAIConversationsSession] - OpenAI Conversations API 实现
-   [`OpenAIResponsesCompactionSession`][agents.memory.openai_responses_compaction_session.OpenAIResponsesCompactionSession] - Responses API 压缩包装器
-   [`SQLiteSession`][agents.memory.sqlite_session.SQLiteSession] - 基础 SQLite 实现
-   [`AsyncSQLiteSession`][agents.extensions.memory.async_sqlite_session.AsyncSQLiteSession] - 基于 `aiosqlite` 的异步 SQLite 实现
-   [`RedisSession`][agents.extensions.memory.redis_session.RedisSession] - Redis 支撑的会话实现
-   [`SQLAlchemySession`][agents.extensions.memory.sqlalchemy_session.SQLAlchemySession] - SQLAlchemy 驱动实现
-   [`DaprSession`][agents.extensions.memory.dapr_session.DaprSession] - Dapr 状态存储实现
-   [`AdvancedSQLiteSession`][agents.extensions.memory.advanced_sqlite_session.AdvancedSQLiteSession] - 带分支和分析能力的增强 SQLite
-   [`EncryptedSession`][agents.extensions.memory.encrypt_session.EncryptedSession] - 适用于任意会话的加密包装器

================
File: docs/zh/sessions/sqlalchemy_session.md
================
---
search:
  exclude: true
---
# SQLAlchemy 会话

`SQLAlchemySession` 使用 SQLAlchemy 提供可用于生产环境的会话实现，使你能够使用 SQLAlchemy 支持的任意数据库（PostgreSQL、MySQL、SQLite 等）进行会话存储。

## 安装

SQLAlchemy 会话需要 `sqlalchemy` 扩展：

```bash
pip install openai-agents[sqlalchemy]
```

## 快速开始

### 使用数据库 URL

最简单的入门方式：

```python
import asyncio
from agents import Agent, Runner
from agents.extensions.memory import SQLAlchemySession

async def main():
    agent = Agent("Assistant")
    
    # Create session using database URL
    session = SQLAlchemySession.from_url(
        "user-123",
        url="sqlite+aiosqlite:///:memory:",
        create_tables=True
    )
    
    result = await Runner.run(agent, "Hello", session=session)
    print(result.final_output)

if __name__ == "__main__":
    asyncio.run(main())
```

### 使用现有引擎

适用于已有 SQLAlchemy 引擎的应用程序：

```python
import asyncio
from agents import Agent, Runner
from agents.extensions.memory import SQLAlchemySession
from sqlalchemy.ext.asyncio import create_async_engine

async def main():
    # Create your database engine
    engine = create_async_engine("postgresql+asyncpg://user:pass@localhost/db")
    
    agent = Agent("Assistant")
    session = SQLAlchemySession(
        "user-456",
        engine=engine,
        create_tables=True
    )
    
    result = await Runner.run(agent, "Hello", session=session)
    print(result.final_output)
    
    # Clean up
    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(main())
```

## API 参考

- [`SQLAlchemySession`][agents.extensions.memory.sqlalchemy_session.SQLAlchemySession] - 主类
- [`Session`][agents.memory.session.Session] - 基础会话协议

================
File: docs/zh/voice/pipeline.md
================
---
search:
  exclude: true
---
# 管道与工作流

[`VoicePipeline`][agents.voice.pipeline.VoicePipeline] 是一个类，可让你轻松将智能体工作流转换为语音应用。你传入要运行的工作流，管道会负责转写输入音频、检测音频何时结束、在合适的时间调用你的工作流，并将工作流输出再转换为音频。

```mermaid
graph LR
    %% Input
    A["🎤 Audio Input"]

    %% Voice Pipeline
    subgraph Voice_Pipeline [Voice Pipeline]
        direction TB
        B["Transcribe (speech-to-text)"]
        C["Your Code"]:::highlight
        D["Text-to-speech"]
        B --> C --> D
    end

    %% Output
    E["🎧 Audio Output"]

    %% Flow
    A --> Voice_Pipeline
    Voice_Pipeline --> E

    %% Custom styling
    classDef highlight fill:#ffcc66,stroke:#333,stroke-width:1px,font-weight:700;

```

## 管道配置

创建管道时，你可以设置以下几项：

1. [`workflow`][agents.voice.workflow.VoiceWorkflowBase]：每次有新音频被转写时运行的代码。
2. 所使用的 [`speech-to-text`][agents.voice.model.STTModel] 和 [`text-to-speech`][agents.voice.model.TTSModel] 模型
3. [`config`][agents.voice.pipeline_config.VoicePipelineConfig]：用于配置例如：
    - 模型提供方，可将模型名称映射到模型
    - 追踪，包括是否禁用追踪、是否上传音频文件、工作流名称、trace IDs 等
    - TTS 和 STT 模型的设置，例如所使用的提示词、语言和数据类型

## 运行管道

你可以通过 [`run()`][agents.voice.pipeline.VoicePipeline.run] 方法运行管道，它允许你以两种形式传入音频输入：

1. [`AudioInput`][agents.voice.input.AudioInput]：适用于你有完整音频转写（或完整音频内容）且只想为其生成结果的场景。这在你不需要检测说话者何时说完时很有用；例如，你有预录音频，或在按键说话（push-to-talk）应用中，用户何时说完很明确。
2. [`StreamedAudioInput`][agents.voice.input.StreamedAudioInput]：适用于你可能需要检测用户何时说完的场景。它允许你在检测到音频分块时将其推送进来，而语音管道会通过称为“activity detection”的过程，在合适的时间自动运行智能体工作流。

## 结果

一次语音管道运行的结果是 [`StreamedAudioResult`][agents.voice.result.StreamedAudioResult]。该对象允许你在事件发生时进行流式输出。存在几种 [`VoiceStreamEvent`][agents.voice.events.VoiceStreamEvent]，包括：

1. [`VoiceStreamEventAudio`][agents.voice.events.VoiceStreamEventAudio]：包含一段音频分块。
2. [`VoiceStreamEventLifecycle`][agents.voice.events.VoiceStreamEventLifecycle]：通知你轮次开始或结束等生命周期事件。
3. [`VoiceStreamEventError`][agents.voice.events.VoiceStreamEventError]：错误事件。

```python

result = await pipeline.run(input)

async for event in result.stream():
    if event.type == "voice_stream_event_audio":
        # play audio
    elif event.type == "voice_stream_event_lifecycle":
        # lifecycle
    elif event.type == "voice_stream_event_error":
        # error
    ...
```

## 最佳实践

### 打断

Agents SDK 目前不支持对 [`StreamedAudioInput`][agents.voice.input.StreamedAudioInput] 的任何内置打断能力。相反，对于每个检测到的轮次，它都会触发你的工作流的一次独立运行。如果你想在应用内处理打断，可以监听 [`VoiceStreamEventLifecycle`][agents.voice.events.VoiceStreamEventLifecycle] 事件。`turn_started` 表示一个新轮次已被转写且处理开始。`turn_ended` 会在相应轮次的所有音频都已分发后触发。你可以使用这些事件在模型开始一个轮次时将说话者的麦克风静音，并在你刷新完该轮次的所有相关音频后取消静音。

================
File: docs/zh/voice/quickstart.md
================
---
search:
  exclude: true
---
# 快速入门

## 先决条件

请确保你已按照 Agents SDK 的基础[快速入门说明](../quickstart.md)进行操作，并设置好虚拟环境。然后，从 SDK 安装可选的语音依赖：

```bash
pip install 'openai-agents[voice]'
```

## 概念

需要了解的主要概念是一个 [`VoicePipeline`][agents.voice.pipeline.VoicePipeline]，这是一个三步流程：

1. 运行语音转文本模型，将音频转为文本。
2. 运行你的代码（通常是一个智能体式工作流），以生成结果。
3. 运行文本转语音模型，将结果文本转换回音频。

```mermaid
graph LR
    %% Input
    A["🎤 Audio Input"]

    %% Voice Pipeline
    subgraph Voice_Pipeline [Voice Pipeline]
        direction TB
        B["Transcribe (speech-to-text)"]
        C["Your Code"]:::highlight
        D["Text-to-speech"]
        B --> C --> D
    end

    %% Output
    E["🎧 Audio Output"]

    %% Flow
    A --> Voice_Pipeline
    Voice_Pipeline --> E

    %% Custom styling
    classDef highlight fill:#ffcc66,stroke:#333,stroke-width:1px,font-weight:700;

```

## 智能体

首先，让我们设置一些智能体。如果你曾使用此 SDK 构建过智能体，这部分会很熟悉。我们将有几个智能体、一次任务转移，以及一个工具。

```python
import asyncio
import random

from agents import (
    Agent,
    function_tool,
)
from agents.extensions.handoff_prompt import prompt_with_handoff_instructions



@function_tool
def get_weather(city: str) -> str:
    """Get the weather for a given city."""
    print(f"[debug] get_weather called with city: {city}")
    choices = ["sunny", "cloudy", "rainy", "snowy"]
    return f"The weather in {city} is {random.choice(choices)}."


spanish_agent = Agent(
    name="Spanish",
    handoff_description="A spanish speaking agent.",
    instructions=prompt_with_handoff_instructions(
        "You're speaking to a human, so be polite and concise. Speak in Spanish.",
    ),
    model="gpt-5.2",
)

agent = Agent(
    name="Assistant",
    instructions=prompt_with_handoff_instructions(
        "You're speaking to a human, so be polite and concise. If the user speaks in Spanish, handoff to the spanish agent.",
    ),
    model="gpt-5.2",
    handoffs=[spanish_agent],
    tools=[get_weather],
)
```

## 语音管道

我们将设置一个简单的语音管道，使用 [`SingleAgentVoiceWorkflow`][agents.voice.workflow.SingleAgentVoiceWorkflow] 作为工作流。

```python
from agents.voice import SingleAgentVoiceWorkflow, VoicePipeline
pipeline = VoicePipeline(workflow=SingleAgentVoiceWorkflow(agent))
```

## 管道运行

```python
import numpy as np
import sounddevice as sd
from agents.voice import AudioInput

# For simplicity, we'll just create 3 seconds of silence
# In reality, you'd get microphone data
buffer = np.zeros(24000 * 3, dtype=np.int16)
audio_input = AudioInput(buffer=buffer)

result = await pipeline.run(audio_input)

# Create an audio player using `sounddevice`
player = sd.OutputStream(samplerate=24000, channels=1, dtype=np.int16)
player.start()

# Play the audio stream as it comes in
async for event in result.stream():
    if event.type == "voice_stream_event_audio":
        player.write(event.data)

```

## 完整示例

```python
import asyncio
import random

import numpy as np
import sounddevice as sd

from agents import (
    Agent,
    function_tool,
    set_tracing_disabled,
)
from agents.voice import (
    AudioInput,
    SingleAgentVoiceWorkflow,
    VoicePipeline,
)
from agents.extensions.handoff_prompt import prompt_with_handoff_instructions


@function_tool
def get_weather(city: str) -> str:
    """Get the weather for a given city."""
    print(f"[debug] get_weather called with city: {city}")
    choices = ["sunny", "cloudy", "rainy", "snowy"]
    return f"The weather in {city} is {random.choice(choices)}."


spanish_agent = Agent(
    name="Spanish",
    handoff_description="A spanish speaking agent.",
    instructions=prompt_with_handoff_instructions(
        "You're speaking to a human, so be polite and concise. Speak in Spanish.",
    ),
    model="gpt-5.2",
)

agent = Agent(
    name="Assistant",
    instructions=prompt_with_handoff_instructions(
        "You're speaking to a human, so be polite and concise. If the user speaks in Spanish, handoff to the spanish agent.",
    ),
    model="gpt-5.2",
    handoffs=[spanish_agent],
    tools=[get_weather],
)


async def main():
    pipeline = VoicePipeline(workflow=SingleAgentVoiceWorkflow(agent))
    buffer = np.zeros(24000 * 3, dtype=np.int16)
    audio_input = AudioInput(buffer=buffer)

    result = await pipeline.run(audio_input)

    # Create an audio player using `sounddevice`
    player = sd.OutputStream(samplerate=24000, channels=1, dtype=np.int16)
    player.start()

    # Play the audio stream as it comes in
    async for event in result.stream():
        if event.type == "voice_stream_event_audio":
            player.write(event.data)


if __name__ == "__main__":
    asyncio.run(main())
```

如果你运行此示例，智能体会和你对话！查看 [examples/voice/static](https://github.com/openai/openai-agents-python/tree/main/examples/voice/static) 中的示例，体验一个你可以亲自与智能体对话的演示。

================
File: docs/zh/voice/tracing.md
================
---
search:
  exclude: true
---
# 追踪

就像[智能体如何被追踪](../tracing.md)一样，语音管道也会被自动追踪。

你可以阅读上面的追踪文档以了解基础追踪信息，但你还可以通过 [`VoicePipelineConfig`][agents.voice.pipeline_config.VoicePipelineConfig] 额外配置管道的追踪。

与追踪相关的关键字段包括：

-   [`tracing_disabled`][agents.voice.pipeline_config.VoicePipelineConfig.tracing_disabled]：控制是否禁用追踪。默认启用追踪。
-   [`trace_include_sensitive_data`][agents.voice.pipeline_config.VoicePipelineConfig.trace_include_sensitive_data]：控制追踪中是否包含潜在敏感数据，例如音频转写文本。这仅适用于语音管道，而不适用于你的 Workflow 内部发生的任何内容。
-   [`trace_include_sensitive_audio_data`][agents.voice.pipeline_config.VoicePipelineConfig.trace_include_sensitive_audio_data]：控制追踪中是否包含音频数据。
-   [`workflow_name`][agents.voice.pipeline_config.VoicePipelineConfig.workflow_name]：追踪工作流的名称。
-   [`group_id`][agents.voice.pipeline_config.VoicePipelineConfig.group_id]：追踪的 `group_id`，用于关联多个追踪记录。
-   [`trace_metadata`][agents.voice.pipeline_config.VoicePipelineConfig.trace_metadata]：要随追踪一并包含的附加元数据。

================
File: docs/zh/agents.md
================
---
search:
  exclude: true
---
# 智能体

智能体是你应用中的核心构建模块。智能体是一个大语言模型（LLM），通过 instructions、tools 以及可选的运行时行为（如任务转移、安全防护措施和 structured outputs）进行配置。

当你想定义或自定义单个智能体时，请使用本页。如果你在决定多个智能体应如何协作，请阅读[智能体编排](multi_agent.md)。

## 下一指南选择

将本页作为智能体定义的枢纽。跳转到与你下一步决策相匹配的相邻指南。

| 如果你想要…… | 接下来阅读 |
| --- | --- |
| 选择模型或提供方配置 | [模型](models/index.md) |
| 为智能体添加能力 | [工具](tools.md) |
| 在管理者式编排和任务转移之间做选择 | [智能体编排](multi_agent.md) |
| 配置任务转移行为 | [任务转移](handoffs.md) |
| 运行轮次、流式传输事件或管理对话状态 | [运行智能体](running_agents.md) |
| 检查最终输出、运行条目或可恢复状态 | [结果](results.md) |
| 共享本地依赖和运行时状态 | [上下文管理](context.md) |

## 基本配置

智能体最常见的属性有：

| 属性 | 必需 | 描述 |
| --- | --- | --- |
| `name` | 是 | 人类可读的智能体名称。 |
| `instructions` | 是 | 系统提示词或动态 instructions 回调。参见[动态 instructions](#dynamic-instructions)。 |
| `prompt` | 否 | OpenAI Responses API 提示词配置。接受静态提示词对象或函数。参见[提示词模板](#prompt-templates)。 |
| `handoff_description` | 否 | 当该智能体作为任务转移目标提供时展示的简短描述。 |
| `handoffs` | 否 | 将对话委派给专业智能体。参见[handoffs](handoffs.md)。 |
| `model` | 否 | 使用哪个 LLM。参见[模型](models/index.md)。 |
| `model_settings` | 否 | 模型调优参数，例如 `temperature`、`top_p` 和 `tool_choice`。 |
| `tools` | 否 | 智能体可调用的工具。参见[工具](tools.md)。 |
| `mcp_servers` | 否 | 智能体使用的 MCP 支持工具。参见[MCP 指南](mcp.md)。 |
| `input_guardrails` | 否 | 在该智能体链首个用户输入上运行的安全防护措施。参见[安全防护措施](guardrails.md)。 |
| `output_guardrails` | 否 | 在该智能体最终输出上运行的安全防护措施。参见[安全防护措施](guardrails.md)。 |
| `output_type` | 否 | 使用结构化输出类型而非纯文本。参见[输出类型](#output-types)。 |
| `tool_use_behavior` | 否 | 控制工具结果是回传给模型还是结束运行。参见[工具使用行为](#tool-use-behavior)。 |
| `reset_tool_choice` | 否 | 在工具调用后重置 `tool_choice`（默认：`True`）以避免工具使用循环。参见[强制工具使用](#forcing-tool-use)。 |

```python
from agents import Agent, ModelSettings, function_tool

@function_tool
def get_weather(city: str) -> str:
    """returns weather info for the specified city."""
    return f"The weather in {city} is sunny"

agent = Agent(
    name="Haiku agent",
    instructions="Always respond in haiku form",
    model="gpt-5-nano",
    tools=[get_weather],
)
```

## 提示词模板

你可以通过设置 `prompt` 引用在 OpenAI 平台中创建的提示词模板。这适用于使用 Responses API 的 OpenAI 模型。

要使用它，请：

1. 访问 https://platform.openai.com/playground/prompts
2. 创建一个新的提示词变量 `poem_style`。
3. 创建一个内容为以下内容的系统提示词：

    ```
    Write a poem in {{poem_style}}
    ```

4. 使用 `--prompt-id` 标志运行示例。

```python
from agents import Agent

agent = Agent(
    name="Prompted assistant",
    prompt={
        "id": "pmpt_123",
        "version": "1",
        "variables": {"poem_style": "haiku"},
    },
)
```

你也可以在运行时动态生成提示词：

```python
from dataclasses import dataclass

from agents import Agent, GenerateDynamicPromptData, Runner

@dataclass
class PromptContext:
    prompt_id: str
    poem_style: str


async def build_prompt(data: GenerateDynamicPromptData):
    ctx: PromptContext = data.context.context
    return {
        "id": ctx.prompt_id,
        "version": "1",
        "variables": {"poem_style": ctx.poem_style},
    }


agent = Agent(name="Prompted assistant", prompt=build_prompt)
result = await Runner.run(
    agent,
    "Say hello",
    context=PromptContext(prompt_id="pmpt_123", poem_style="limerick"),
)
```

## 上下文

智能体在其 `context` 类型上是泛型的。上下文是一个依赖注入工具：它是你创建并传递给 `Runner.run()` 的对象，会被传递给每个智能体、工具、任务转移等，并作为智能体运行所需依赖和状态的集合。你可以将任意 Python 对象作为上下文提供。

阅读[上下文指南](context.md)，了解完整的 `RunContextWrapper` 能力面、共享使用量跟踪、嵌套 `tool_input` 以及序列化注意事项。

```python
@dataclass
class UserContext:
    name: str
    uid: str
    is_pro_user: bool

    async def fetch_purchases() -> list[Purchase]:
        return ...

agent = Agent[UserContext](
    ...,
)
```

## 输出类型

默认情况下，智能体产生纯文本（即 `str`）输出。如果你希望智能体产生特定类型的输出，可以使用 `output_type` 参数。常见选择是使用 [Pydantic](https://docs.pydantic.dev/) 对象，但我们支持任何可被 Pydantic [TypeAdapter](https://docs.pydantic.dev/latest/api/type_adapter/) 包装的类型——dataclasses、列表、TypedDict 等。

```python
from pydantic import BaseModel
from agents import Agent


class CalendarEvent(BaseModel):
    name: str
    date: str
    participants: list[str]

agent = Agent(
    name="Calendar extractor",
    instructions="Extract calendar events from text",
    output_type=CalendarEvent,
)
```

!!! note

    当你传入 `output_type` 时，这会告诉模型使用[structured outputs](https://platform.openai.com/docs/guides/structured-outputs)而不是常规纯文本响应。

## 多智能体系统设计模式

设计多智能体系统有很多方式，但我们通常看到两种广泛适用的模式：

1. 管理者（Agents as tools）：一个中心管理者/编排器将专业子智能体作为工具调用，并保留对对话的控制。
2. 任务转移：对等智能体将控制权转移给接管对话的专业智能体。这是去中心化的。

更多细节请参见[我们构建智能体的实用指南](https://cdn.openai.com/business-guides-and-resources/a-practical-guide-to-building-agents.pdf)。

### 管理者（Agents as tools）

`customer_facing_agent` 处理所有用户交互，并调用以工具形式暴露的专业子智能体。更多内容见[工具](tools.md#agents-as-tools)文档。

```python
from agents import Agent

booking_agent = Agent(...)
refund_agent = Agent(...)

customer_facing_agent = Agent(
    name="Customer-facing agent",
    instructions=(
        "Handle all direct user communication. "
        "Call the relevant tools when specialized expertise is needed."
    ),
    tools=[
        booking_agent.as_tool(
            tool_name="booking_expert",
            tool_description="Handles booking questions and requests.",
        ),
        refund_agent.as_tool(
            tool_name="refund_expert",
            tool_description="Handles refund questions and requests.",
        )
    ],
)
```

### 任务转移

任务转移是智能体可委派的子智能体。当发生任务转移时，被委派的智能体会接收对话历史并接管对话。该模式支持模块化、专业化的智能体，使其在单一任务上表现出色。更多内容见[任务转移](handoffs.md)文档。

```python
from agents import Agent

booking_agent = Agent(...)
refund_agent = Agent(...)

triage_agent = Agent(
    name="Triage agent",
    instructions=(
        "Help the user with their questions. "
        "If they ask about booking, hand off to the booking agent. "
        "If they ask about refunds, hand off to the refund agent."
    ),
    handoffs=[booking_agent, refund_agent],
)
```

## 动态 instructions

在大多数情况下，你可以在创建智能体时提供 instructions。不过，你也可以通过函数提供动态 instructions。该函数会接收智能体和上下文，并且必须返回提示词。常规函数和 `async` 函数都支持。

```python
def dynamic_instructions(
    context: RunContextWrapper[UserContext], agent: Agent[UserContext]
) -> str:
    return f"The user's name is {context.context.name}. Help them with their questions."


agent = Agent[UserContext](
    name="Triage agent",
    instructions=dynamic_instructions,
)
```

## 生命周期事件（hooks）

有时，你希望观察智能体的生命周期。例如，你可能希望在特定事件发生时记录事件、预取数据或记录使用情况。

有两种 hook 作用域：

-   [`RunHooks`][agents.lifecycle.RunHooks] 观察整个 `Runner.run(...)` 调用，包括向其他智能体的任务转移。
-   [`AgentHooks`][agents.lifecycle.AgentHooks] 通过 `agent.hooks` 附加到特定智能体实例。

回调上下文也会根据事件而变化：

-   智能体开始/结束 hooks 接收 [`AgentHookContext`][agents.run_context.AgentHookContext]，它包装了你的原始上下文并携带共享的运行使用状态。
-   LLM、工具和任务转移 hooks 接收 [`RunContextWrapper`][agents.run_context.RunContextWrapper]。

典型 hook 时机：

-   `on_agent_start` / `on_agent_end`：当特定智能体开始或完成生成最终输出时。
-   `on_llm_start` / `on_llm_end`：每次模型调用前后立即触发。
-   `on_tool_start` / `on_tool_end`：每次本地工具调用前后触发。
-   `on_handoff`：当控制权从一个智能体移动到另一个智能体时。

当你希望为整个工作流设置单一观察者时使用 `RunHooks`，当某个智能体需要自定义副作用时使用 `AgentHooks`。

```python
from agents import Agent, RunHooks, Runner


class LoggingHooks(RunHooks):
    async def on_agent_start(self, context, agent):
        print(f"Starting {agent.name}")

    async def on_llm_end(self, context, agent, response):
        print(f"{agent.name} produced {len(response.output)} output items")

    async def on_agent_end(self, context, agent, output):
        print(f"{agent.name} finished with usage: {context.usage}")


agent = Agent(name="Assistant", instructions="Be concise.")
result = await Runner.run(agent, "Explain quines", hooks=LoggingHooks())
print(result.final_output)
```

完整回调能力面请参见[生命周期 API 参考](ref/lifecycle.md)。

## 安全防护措施

安全防护措施允许你在智能体运行的同时并行地对用户输入执行检查/验证，并在智能体输出产生后对其进行检查/验证。例如，你可以筛查用户输入和智能体输出的相关性。更多内容见[安全防护措施](guardrails.md)文档。

## 智能体克隆/复制

通过在智能体上使用 `clone()` 方法，你可以复制一个智能体，并可按需更改任意属性。

```python
pirate_agent = Agent(
    name="Pirate",
    instructions="Write like a pirate",
    model="gpt-5.2",
)

robot_agent = pirate_agent.clone(
    name="Robot",
    instructions="Write like a robot",
)
```

## 强制工具使用

提供工具列表并不总意味着 LLM 会使用工具。你可以通过设置 [`ModelSettings.tool_choice`][agents.model_settings.ModelSettings.tool_choice] 强制工具使用。有效值包括：

1. `auto`，允许 LLM 自行决定是否使用工具。
2. `required`，要求 LLM 使用工具（但可智能决定使用哪个工具）。
3. `none`，要求 LLM _不_ 使用工具。
4. 设置特定字符串，例如 `my_tool`，要求 LLM 使用该特定工具。

```python
from agents import Agent, Runner, function_tool, ModelSettings

@function_tool
def get_weather(city: str) -> str:
    """Returns weather info for the specified city."""
    return f"The weather in {city} is sunny"

agent = Agent(
    name="Weather Agent",
    instructions="Retrieve weather details.",
    tools=[get_weather],
    model_settings=ModelSettings(tool_choice="get_weather")
)
```

## 工具使用行为

`Agent` 配置中的 `tool_use_behavior` 参数控制如何处理工具输出：

- `"run_llm_again"`：默认值。运行工具后，由 LLM 处理结果并生成最终响应。
- `"stop_on_first_tool"`：将第一次工具调用的输出作为最终响应，不再进行后续 LLM 处理。

```python
from agents import Agent, Runner, function_tool, ModelSettings

@function_tool
def get_weather(city: str) -> str:
    """Returns weather info for the specified city."""
    return f"The weather in {city} is sunny"

agent = Agent(
    name="Weather Agent",
    instructions="Retrieve weather details.",
    tools=[get_weather],
    tool_use_behavior="stop_on_first_tool"
)
```

- `StopAtTools(stop_at_tool_names=[...])`：若调用了任一指定工具则停止，并将其输出作为最终响应。

```python
from agents import Agent, Runner, function_tool
from agents.agent import StopAtTools

@function_tool
def get_weather(city: str) -> str:
    """Returns weather info for the specified city."""
    return f"The weather in {city} is sunny"

@function_tool
def sum_numbers(a: int, b: int) -> int:
    """Adds two numbers."""
    return a + b

agent = Agent(
    name="Stop At Stock Agent",
    instructions="Get weather or sum numbers.",
    tools=[get_weather, sum_numbers],
    tool_use_behavior=StopAtTools(stop_at_tool_names=["get_weather"])
)
```

- `ToolsToFinalOutputFunction`：自定义函数，用于处理工具结果并决定停止还是继续交给 LLM。

```python
from agents import Agent, Runner, function_tool, FunctionToolResult, RunContextWrapper
from agents.agent import ToolsToFinalOutputResult
from typing import List, Any

@function_tool
def get_weather(city: str) -> str:
    """Returns weather info for the specified city."""
    return f"The weather in {city} is sunny"

def custom_tool_handler(
    context: RunContextWrapper[Any],
    tool_results: List[FunctionToolResult]
) -> ToolsToFinalOutputResult:
    """Processes tool results to decide final output."""
    for result in tool_results:
        if result.output and "sunny" in result.output:
            return ToolsToFinalOutputResult(
                is_final_output=True,
                final_output=f"Final weather: {result.output}"
            )
    return ToolsToFinalOutputResult(
        is_final_output=False,
        final_output=None
    )

agent = Agent(
    name="Weather Agent",
    instructions="Retrieve weather details.",
    tools=[get_weather],
    tool_use_behavior=custom_tool_handler
)
```

!!! note

    为防止无限循环，框架会在工具调用后自动将 `tool_choice` 重置为 "auto"。该行为可通过 [`agent.reset_tool_choice`][agents.agent.Agent.reset_tool_choice] 配置。出现无限循环的原因是工具结果会发送给 LLM，而 LLM 随后又因 `tool_choice` 生成新的工具调用，如此无限往复。

================
File: docs/zh/config.md
================
---
search:
  exclude: true
---
# 配置

本页介绍 SDK 范围内的默认设置，你通常会在应用启动时一次性完成配置，例如默认 OpenAI 密钥或客户端、默认 OpenAI API 形态、追踪导出默认值以及日志行为。

如果你需要改为配置某个特定智能体或某次运行，请先查看：

-   [运行智能体](running_agents.md)，了解 `RunConfig`、会话和对话状态选项。
-   [模型](models/index.md)，了解模型选择和提供方配置。
-   [追踪](tracing.md)，了解按运行设置的追踪元数据和自定义追踪进程。

## API 密钥与客户端

默认情况下，SDK 使用 `OPENAI_API_KEY` 环境变量来处理 LLM 请求和追踪。该密钥会在 SDK 首次创建 OpenAI 客户端时解析（延迟初始化），因此请在首次模型调用前设置该环境变量。如果你无法在应用启动前设置该环境变量，可以使用 [set_default_openai_key()][agents.set_default_openai_key] 函数来设置密钥。

```python
from agents import set_default_openai_key

set_default_openai_key("sk-...")
```

或者，你也可以配置要使用的 OpenAI 客户端。默认情况下，SDK 会创建一个 `AsyncOpenAI` 实例，使用环境变量中的 API 密钥或上面设置的默认密钥。你可以通过 [set_default_openai_client()][agents.set_default_openai_client] 函数进行更改。

```python
from openai import AsyncOpenAI
from agents import set_default_openai_client

custom_client = AsyncOpenAI(base_url="...", api_key="...")
set_default_openai_client(custom_client)
```

最后，你还可以自定义所使用的 OpenAI API。默认情况下，我们使用 OpenAI Responses API。你可以通过 [set_default_openai_api()][agents.set_default_openai_api] 函数将其覆盖为 Chat Completions API。

```python
from agents import set_default_openai_api

set_default_openai_api("chat_completions")
```

## 追踪

默认启用追踪。默认情况下，它使用与上文模型请求相同的 OpenAI API 密钥（即环境变量中的密钥或你设置的默认密钥）。你可以使用 [`set_tracing_export_api_key`][agents.set_tracing_export_api_key] 函数专门设置用于追踪的 API 密钥。

```python
from agents import set_tracing_export_api_key

set_tracing_export_api_key("sk-...")
```

如果在使用默认导出器时，你需要将追踪归属到特定组织或项目，请在应用启动前设置以下环境变量：

```bash
export OPENAI_ORG_ID="org_..."
export OPENAI_PROJECT_ID="proj_..."
```

你也可以按单次运行设置追踪 API 密钥，而无需更改全局导出器。

```python
from agents import Runner, RunConfig

await Runner.run(
    agent,
    input="Hello",
    run_config=RunConfig(tracing={"api_key": "sk-tracing-123"}),
)
```

你还可以使用 [`set_tracing_disabled()`][agents.set_tracing_disabled] 函数完全禁用追踪。

```python
from agents import set_tracing_disabled

set_tracing_disabled(True)
```

如果你希望保持追踪启用，但从追踪负载中排除可能的敏感输入/输出，请将 [`RunConfig.trace_include_sensitive_data`][agents.run.RunConfig.trace_include_sensitive_data] 设置为 `False`：

```python
from agents import Runner, RunConfig

await Runner.run(
    agent,
    input="Hello",
    run_config=RunConfig(trace_include_sensitive_data=False),
)
```

你也可以不改代码，而是在应用启动前设置以下环境变量来更改默认行为：

```bash
export OPENAI_AGENTS_TRACE_INCLUDE_SENSITIVE_DATA=0
```

完整的追踪控制请参阅[追踪指南](tracing.md)。

## 调试日志

SDK 定义了两个 Python 日志记录器（`openai.agents` 和 `openai.agents.tracing`），默认不附加处理器。日志遵循你应用的 Python 日志配置。

要启用详细日志，请使用 [`enable_verbose_stdout_logging()`][agents.enable_verbose_stdout_logging] 函数。

```python
from agents import enable_verbose_stdout_logging

enable_verbose_stdout_logging()
```

或者，你可以通过添加处理器、过滤器、格式化器等来自定义日志。详情可参阅 [Python 日志指南](https://docs.python.org/3/howto/logging.html)。

```python
import logging

logger = logging.getLogger("openai.agents") # or openai.agents.tracing for the Tracing logger

# To make all logs show up
logger.setLevel(logging.DEBUG)
# To make info and above show up
logger.setLevel(logging.INFO)
# To make warning and above show up
logger.setLevel(logging.WARNING)
# etc

# You can customize this as needed, but this will output to `stderr` by default
logger.addHandler(logging.StreamHandler())
```

### 日志中的敏感数据

某些日志可能包含敏感数据（例如用户数据）。

默认情况下，SDK **不会**记录 LLM 输入/输出或工具输入/输出。这些保护由以下项控制：

```bash
OPENAI_AGENTS_DONT_LOG_MODEL_DATA=1
OPENAI_AGENTS_DONT_LOG_TOOL_DATA=1
```

如果你需要临时包含这些数据以进行调试，请在应用启动前将任一变量设为 `0`（或 `false`）：

```bash
export OPENAI_AGENTS_DONT_LOG_MODEL_DATA=0
export OPENAI_AGENTS_DONT_LOG_TOOL_DATA=0
```

================
File: docs/zh/context.md
================
---
search:
  exclude: true
---
# 上下文管理

Context 是一个含义宽泛的术语。你可能会关心两大类上下文：

1. 你的代码在本地可用的上下文：这是在工具函数运行时、`on_handoff` 这类回调期间、生命周期钩子中等可能需要的数据和依赖。
2. LLM 可用的上下文：这是 LLM 在生成响应时能看到的数据。

## 本地上下文

这通过 [`RunContextWrapper`][agents.run_context.RunContextWrapper] 类及其内部的 [`context`][agents.run_context.RunContextWrapper.context] 属性来表示。其工作方式如下：

1. 你创建任意想要的 Python 对象。常见模式是使用 dataclass 或 Pydantic 对象。
2. 你将该对象传给各类运行方法（例如 `Runner.run(..., context=whatever)`）。
3. 你的所有工具调用、生命周期钩子等都会收到一个包装器对象 `RunContextWrapper[T]`，其中 `T` 表示你的上下文对象类型，你可以通过 `wrapper.context` 访问它。

**最重要**的一点是：在一次给定的智能体运行中，每个智能体、工具函数、生命周期等都必须使用相同的上下文_类型_。

你可以将上下文用于以下场景：

-   运行的上下文数据（例如用户名/uid 或其他用户信息）
-   依赖项（例如 logger 对象、数据获取器等）
-   辅助函数

!!! danger "注意"

    上下文对象**不会**发送给 LLM。它纯粹是一个本地对象，你可以读取、写入并调用其方法。

在单次运行中，派生包装器共享同一底层应用上下文、审批状态和用量跟踪。嵌套的 [`Agent.as_tool()`][agents.agent.Agent.as_tool] 运行可能会附加不同的 `tool_input`，但默认不会获得应用状态的隔离副本。

### `RunContextWrapper` 暴露的内容

[`RunContextWrapper`][agents.run_context.RunContextWrapper] 是对你应用自定义上下文对象的包装。实际中你最常用的是：

-   [`wrapper.context`][agents.run_context.RunContextWrapper.context]：用于你自己的可变应用状态和依赖。
-   [`wrapper.usage`][agents.run_context.RunContextWrapper.usage]：用于当前运行中的聚合请求与 token 用量。
-   [`wrapper.tool_input`][agents.run_context.RunContextWrapper.tool_input]：用于当前运行在 [`Agent.as_tool()`][agents.agent.Agent.as_tool] 内部执行时的结构化输入。
-   当你需要以编程方式更新审批状态时，使用 [`wrapper.approve_tool(...)`][agents.run_context.RunContextWrapper.approve_tool] / [`wrapper.reject_tool(...)`][agents.run_context.RunContextWrapper.reject_tool]。

只有 `wrapper.context` 是你应用自定义的对象。其他字段都是由 SDK 管理的运行时元数据。

如果你后续为 human-in-the-loop 或持久化作业工作流序列化 [`RunState`][agents.run_state.RunState]，这些运行时元数据会随状态一起保存。如果你打算持久化或传输序列化状态，请避免在 [`RunContextWrapper.context`][agents.run_context.RunContextWrapper.context] 中放入机密信息。

会话状态是另一个独立问题。根据你希望如何延续多轮对话，使用 `result.to_input_list()`、`session`、`conversation_id` 或 `previous_response_id`。相关决策请参见 [results](results.md)、[running agents](running_agents.md) 和 [sessions](sessions/index.md)。

```python
import asyncio
from dataclasses import dataclass

from agents import Agent, RunContextWrapper, Runner, function_tool

@dataclass
class UserInfo:  # (1)!
    name: str
    uid: int

@function_tool
async def fetch_user_age(wrapper: RunContextWrapper[UserInfo]) -> str:  # (2)!
    """Fetch the age of the user. Call this function to get user's age information."""
    return f"The user {wrapper.context.name} is 47 years old"

async def main():
    user_info = UserInfo(name="John", uid=123)

    agent = Agent[UserInfo](  # (3)!
        name="Assistant",
        tools=[fetch_user_age],
    )

    result = await Runner.run(  # (4)!
        starting_agent=agent,
        input="What is the age of the user?",
        context=user_info,
    )

    print(result.final_output)  # (5)!
    # The user John is 47 years old.

if __name__ == "__main__":
    asyncio.run(main())
```

1. 这是上下文对象。这里我们使用了 dataclass，但你可以使用任意类型。
2. 这是一个工具。你可以看到它接收 `RunContextWrapper[UserInfo]`。工具实现会从上下文中读取。
3. 我们为智能体标注了泛型 `UserInfo`，这样类型检查器就能捕获错误（例如，如果我们尝试传入一个使用不同上下文类型的工具）。
4. 上下文被传递给 `run` 函数。
5. 智能体正确调用工具并获取年龄。

---

### 高级：`ToolContext`

在某些情况下，你可能希望访问正在执行的工具的额外元数据——例如其名称、调用 ID 或原始参数字符串。  
为此，你可以使用 [`ToolContext`][agents.tool_context.ToolContext] 类，它扩展了 `RunContextWrapper`。

```python
from typing import Annotated
from pydantic import BaseModel, Field
from agents import Agent, Runner, function_tool
from agents.tool_context import ToolContext

class WeatherContext(BaseModel):
    user_id: str

class Weather(BaseModel):
    city: str = Field(description="The city name")
    temperature_range: str = Field(description="The temperature range in Celsius")
    conditions: str = Field(description="The weather conditions")

@function_tool
def get_weather(ctx: ToolContext[WeatherContext], city: Annotated[str, "The city to get the weather for"]) -> Weather:
    print(f"[debug] Tool context: (name: {ctx.tool_name}, call_id: {ctx.tool_call_id}, args: {ctx.tool_arguments})")
    return Weather(city=city, temperature_range="14-20C", conditions="Sunny with wind.")

agent = Agent(
    name="Weather Agent",
    instructions="You are a helpful agent that can tell the weather of a given city.",
    tools=[get_weather],
)
```

`ToolContext` 提供与 `RunContextWrapper` 相同的 `.context` 属性，  
以及当前工具调用特有的附加字段：

- `tool_name` – 被调用工具的名称  
- `tool_call_id` – 此次工具调用的唯一标识符  
- `tool_arguments` – 传递给工具的原始参数字符串  

当你在执行期间需要工具级元数据时，请使用 `ToolContext`。  
对于智能体与工具之间的通用上下文共享，`RunContextWrapper` 仍然足够。由于 `ToolContext` 扩展自 `RunContextWrapper`，当嵌套的 `Agent.as_tool()` 运行提供了结构化输入时，它也可以暴露 `.tool_input`。

---

## 智能体/LLM 上下文

调用 LLM 时，它**唯一**能看到的数据来自对话历史。这意味着，如果你想让某些新数据可供 LLM 使用，必须以某种方式将其放入该历史中。可采用以下几种方式：

1. 你可以把它加入智能体的 `instructions`。这也称为“系统提示词”或“开发者消息”。系统提示词可以是静态字符串，也可以是接收上下文并输出字符串的动态函数。这是处理始终有用信息的常见策略（例如用户名或当前日期）。
2. 在调用 `Runner.run` 函数时将其加入 `input`。这与 `instructions` 策略类似，但允许你的消息处于[命令链](https://cdn.openai.com/spec/model-spec-2024-05-08.html#follow-the-chain-of-command)中更低的位置。
3. 通过工具调用暴露它。这对_按需_上下文很有用——LLM 决定何时需要某些数据，并可调用工具来获取这些数据。
4. 使用检索或网络检索。这些是能够从文件或数据库（检索）或网络（网络检索）获取相关数据的特殊工具。这有助于让响应“基于”相关上下文数据。

================
File: docs/zh/examples.md
================
---
search:
  exclude: true
---
# 示例

请在 [repo](https://github.com/openai/openai-agents-python/tree/main/examples) 的 examples 部分查看 SDK 的多种 sample code 实现。这些示例按多个目录组织，展示了不同的模式和能力。

## 目录

-   **[agent_patterns](https://github.com/openai/openai-agents-python/tree/main/examples/agent_patterns):**
    此目录中的示例说明了常见的智能体设计模式，例如：

    -   确定性工作流
    -   Agents as tools
    -   并行智能体执行
    -   条件式工具使用
    -   输入/输出安全防护措施
    -   LLM 作为评审
    -   路由
    -   流式传输安全防护措施

-   **[basic](https://github.com/openai/openai-agents-python/tree/main/examples/basic):**
    这些示例展示了 SDK 的基础能力，例如：

    -   Hello World 示例（默认模型、GPT-5、开放权重模型）
    -   智能体生命周期管理
    -   动态系统提示词
    -   流式传输输出（文本、条目、函数调用参数）
    -   跨轮次使用共享会话辅助器的 Responses websocket 传输（`examples/basic/stream_ws.py`）
    -   提示词模板
    -   文件处理（本地和远程、图像和 PDF）
    -   用量追踪
    -   非严格输出类型
    -   先前响应 ID 的使用

-   **[customer_service](https://github.com/openai/openai-agents-python/tree/main/examples/customer_service):**
    面向航空公司的客户服务系统示例。

-   **[financial_research_agent](https://github.com/openai/openai-agents-python/tree/main/examples/financial_research_agent):**
    一个金融研究智能体，演示了使用智能体和工具进行金融数据分析的结构化研究工作流。

-   **[handoffs](https://github.com/openai/openai-agents-python/tree/main/examples/handoffs):**
    查看带有消息过滤的智能体任务转移实践示例。

-   **[hosted_mcp](https://github.com/openai/openai-agents-python/tree/main/examples/hosted_mcp):**
    演示如何使用托管 MCP（Model context protocol）连接器和审批的示例。

-   **[mcp](https://github.com/openai/openai-agents-python/tree/main/examples/mcp):**
    了解如何使用 MCP（Model context protocol）构建智能体，包括：

    -   文件系统示例
    -   Git 示例
    -   MCP 提示词服务示例
    -   SSE（服务端发送事件）示例
    -   可流式 HTTP 示例

-   **[memory](https://github.com/openai/openai-agents-python/tree/main/examples/memory):**
    不同智能体记忆实现的示例，包括：

    -   SQLite 会话存储
    -   高级 SQLite 会话存储
    -   Redis 会话存储
    -   SQLAlchemy 会话存储
    -   Dapr 状态存储会话存储
    -   加密会话存储
    -   OpenAI Conversations 会话存储
    -   Responses 压缩会话存储

-   **[model_providers](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers):**
    探索如何在 SDK 中使用非 OpenAI 模型，包括自定义提供方和 LiteLLM 集成。

-   **[realtime](https://github.com/openai/openai-agents-python/tree/main/examples/realtime):**
    展示如何使用 SDK 构建实时体验的示例，包括：

    -   使用结构化文本和图像消息的 Web 应用模式
    -   命令行音频循环与播放处理
    -   通过 WebSocket 集成 Twilio Media Streams
    -   使用 Realtime Calls API 附加流程进行 Twilio SIP 集成

-   **[reasoning_content](https://github.com/openai/openai-agents-python/tree/main/examples/reasoning_content):**
    演示如何处理推理内容和 structured outputs 的示例。

-   **[research_bot](https://github.com/openai/openai-agents-python/tree/main/examples/research_bot):**
    简单的深度研究克隆，演示了复杂的多智能体研究工作流。

-   **[tools](https://github.com/openai/openai-agents-python/tree/main/examples/tools):**
    了解如何实现由OpenAI托管的工具和实验性的 Codex 工具能力，例如：

    -   网络检索以及带过滤器的网络检索
    -   文件检索
    -   Code Interpreter
    -   带内联技能的托管容器 shell（`examples/tools/container_shell_inline_skill.py`）
    -   带技能引用的托管容器 shell（`examples/tools/container_shell_skill_reference.py`）
    -   计算机操作
    -   图像生成
    -   实验性 Codex 工具工作流（`examples/tools/codex.py`）
    -   实验性 Codex 同线程工作流（`examples/tools/codex_same_thread.py`）

-   **[voice](https://github.com/openai/openai-agents-python/tree/main/examples/voice):**
    查看语音智能体示例，使用我们的 TTS 和 STT 模型，包括流式语音示例。

================
File: docs/zh/guardrails.md
================
---
search:
  exclude: true
---
# 安全防护措施

安全防护措施让你能够对用户输入和智能体输出进行检查与校验。比如，假设你有一个智能体，使用一个非常智能（因此也较慢/昂贵）的模型来帮助处理客户请求。你肯定不希望恶意用户让这个模型帮他们做数学作业。因此，你可以先用一个快速/便宜的模型运行安全防护措施。如果安全防护措施检测到恶意使用，它可以立即抛出错误并阻止昂贵模型运行，从而节省时间和成本（**在使用阻塞式安全防护措施时；对于并行安全防护措施，昂贵模型可能在安全防护措施完成前就已经开始运行。详情见下方“执行模式”**）。

安全防护措施有两种：

1. 输入安全防护措施：作用于初始用户输入
2. 输出安全防护措施：作用于最终智能体输出

## 工作流边界

安全防护措施会附加在智能体和工具上，但它们在工作流中的运行时机并不相同：

-   **输入安全防护措施**仅对链路中的第一个智能体运行。
-   **输出安全防护措施**仅对产出最终输出的智能体运行。
-   **工具安全防护措施**会在每次自定义 function-tool 调用时运行，执行前运行输入安全防护措施，执行后运行输出安全防护措施。

如果你的工作流包含管理者、任务转移或被委派的专家，并且需要围绕每次自定义 function-tool 调用做检查，请使用工具安全防护措施，而不要只依赖智能体级别的输入/输出安全防护措施。

## 输入安全防护措施

输入安全防护措施分 3 步运行：

1. 首先，安全防护措施接收与传给智能体相同的输入。
2. 接着，运行安全防护函数，产出一个 [`GuardrailFunctionOutput`][agents.guardrail.GuardrailFunctionOutput]，随后被封装为 [`InputGuardrailResult`][agents.guardrail.InputGuardrailResult]
3. 最后，我们检查 [`.tripwire_triggered`][agents.guardrail.GuardrailFunctionOutput.tripwire_triggered] 是否为 true。若为 true，会抛出 [`InputGuardrailTripwireTriggered`][agents.exceptions.InputGuardrailTripwireTriggered] 异常，以便你恰当地响应用户或处理异常。

!!! Note

    输入安全防护措施旨在作用于用户输入，因此只有当该智能体是*第一个*智能体时，它的安全防护措施才会运行。你可能会疑惑：为什么 `guardrails` 属性放在智能体上，而不是传给 `Runner.run`？这是因为安全防护措施通常与具体的 Agent 相关——不同智能体通常会使用不同的安全防护措施，把代码就近放置有助于提升可读性。

### 执行模式

输入安全防护措施支持两种执行模式：

- **并行执行**（默认，`run_in_parallel=True`）：安全防护措施与智能体执行并发运行。由于两者同时开始，这能提供最佳延迟表现。不过，如果安全防护措施失败，智能体在被取消前可能已经消耗了 token 并执行了工具调用。

- **阻塞执行**（`run_in_parallel=False`）：安全防护措施会在智能体启动*之前*运行并完成。如果触发了安全防护触发器，智能体将不会执行，从而避免 token 消耗和工具执行。这非常适合成本优化，以及你希望避免工具调用潜在副作用的场景。

## 输出安全防护措施

输出安全防护措施分 3 步运行：

1. 首先，安全防护措施接收智能体生成的输出。
2. 接着，运行安全防护函数，产出一个 [`GuardrailFunctionOutput`][agents.guardrail.GuardrailFunctionOutput]，随后被封装为 [`OutputGuardrailResult`][agents.guardrail.OutputGuardrailResult]
3. 最后，我们检查 [`.tripwire_triggered`][agents.guardrail.GuardrailFunctionOutput.tripwire_triggered] 是否为 true。若为 true，会抛出 [`OutputGuardrailTripwireTriggered`][agents.exceptions.OutputGuardrailTripwireTriggered] 异常，以便你恰当地响应用户或处理异常。

!!! Note

    输出安全防护措施旨在作用于最终智能体输出，因此只有当该智能体是*最后一个*智能体时，它的安全防护措施才会运行。与输入安全防护措施类似，这样设计是因为安全防护措施通常与具体 Agent 相关——不同智能体通常会使用不同的安全防护措施，把代码就近放置有助于提升可读性。

    输出安全防护措施总是在智能体完成后运行，因此不支持 `run_in_parallel` 参数。

## 工具安全防护措施

工具安全防护措施会包裹**工具调用**，让你能够在执行前后校验或拦截工具调用。它们配置在工具本身上，并在每次调用该工具时运行。

- 输入工具安全防护措施在工具执行前运行，可跳过调用、用一条消息替换输出，或抛出触发器。
- 输出工具安全防护措施在工具执行后运行，可替换输出或抛出触发器。
- 工具安全防护措施仅适用于通过 [`function_tool`][agents.tool.function_tool] 创建的 function tools。任务转移通过 SDK 的 handoff 管线运行，而不是普通 function-tool 管线，因此工具安全防护措施不适用于任务转移调用本身。托管工具（`WebSearchTool`、`FileSearchTool`、`HostedMCPTool`、`CodeInterpreterTool`、`ImageGenerationTool`）和内置执行工具（`ComputerTool`、`ShellTool`、`ApplyPatchTool`、`LocalShellTool`）也不使用这条安全防护措施管线，且 [`Agent.as_tool()`][agents.agent.Agent.as_tool] 目前也不直接暴露工具安全防护措施选项。

详情见下方代码片段。

## 触发器

如果输入或输出未通过安全防护措施，安全防护措施可通过触发器发出信号。一旦检测到某个安全防护措施触发了触发器，我们会立即抛出 `{Input,Output}GuardrailTripwireTriggered` 异常并终止智能体执行。

## 安全防护措施实现

你需要提供一个函数来接收输入，并返回一个 [`GuardrailFunctionOutput`][agents.guardrail.GuardrailFunctionOutput]。在这个示例中，我们会通过在底层运行一个智能体来实现。

```python
from pydantic import BaseModel
from agents import (
    Agent,
    GuardrailFunctionOutput,
    InputGuardrailTripwireTriggered,
    RunContextWrapper,
    Runner,
    TResponseInputItem,
    input_guardrail,
)

class MathHomeworkOutput(BaseModel):
    is_math_homework: bool
    reasoning: str

guardrail_agent = Agent( # (1)!
    name="Guardrail check",
    instructions="Check if the user is asking you to do their math homework.",
    output_type=MathHomeworkOutput,
)


@input_guardrail
async def math_guardrail( # (2)!
    ctx: RunContextWrapper[None], agent: Agent, input: str | list[TResponseInputItem]
) -> GuardrailFunctionOutput:
    result = await Runner.run(guardrail_agent, input, context=ctx.context)

    return GuardrailFunctionOutput(
        output_info=result.final_output, # (3)!
        tripwire_triggered=result.final_output.is_math_homework,
    )


agent = Agent(  # (4)!
    name="Customer support agent",
    instructions="You are a customer support agent. You help customers with their questions.",
    input_guardrails=[math_guardrail],
)

async def main():
    # This should trip the guardrail
    try:
        await Runner.run(agent, "Hello, can you help me solve for x: 2x + 3 = 11?")
        print("Guardrail didn't trip - this is unexpected")

    except InputGuardrailTripwireTriggered:
        print("Math homework guardrail tripped")
```

1. 我们会在安全防护函数中使用这个智能体。
2. 这是安全防护函数，它接收智能体的输入/上下文，并返回结果。
3. 我们可以在安全防护结果中包含额外信息。
4. 这是真正定义工作流的智能体。

输出安全防护措施类似。

```python
from pydantic import BaseModel
from agents import (
    Agent,
    GuardrailFunctionOutput,
    OutputGuardrailTripwireTriggered,
    RunContextWrapper,
    Runner,
    output_guardrail,
)
class MessageOutput(BaseModel): # (1)!
    response: str

class MathOutput(BaseModel): # (2)!
    reasoning: str
    is_math: bool

guardrail_agent = Agent(
    name="Guardrail check",
    instructions="Check if the output includes any math.",
    output_type=MathOutput,
)

@output_guardrail
async def math_guardrail(  # (3)!
    ctx: RunContextWrapper, agent: Agent, output: MessageOutput
) -> GuardrailFunctionOutput:
    result = await Runner.run(guardrail_agent, output.response, context=ctx.context)

    return GuardrailFunctionOutput(
        output_info=result.final_output,
        tripwire_triggered=result.final_output.is_math,
    )

agent = Agent( # (4)!
    name="Customer support agent",
    instructions="You are a customer support agent. You help customers with their questions.",
    output_guardrails=[math_guardrail],
    output_type=MessageOutput,
)

async def main():
    # This should trip the guardrail
    try:
        await Runner.run(agent, "Hello, can you help me solve for x: 2x + 3 = 11?")
        print("Guardrail didn't trip - this is unexpected")

    except OutputGuardrailTripwireTriggered:
        print("Math output guardrail tripped")
```

1. 这是实际智能体的输出类型。
2. 这是安全防护措施的输出类型。
3. 这是安全防护函数，它接收智能体的输出，并返回结果。
4. 这是真正定义工作流的智能体。

最后，这里是工具安全防护措施的示例。

```python
import json
from agents import (
    Agent,
    Runner,
    ToolGuardrailFunctionOutput,
    function_tool,
    tool_input_guardrail,
    tool_output_guardrail,
)

@tool_input_guardrail
def block_secrets(data):
    args = json.loads(data.context.tool_arguments or "{}")
    if "sk-" in json.dumps(args):
        return ToolGuardrailFunctionOutput.reject_content(
            "Remove secrets before calling this tool."
        )
    return ToolGuardrailFunctionOutput.allow()


@tool_output_guardrail
def redact_output(data):
    text = str(data.output or "")
    if "sk-" in text:
        return ToolGuardrailFunctionOutput.reject_content("Output contained sensitive data.")
    return ToolGuardrailFunctionOutput.allow()


@function_tool(
    tool_input_guardrails=[block_secrets],
    tool_output_guardrails=[redact_output],
)
def classify_text(text: str) -> str:
    """Classify text for internal routing."""
    return f"length:{len(text)}"


agent = Agent(name="Classifier", tools=[classify_text])
result = Runner.run_sync(agent, "hello world")
print(result.final_output)
```

================
File: docs/zh/handoffs.md
================
---
search:
  exclude: true
---
# 任务转移

任务转移允许一个智能体将任务委派给另一个智能体。这在不同智能体专注于不同领域的场景中特别有用。例如，一个客户支持应用可能会有多个智能体，分别专门处理订单状态、退款、常见问题等任务。

任务转移会作为工具呈现给 LLM。因此，如果有一个转移目标是名为 `Refund Agent` 的智能体，那么该工具名称会是 `transfer_to_refund_agent`。

## 创建任务转移

所有智能体都有一个 [`handoffs`][agents.agent.Agent.handoffs] 参数，它既可以直接接收一个 `Agent`，也可以接收一个用于自定义任务转移的 `Handoff` 对象。

如果你传入普通的 `Agent` 实例，它们的 [`handoff_description`][agents.agent.Agent.handoff_description]（设置时）会附加到默认工具描述中。你可以用它提示模型何时应选择该任务转移，而无需编写完整的 `handoff()` 对象。

你可以使用 Agents SDK 提供的 [`handoff()`][agents.handoffs.handoff] 函数创建任务转移。该函数允许你指定要转移到的智能体，以及可选的覆盖项和输入过滤器。

### 基本用法

下面是创建一个简单任务转移的方法：

```python
from agents import Agent, handoff

billing_agent = Agent(name="Billing agent")
refund_agent = Agent(name="Refund agent")

# (1)!
triage_agent = Agent(name="Triage agent", handoffs=[billing_agent, handoff(refund_agent)])
```

1. 你可以直接使用智能体（如 `billing_agent`），也可以使用 `handoff()` 函数。

### 通过 `handoff()` 函数自定义任务转移

[`handoff()`][agents.handoffs.handoff] 函数允许你自定义配置。

-   `agent`：这是要将任务转移到的智能体。
-   `tool_name_override`：默认使用 `Handoff.default_tool_name()` 函数，结果为 `transfer_to_<agent_name>`。你可以覆盖它。
-   `tool_description_override`：覆盖 `Handoff.default_tool_description()` 的默认工具描述
-   `on_handoff`：在任务转移被调用时执行的回调函数。这对于在你确认任务转移将被调用后立即触发数据获取等场景很有用。该函数会接收智能体上下文，并且也可以选择接收由 LLM 生成的输入。输入数据由 `input_type` 参数控制。
-   `input_type`：任务转移工具调用参数的 schema。设置后，解析后的负载会传递给 `on_handoff`。
-   `input_filter`：允许你过滤下一个智能体接收到的输入。详见下文。
-   `is_enabled`：任务转移是否启用。可以是布尔值，也可以是返回布尔值的函数，从而允许你在运行时动态启用或禁用任务转移。
-   `nest_handoff_history`：对 RunConfig 级别 `nest_handoff_history` 设置的可选单次调用覆盖项。如果为 `None`，则改用当前运行配置中定义的值。

[`handoff()`][agents.handoffs.handoff] 辅助函数始终将控制权转移到你传入的特定 `agent`。如果你有多个可能的目标，请为每个目标注册一个任务转移，并让模型在它们之间选择。仅当你自己的任务转移代码必须在调用时决定返回哪个智能体时，才使用自定义 [`Handoff`][agents.handoffs.Handoff]。

```python
from agents import Agent, handoff, RunContextWrapper

def on_handoff(ctx: RunContextWrapper[None]):
    print("Handoff called")

agent = Agent(name="My agent")

handoff_obj = handoff(
    agent=agent,
    on_handoff=on_handoff,
    tool_name_override="custom_handoff_tool",
    tool_description_override="Custom description",
)
```

## 任务转移输入

在某些情况下，你会希望 LLM 在调用任务转移时提供一些数据。例如，设想有一个到“升级处理智能体”的任务转移。你可能希望提供原因，以便记录日志。

```python
from pydantic import BaseModel

from agents import Agent, handoff, RunContextWrapper

class EscalationData(BaseModel):
    reason: str

async def on_handoff(ctx: RunContextWrapper[None], input_data: EscalationData):
    print(f"Escalation agent called with reason: {input_data.reason}")

agent = Agent(name="Escalation agent")

handoff_obj = handoff(
    agent=agent,
    on_handoff=on_handoff,
    input_type=EscalationData,
)
```

`input_type` 描述的是任务转移工具调用本身的参数。SDK 会将该 schema 作为任务转移工具的 `parameters` 暴露给模型，在本地校验返回的 JSON，并将解析后的值传递给 `on_handoff`。

它不会替代下一个智能体的主输入，也不会选择不同的目标。[`handoff()`][agents.handoffs.handoff] 辅助函数仍会转移到你封装的特定智能体，接收方智能体仍会看到对话历史，除非你通过 [`input_filter`][agents.handoffs.Handoff.input_filter] 或嵌套任务转移历史设置进行更改。

`input_type` 也独立于 [`RunContextWrapper.context`][agents.run_context.RunContextWrapper.context]。`input_type` 适用于模型在任务转移时决定的元数据，而不是你本地已存在的应用状态或依赖项。

### 何时使用 `input_type`

当任务转移需要一小段由模型生成的元数据（如 `reason`、`language`、`priority` 或 `summary`）时，使用 `input_type`。例如，分流智能体可以将任务转移给退款智能体并附带 `{ "reason": "duplicate_charge", "priority": "high" }`，而 `on_handoff` 可以在退款智能体接管前记录或持久化该元数据。

当目标不同，请选择其他机制：

-   将现有应用状态和依赖项放入 [`RunContextWrapper.context`][agents.run_context.RunContextWrapper.context]。参见[上下文指南](context.md)。
-   如果你想更改接收方智能体能看到的历史，使用 [`input_filter`][agents.handoffs.Handoff.input_filter]、[`RunConfig.nest_handoff_history`][agents.run.RunConfig.nest_handoff_history] 或 [`RunConfig.handoff_history_mapper`][agents.run.RunConfig.handoff_history_mapper]。
-   如果存在多个可能的专家目标，为每个目标注册一个任务转移。`input_type` 可以为已选任务转移添加元数据，但不会在目标之间分发。
-   如果你想为嵌套专家提供 structured outputs 输入而不转移对话，优先使用 [`Agent.as_tool(parameters=...)`][agents.agent.Agent.as_tool]。参见 [tools](tools.md#structured-input-for-tool-agents)。

## 输入过滤器

当发生任务转移时，就好像新智能体接管了对话，并能看到此前完整的对话历史。如果你想改变这一点，可以设置 [`input_filter`][agents.handoffs.Handoff.input_filter]。输入过滤器是一个函数，它通过 [`HandoffInputData`][agents.handoffs.HandoffInputData] 接收现有输入，并且必须返回一个新的 `HandoffInputData`。

[`HandoffInputData`][agents.handoffs.HandoffInputData] 包含：

-   `input_history`：`Runner.run(...)` 开始前的输入历史。
-   `pre_handoff_items`：调用任务转移的智能体轮次之前生成的条目。
-   `new_items`：当前轮次中生成的条目，包括任务转移调用和任务转移输出条目。
-   `input_items`：可选项；可转发给下一个智能体以替代 `new_items`，从而在保留用于会话历史的 `new_items` 不变的同时过滤模型输入。
-   `run_context`：调用任务转移时处于激活状态的 [`RunContextWrapper`][agents.run_context.RunContextWrapper]。

嵌套任务转移作为可选启用的 beta 功能提供，默认关闭，直到我们将其稳定化。启用 [`RunConfig.nest_handoff_history`][agents.run.RunConfig.nest_handoff_history] 后，runner 会将先前的对话记录折叠为一条 assistant 摘要消息，并将其包装在 `<CONVERSATION HISTORY>` 块中；当同一次运行中发生多次任务转移时，该块会持续追加新轮次。你可以通过 [`RunConfig.handoff_history_mapper`][agents.run.RunConfig.handoff_history_mapper] 提供自己的映射函数来替换自动生成的消息，而无需编写完整的 `input_filter`。仅当任务转移和运行都未提供显式 `input_filter` 时，此可选启用才会生效，因此已自定义负载的现有代码（包括本仓库中的代码示例）无需变更即可保持当前行为。你可以在 [`handoff(...)`][agents.handoffs.handoff] 中传入 `nest_handoff_history=True` 或 `False` 来覆盖单次任务转移的嵌套行为，这会设置 [`Handoff.nest_handoff_history`][agents.handoffs.Handoff.nest_handoff_history]。如果你只需要修改生成摘要的包装文本，请在运行智能体前调用 [`set_conversation_history_wrappers`][agents.handoffs.set_conversation_history_wrappers]（以及可选的 [`reset_conversation_history_wrappers`][agents.handoffs.reset_conversation_history_wrappers]）。

如果任务转移和当前激活的 [`RunConfig.handoff_input_filter`][agents.run.RunConfig.handoff_input_filter] 都定义了过滤器，则该特定任务转移的每任务转移 [`input_filter`][agents.handoffs.Handoff.input_filter] 优先。

!!! note

    任务转移会保持在单次运行内。输入安全防护措施仍仅适用于链路中的第一个智能体，输出安全防护措施仅适用于产生最终输出的智能体。当你需要在工作流中每次自定义工具调用周围进行检查时，请使用工具安全防护措施。

有一些常见模式（例如从历史中移除所有工具调用）已在 [`agents.extensions.handoff_filters`][] 中为你实现。

```python
from agents import Agent, handoff
from agents.extensions import handoff_filters

agent = Agent(name="FAQ agent")

handoff_obj = handoff(
    agent=agent,
    input_filter=handoff_filters.remove_all_tools, # (1)!
)
```

1. 当调用 `FAQ agent` 时，这会自动从历史中移除所有工具。

## 推荐提示词

为了确保 LLM 正确理解任务转移，我们建议在你的智能体中包含任务转移相关信息。我们在 [`agents.extensions.handoff_prompt.RECOMMENDED_PROMPT_PREFIX`][] 中提供了建议前缀，或者你可以调用 [`agents.extensions.handoff_prompt.prompt_with_handoff_instructions`][]，将推荐内容自动添加到你的提示词中。

```python
from agents import Agent
from agents.extensions.handoff_prompt import RECOMMENDED_PROMPT_PREFIX

billing_agent = Agent(
    name="Billing agent",
    instructions=f"""{RECOMMENDED_PROMPT_PREFIX}
    <Fill in the rest of your prompt here>.""",
)
```

================
File: docs/zh/human_in_the_loop.md
================
---
search:
  exclude: true
---
# 人工参与

使用人工参与（HITL）流程，在人员批准或拒绝敏感工具调用之前暂停智能体执行。工具会声明何时需要批准，运行结果会将待处理批准显示为中断，`RunState` 则允许你在决策完成后序列化并恢复运行。

该批准界面是针对整个运行的，而不仅限于当前顶层智能体。无论工具属于当前智能体、属于通过任务转移到达的智能体，还是属于嵌套的 [`Agent.as_tool()`][agents.agent.Agent.as_tool] 执行，模式都相同。在嵌套 `Agent.as_tool()` 的情况下，中断仍会显示在外层运行上，因此你需要在外层 `RunState` 上批准或拒绝它，并恢复原始顶层运行。

对于 `Agent.as_tool()`，批准可能发生在两个不同层级：智能体工具本身可通过 `Agent.as_tool(..., needs_approval=...)` 要求批准；嵌套智能体内部的工具也可在嵌套运行开始后触发其自身批准请求。这两者都通过同一个外层运行中断流程处理。

本页重点介绍通过 `interruptions` 的手动批准流程。如果你的应用可以在代码中做出决策，某些工具类型也支持编程式批准回调，从而让运行无需暂停即可继续。

## 标记需要批准的工具

将 `needs_approval` 设为 `True` 可始终要求批准，或提供一个异步函数按每次调用决定。该可调用对象接收运行上下文、解析后的工具参数以及工具调用 ID。

```python
from agents import Agent, Runner, function_tool


@function_tool(needs_approval=True)
async def cancel_order(order_id: int) -> str:
    return f"Cancelled order {order_id}"


async def requires_review(_ctx, params, _call_id) -> bool:
    return "refund" in params.get("subject", "").lower()


@function_tool(needs_approval=requires_review)
async def send_email(subject: str, body: str) -> str:
    return f"Sent '{subject}'"


agent = Agent(
    name="Support agent",
    instructions="Handle tickets and ask for approval when needed.",
    tools=[cancel_order, send_email],
)
```

`needs_approval` 可用于 [`function_tool`][agents.tool.function_tool]、[`Agent.as_tool`][agents.agent.Agent.as_tool]、[`ShellTool`][agents.tool.ShellTool] 和 [`ApplyPatchTool`][agents.tool.ApplyPatchTool]。本地 MCP 服务也支持通过 [`MCPServerStdio`][agents.mcp.server.MCPServerStdio]、[`MCPServerSse`][agents.mcp.server.MCPServerSse] 和 [`MCPServerStreamableHttp`][agents.mcp.server.MCPServerStreamableHttp] 上的 `require_approval` 进行批准控制。托管 MCP 服务通过带有 `tool_config={"require_approval": "always"}` 的 [`HostedMCPTool`][agents.tool.HostedMCPTool] 支持批准，并可选提供 `on_approval_request` 回调。Shell 和 apply_patch 工具接受 `on_approval` 回调，如果你希望在不显示中断的情况下自动批准或自动拒绝。

## 批准流程机制

1. 当模型发出工具调用时，runner 会评估其批准规则（`needs_approval`、`require_approval` 或托管 MCP 对应配置）。
2. 如果该工具调用的批准决策已存储在 [`RunContextWrapper`][agents.run_context.RunContextWrapper] 中，runner 将无需提示直接继续。按调用的批准仅作用于特定调用 ID；传入 `always_approve=True` 或 `always_reject=True` 可将同一决策持久化，用于本次运行剩余期间对该工具的后续调用。
3. 否则，执行会暂停，且 `RunResult.interruptions`（或 `RunResultStreaming.interruptions`）将包含 [`ToolApprovalItem`][agents.items.ToolApprovalItem] 条目，含有如 `agent.name`、`tool_name` 和 `arguments` 等详细信息。这也包括任务转移后或嵌套 `Agent.as_tool()` 执行内部触发的批准请求。
4. 将结果转换为 `RunState`（`result.to_state()`），调用 `state.approve(...)` 或 `state.reject(...)`，然后通过 `Runner.run(agent, state)` 或 `Runner.run_streamed(agent, state)` 恢复，其中 `agent` 是该运行原始顶层智能体。
5. 恢复后的运行会从中断处继续；若出现新的批准需求，将再次进入此流程。

通过 `always_approve=True` 或 `always_reject=True` 创建的粘性决策会存储在运行状态中，因此在你稍后恢复同一暂停运行时，它们会在 `state.to_string()` / `RunState.from_string(...)` 和 `state.to_json()` / `RunState.from_json(...)` 之间保留。

你无需在同一次处理中解决所有待处理批准。`interruptions` 可同时包含常规工具调用、托管 MCP 批准以及嵌套 `Agent.as_tool()` 批准。如果你在仅批准或拒绝部分条目后重新运行，已处理的调用可继续执行，而未处理项会继续留在 `interruptions` 中并再次暂停运行。

## 自动批准决策

手动 `interruptions` 是最通用模式，但不是唯一方式：

-   本地 [`ShellTool`][agents.tool.ShellTool] 和 [`ApplyPatchTool`][agents.tool.ApplyPatchTool] 可使用 `on_approval` 在代码中立即批准或拒绝。
-   [`HostedMCPTool`][agents.tool.HostedMCPTool] 可使用 `tool_config={"require_approval": "always"}` 配合 `on_approval_request` 实现同类编程式决策。
-   普通 [`function_tool`][agents.tool.function_tool] 工具和 [`Agent.as_tool()`][agents.agent.Agent.as_tool] 使用本页所述手动中断流程。

当这些回调返回决策后，运行会继续，无需暂停等待人工响应。对于 Realtime 和语音会话 API，请参阅 [Realtime 指南](realtime/guide.md) 中的批准流程。

## 流式传输与会话

同一中断流程也适用于流式运行。流式运行暂停后，继续消费 [`RunResultStreaming.stream_events()`][agents.result.RunResultStreaming.stream_events]，直到迭代器结束；检查 [`RunResultStreaming.interruptions`][agents.result.RunResultStreaming.interruptions]；完成处理后，如需让恢复后的输出继续流式传输，请使用 [`Runner.run_streamed(...)`][agents.run.Runner.run_streamed] 恢复。该模式的流式版本见 [流式传输](streaming.md)。

如果你还在使用会话，从 `RunState` 恢复时请持续传入同一个会话实例，或传入另一个指向同一底层存储的会话对象。恢复后的轮次会追加到同一已存储对话历史中。会话生命周期细节见 [会话](sessions/index.md)。

## 示例：暂停、批准、恢复

下面的代码片段与 JavaScript HITL 指南一致：当工具需要批准时暂停，将状态持久化到磁盘，重新加载，并在收集决策后恢复。

```python
import asyncio
import json
from pathlib import Path

from agents import Agent, Runner, RunState, function_tool


async def needs_oakland_approval(_ctx, params, _call_id) -> bool:
    return "Oakland" in params.get("city", "")


@function_tool(needs_approval=needs_oakland_approval)
async def get_temperature(city: str) -> str:
    return f"The temperature in {city} is 20° Celsius"


agent = Agent(
    name="Weather assistant",
    instructions="Answer weather questions with the provided tools.",
    tools=[get_temperature],
)

STATE_PATH = Path(".cache/hitl_state.json")


def prompt_approval(tool_name: str, arguments: str | None) -> bool:
    answer = input(f"Approve {tool_name} with {arguments}? [y/N]: ").strip().lower()
    return answer in {"y", "yes"}


async def main() -> None:
    result = await Runner.run(agent, "What is the temperature in Oakland?")

    while result.interruptions:
        # Persist the paused state.
        state = result.to_state()
        STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
        STATE_PATH.write_text(state.to_string())

        # Load the state later (could be a different process).
        stored = json.loads(STATE_PATH.read_text())
        state = await RunState.from_json(agent, stored)

        for interruption in result.interruptions:
            approved = await asyncio.get_running_loop().run_in_executor(
                None, prompt_approval, interruption.name or "unknown_tool", interruption.arguments
            )
            if approved:
                state.approve(interruption, always_approve=False)
            else:
                state.reject(interruption)

        result = await Runner.run(agent, state)

    print(result.final_output)


if __name__ == "__main__":
    asyncio.run(main())
```

在此示例中，`prompt_approval` 是同步函数，因为它使用 `input()` 并通过 `run_in_executor(...)` 执行。如果你的批准来源本身已是异步的（例如 HTTP 请求或异步数据库查询），可改用 `async def` 函数并直接 `await`。

若要在等待批准时流式输出，请调用 `Runner.run_streamed`，消费 `result.stream_events()` 直到完成，然后按上文相同方式执行 `result.to_state()` 和恢复步骤。

## 仓库模式与代码示例

- **流式传输批准**：`examples/agent_patterns/human_in_the_loop_stream.py` 展示了如何清空 `stream_events()`，然后在使用 `Runner.run_streamed(agent, state)` 恢复前批准待处理工具调用。
- **智能体作为工具的批准**：`Agent.as_tool(..., needs_approval=...)` 在被委托的智能体任务需要审查时应用同样的中断流程。嵌套中断仍显示在外层运行上，因此应恢复原始顶层智能体，而不是嵌套智能体。
- **本地 shell 与 apply_patch 工具**：`ShellTool` 和 `ApplyPatchTool` 也支持 `needs_approval`。使用 `state.approve(interruption, always_approve=True)` 或 `state.reject(..., always_reject=True)` 可为后续调用缓存决策。自动决策可提供 `on_approval`（见 `examples/tools/shell.py`）；手动决策可处理中断（见 `examples/tools/shell_human_in_the_loop.py`）。托管 shell 环境不支持 `needs_approval` 或 `on_approval`；见[工具指南](tools.md)。
- **本地 MCP 服务**：在 `MCPServerStdio` / `MCPServerSse` / `MCPServerStreamableHttp` 上使用 `require_approval` 以控制 MCP 工具调用（见 `examples/mcp/get_all_mcp_tools_example/main.py` 和 `examples/mcp/tool_filter_example/main.py`）。
- **托管 MCP 服务**：在 `HostedMCPTool` 上将 `require_approval` 设为 `"always"` 可强制 HITL，并可选提供 `on_approval_request` 以自动批准或拒绝（见 `examples/hosted_mcp/human_in_the_loop.py` 和 `examples/hosted_mcp/on_approval.py`）。对可信服务可使用 `"never"`（`examples/hosted_mcp/simple.py`）。
- **会话与记忆**：向 `Runner.run` 传入会话，使批准与对话历史跨多个轮次保留。SQLite 和 OpenAI Conversations 会话变体位于 `examples/memory/memory_session_hitl_example.py` 和 `examples/memory/openai_session_hitl_example.py`。
- **Realtime 智能体**：realtime 演示通过 WebSocket 消息在 `RealtimeSession` 上调用 `approve_tool_call` / `reject_tool_call` 来批准或拒绝工具调用（服务端处理器见 `examples/realtime/app/server.py`，API 说明见 [Realtime 指南](realtime/guide.md#tool-approvals)）。

## 长时批准

`RunState` 设计为可持久化。使用 `state.to_json()` 或 `state.to_string()` 将待处理工作存储到数据库或队列，并在之后通过 `RunState.from_json(...)` 或 `RunState.from_string(...)` 重新创建。

有用的序列化选项：

-   `context_serializer`：自定义如何序列化非映射的上下文对象。
-   `context_deserializer`：在使用 `RunState.from_json(...)` 或 `RunState.from_string(...)` 加载状态时重建非映射上下文对象。
-   `strict_context=True`：除非上下文本身已是映射类型，或你提供了相应的 serializer/deserializer，否则序列化或反序列化会失败。
-   `context_override`：加载状态时替换已序列化上下文。当你不想恢复原始上下文对象时很有用，但它不会从已序列化负载中移除该上下文。
-   `include_tracing_api_key=True`：当你需要恢复后的工作继续使用相同凭据导出追踪数据时，在序列化的追踪负载中包含 tracing API key。

序列化后的运行状态包含你的应用上下文，以及由 SDK 管理的运行时元数据，例如批准信息、用量、序列化后的 `tool_input`、嵌套 agent-as-tool 恢复、追踪元数据和服务端管理的会话设置。如果你计划存储或传输序列化状态，请将 `RunContextWrapper.context` 视为持久化数据，并避免在其中放置秘密信息，除非你有意让其随状态一同传递。

## 待处理任务版本管理

如果批准请求可能会搁置一段时间，请将你的智能体定义或 SDK 版本标记与序列化状态一并存储。这样在模型、提示词或工具定义发生变化时，你就可以将反序列化路由到匹配的代码路径，以避免不兼容问题。

================
File: docs/zh/index.md
================
---
search:
  exclude: true
---
# OpenAI Agents SDK

[OpenAI Agents SDK](https://github.com/openai/openai-agents-python) 让你能够以一个轻量、易用且抽象极少的软件包构建智能体式 AI 应用。它是我们此前用于智能体实验项目 [Swarm](https://github.com/openai/swarm/tree/main) 的生产级升级版本。Agents SDK 拥有一组非常小的基本组件：

-   **智能体**，即配备了指令和工具的 LLM
-   **Agents as tools / 任务转移**，允许智能体将特定任务委派给其他智能体
-   **安全防护措施**，可对智能体输入和输出进行验证

结合 Python，这些基本组件足以表达工具与智能体之间的复杂关系，并让你无需陡峭的学习曲线即可构建真实世界应用。此外，SDK 内置了**追踪**功能，可让你可视化并调试智能体流程，还能对其进行评估，甚至为你的应用微调模型。

## 使用 Agents SDK 的原因

SDK 有两个核心设计原则：

1. 功能足够丰富，值得使用；但基本组件足够少，学习速度快。
2. 开箱即用效果出色，同时你也可以精确自定义每一步行为。

以下是 SDK 的主要特性：

-   **智能体循环**：内置智能体循环，可处理工具调用、将结果回传给 LLM，并持续执行直到任务完成。
-   **Python 优先**：使用内置语言特性进行智能体编排与链式调用，而无需学习新的抽象概念。
-   **Agents as tools / 任务转移**：用于在多个智能体之间协调与委派工作的强大机制。
-   **安全防护措施**：与智能体执行并行运行输入验证和安全检查，并在检查未通过时快速失败。
-   **工具调用**：将任意 Python 函数转换为工具，并自动生成 schema 与基于 Pydantic 的验证。
-   **MCP 服务工具调用**：内置 MCP 服务工具集成，使用方式与工具调用相同。
-   **会话**：用于在智能体循环中维护工作上下文的持久化记忆层。
-   **人在回路**：内置机制，可在人机协作中跨智能体运行引入人工参与。
-   **追踪**：内置追踪能力，用于工作流可视化、调试与监控，并支持 OpenAI 全套评估、微调与蒸馏工具。
-   **实时智能体**：构建强大的语音智能体，支持自动打断检测、上下文管理、安全防护措施等功能。

## 安装

```bash
pip install openai-agents
```

## Hello World 示例

```python
from agents import Agent, Runner

agent = Agent(name="Assistant", instructions="You are a helpful assistant")

result = Runner.run_sync(agent, "Write a haiku about recursion in programming.")
print(result.final_output)

# Code within the code,
# Functions calling themselves,
# Infinite loop's dance.
```

（_如果要运行此示例，请确保已设置 `OPENAI_API_KEY` 环境变量_）

```bash
export OPENAI_API_KEY=sk-...
```

## 从这里开始

-   通过 [Quickstart](quickstart.md) 构建你的第一个基于文本的智能体。
-   然后在 [运行智能体](running_agents.md#choose-a-memory-strategy) 中决定如何在多轮之间保持状态。
-   如果你在任务转移与管理器式编排之间做选择，请阅读 [智能体编排](multi_agent.md)。

## 路径选择

当你知道要完成的工作、但不确定该看哪一页说明时，请使用下表。

| 目标 | 从这里开始 |
| --- | --- |
| 构建第一个文本智能体并查看一次完整运行 | [Quickstart](quickstart.md) |
| 添加工具调用、托管工具或 Agents as tools | [工具](tools.md) |
| 在任务转移与管理器式编排之间做选择 | [智能体编排](multi_agent.md) |
| 在多轮之间保留记忆 | [运行智能体](running_agents.md#choose-a-memory-strategy) 和 [会话](sessions/index.md) |
| 使用 OpenAI 模型、websocket 传输或非 OpenAI 提供方 | [模型](models/index.md) |
| 查看输出、运行项、中断与恢复状态 | [结果](results.md) |
| 构建低延迟语音智能体 | [实时智能体快速开始](realtime/quickstart.md) 和 [实时传输](realtime/transport.md) |
| 构建语音转文本 / 智能体 / 文本转语音流水线 | [语音流水线快速开始](voice/quickstart.md) |

================
File: docs/zh/mcp.md
================
---
search:
  exclude: true
---
# Model context protocol (MCP)

[Model context protocol](https://modelcontextprotocol.io/introduction)（MCP）标准化了应用向语言模型暴露工具和上下文的方式。来自官方文档：

> MCP 是一种开放协议，用于标准化应用如何向 LLM 提供上下文。可以将 MCP 视为 AI 应用的 USB-C 端口。正如 USB-C 提供了一种将设备连接到各种外设和配件的标准化方式，MCP 也提供了一种将 AI 模型连接到不同数据源和工具的标准化方式。

Agents Python SDK 支持多种 MCP 传输方式。这使你可以复用现有的 MCP 服务，或构建自己的服务，以向智能体暴露基于文件系统、HTTP 或连接器的工具。

## MCP 集成选择

在将 MCP 服务接入智能体之前，请先确定工具调用应在何处执行，以及你可访问哪些传输方式。下表汇总了 Python SDK 支持的选项。

| 你的需求 | 推荐选项 |
| ------------------------------------------------------------------------------------ | ----------------------------------------------------- |
| 让 OpenAI 的 Responses API 代表模型调用一个可公开访问的 MCP 服务| 通过 [`HostedMCPTool`][agents.tool.HostedMCPTool] 使用**托管 MCP 服务工具** |
| 连接你在本地或远程运行的 Streamable HTTP 服务 | 通过 [`MCPServerStreamableHttp`][agents.mcp.server.MCPServerStreamableHttp] 使用**Streamable HTTP MCP 服务** |
| 与实现了带 Server-Sent Events 的 HTTP 的服务通信 | 通过 [`MCPServerSse`][agents.mcp.server.MCPServerSse] 使用**带 SSE 的 HTTP MCP 服务** |
| 启动本地进程并通过 stdin/stdout 通信 | 通过 [`MCPServerStdio`][agents.mcp.server.MCPServerStdio] 使用**stdio MCP 服务** |

下文将逐一介绍每个选项、如何配置，以及何时优先选择某种传输方式。

## 智能体级 MCP 配置

除选择传输方式外，你还可以通过设置 `Agent.mcp_config` 来调整 MCP 工具的准备方式。

```python
from agents import Agent

agent = Agent(
    name="Assistant",
    mcp_servers=[server],
    mcp_config={
        # Try to convert MCP tool schemas to strict JSON schema.
        "convert_schemas_to_strict": True,
        # If None, MCP tool failures are raised as exceptions instead of
        # returning model-visible error text.
        "failure_error_function": None,
    },
)
```

说明：

- `convert_schemas_to_strict` 为尽力而为。如果某个 schema 无法转换，则使用原始 schema。
- `failure_error_function` 控制如何将 MCP 工具调用失败信息暴露给模型。
- 当未设置 `failure_error_function` 时，SDK 使用默认的工具错误格式化器。
- 服务级 `failure_error_function` 会覆盖该服务的 `Agent.mcp_config["failure_error_function"]`。

## 跨传输方式的通用模式

选择传输方式后，大多数集成都需要做出相同的后续决策：

- 如何仅暴露部分工具（[工具过滤](#tool-filtering)）。
- 服务是否也提供可复用的提示词（[Prompts](#prompts)）。
- 是否应缓存 `list_tools()`（[缓存](#caching)）。
- MCP 活动如何显示在追踪中（[追踪](#tracing)）。

对于本地 MCP 服务（`MCPServerStdio`、`MCPServerSse`、`MCPServerStreamableHttp`），审批策略和每次调用的 `_meta` 负载也是通用概念。Streamable HTTP 部分展示了最完整的示例，同样的模式也适用于其他本地传输方式。

## 1. 托管 MCP 服务工具

托管工具将整个工具往返流程交由 OpenAI 基础设施处理。你的代码无需列出和调用工具，[`HostedMCPTool`][agents.tool.HostedMCPTool] 会将服务标签（及可选连接器元数据）转发给 Responses API。模型会列出远程服务的工具并调用它们，而无需额外回调你的 Python 进程。托管工具目前适用于支持 Responses API 托管 MCP 集成的 OpenAI 模型。

### 基础托管 MCP 工具

通过将 [`HostedMCPTool`][agents.tool.HostedMCPTool] 添加到智能体的 `tools` 列表来创建托管工具。`tool_config` 字典与发送到 REST API 的 JSON 对应：

```python
import asyncio

from agents import Agent, HostedMCPTool, Runner

async def main() -> None:
    agent = Agent(
        name="Assistant",
        tools=[
            HostedMCPTool(
                tool_config={
                    "type": "mcp",
                    "server_label": "gitmcp",
                    "server_url": "https://gitmcp.io/openai/codex",
                    "require_approval": "never",
                }
            )
        ],
    )

    result = await Runner.run(agent, "Which language is this repository written in?")
    print(result.final_output)

asyncio.run(main())
```

托管服务会自动暴露其工具；你无需将其添加到 `mcp_servers`。

### 托管 MCP 结果的流式传输

托管工具以与工具调用完全相同的方式支持流式结果。使用 `Runner.run_streamed` 可在模型仍在处理时消费增量 MCP 输出：

```python
result = Runner.run_streamed(agent, "Summarise this repository's top languages")
async for event in result.stream_events():
    if event.type == "run_item_stream_event":
        print(f"Received: {event.item}")
print(result.final_output)
```

### 可选审批流程

如果服务可执行敏感操作，你可以要求在每次工具执行前进行人工或程序化审批。在 `tool_config` 中配置 `require_approval`，可使用单一策略（`"always"`、`"never"`）或将工具名映射到策略的字典。若要在 Python 内做决策，请提供 `on_approval_request` 回调。

```python
from agents import MCPToolApprovalFunctionResult, MCPToolApprovalRequest

SAFE_TOOLS = {"read_project_metadata"}

def approve_tool(request: MCPToolApprovalRequest) -> MCPToolApprovalFunctionResult:
    if request.data.name in SAFE_TOOLS:
        return {"approve": True}
    return {"approve": False, "reason": "Escalate to a human reviewer"}

agent = Agent(
    name="Assistant",
    tools=[
        HostedMCPTool(
            tool_config={
                "type": "mcp",
                "server_label": "gitmcp",
                "server_url": "https://gitmcp.io/openai/codex",
                "require_approval": "always",
            },
            on_approval_request=approve_tool,
        )
    ],
)
```

该回调可为同步或异步；当模型需要审批数据以继续运行时会被调用。

### 基于连接器的托管服务

托管 MCP 也支持 OpenAI 连接器。无需指定 `server_url`，改为提供 `connector_id` 和访问令牌。Responses API 会处理认证，托管服务会暴露该连接器的工具。

```python
import os

HostedMCPTool(
    tool_config={
        "type": "mcp",
        "server_label": "google_calendar",
        "connector_id": "connector_googlecalendar",
        "authorization": os.environ["GOOGLE_CALENDAR_AUTHORIZATION"],
        "require_approval": "never",
    }
)
```

完整可运行的托管工具示例（包括流式传输、审批与连接器）位于
[`examples/hosted_mcp`](https://github.com/openai/openai-agents-python/tree/main/examples/hosted_mcp)。

## 2. Streamable HTTP MCP 服务

当你希望自行管理网络连接时，请使用
[`MCPServerStreamableHttp`][agents.mcp.server.MCPServerStreamableHttp]。当你控制传输层，或希望在自有基础设施中运行服务并保持低延迟时，Streamable HTTP 服务是理想选择。

```python
import asyncio
import os

from agents import Agent, Runner
from agents.mcp import MCPServerStreamableHttp
from agents.model_settings import ModelSettings

async def main() -> None:
    token = os.environ["MCP_SERVER_TOKEN"]
    async with MCPServerStreamableHttp(
        name="Streamable HTTP Python Server",
        params={
            "url": "http://localhost:8000/mcp",
            "headers": {"Authorization": f"Bearer {token}"},
            "timeout": 10,
        },
        cache_tools_list=True,
        max_retry_attempts=3,
    ) as server:
        agent = Agent(
            name="Assistant",
            instructions="Use the MCP tools to answer the questions.",
            mcp_servers=[server],
            model_settings=ModelSettings(tool_choice="required"),
        )

        result = await Runner.run(agent, "Add 7 and 22.")
        print(result.final_output)

asyncio.run(main())
```

构造函数接受以下附加选项：

- `client_session_timeout_seconds` 控制 HTTP 读取超时。
- `use_structured_content` 控制是否优先使用 `tool_result.structured_content` 而非文本输出。
- `max_retry_attempts` 和 `retry_backoff_seconds_base` 为 `list_tools()` 与 `call_tool()` 增加自动重试。
- `tool_filter` 允许你仅暴露部分工具（见[工具过滤](#tool-filtering)）。
- `require_approval` 在本地 MCP 工具上启用人类参与审批策略。
- `failure_error_function` 自定义模型可见的 MCP 工具失败消息；将其设为 `None` 则改为抛出错误。
- `tool_meta_resolver` 在 `call_tool()` 之前注入每次调用的 MCP `_meta` 负载。

### 本地 MCP 服务的审批策略

`MCPServerStdio`、`MCPServerSse` 和 `MCPServerStreamableHttp` 都接受 `require_approval`。

支持形式：

- 对所有工具使用 `"always"` 或 `"never"`。
- `True` / `False`（等价于 always/never）。
- 按工具映射，例如 `{"delete_file": "always", "read_file": "never"}`。
- 分组对象：
  `{"always": {"tool_names": [...]}, "never": {"tool_names": [...]}}`。

```python
async with MCPServerStreamableHttp(
    name="Filesystem MCP",
    params={"url": "http://localhost:8000/mcp"},
    require_approval={"always": {"tool_names": ["delete_file"]}},
) as server:
    ...
```

完整的暂停/恢复流程，请参见[Human-in-the-loop](human_in_the_loop.md) 和 `examples/mcp/get_all_mcp_tools_example/main.py`。

### 使用 `tool_meta_resolver` 提供每次调用元数据

当你的 MCP 服务期望在 `_meta` 中接收请求元数据（例如租户 ID 或追踪上下文）时，请使用 `tool_meta_resolver`。以下示例假设你将 `dict` 作为 `context` 传入 `Runner.run(...)`。

```python
from agents.mcp import MCPServerStreamableHttp, MCPToolMetaContext


def resolve_meta(context: MCPToolMetaContext) -> dict[str, str] | None:
    run_context_data = context.run_context.context or {}
    tenant_id = run_context_data.get("tenant_id")
    if tenant_id is None:
        return None
    return {"tenant_id": str(tenant_id), "source": "agents-sdk"}


server = MCPServerStreamableHttp(
    name="Metadata-aware MCP",
    params={"url": "http://localhost:8000/mcp"},
    tool_meta_resolver=resolve_meta,
)
```

如果你的运行上下文是 Pydantic 模型、dataclass 或自定义类，请改用属性访问读取租户 ID。

### MCP 工具输出：文本与图像

当 MCP 工具返回图像内容时，SDK 会自动将其映射为图像工具输出条目。文本/图像混合响应会作为输出项列表转发，因此智能体可像消费常规工具调用的图像输出一样消费 MCP 图像结果。

## 3. 带 SSE 的 HTTP MCP 服务

!!! warning

    MCP 项目已弃用 Server-Sent Events 传输。新集成请优先使用 Streamable HTTP 或 stdio，仅在遗留服务中保留 SSE。

如果 MCP 服务实现了带 SSE 的 HTTP 传输，请实例化
[`MCPServerSse`][agents.mcp.server.MCPServerSse]。除传输方式外，其 API 与 Streamable HTTP 服务完全一致。

```python

from agents import Agent, Runner
from agents.model_settings import ModelSettings
from agents.mcp import MCPServerSse

workspace_id = "demo-workspace"

async with MCPServerSse(
    name="SSE Python Server",
    params={
        "url": "http://localhost:8000/sse",
        "headers": {"X-Workspace": workspace_id},
    },
    cache_tools_list=True,
) as server:
    agent = Agent(
        name="Assistant",
        mcp_servers=[server],
        model_settings=ModelSettings(tool_choice="required"),
    )
    result = await Runner.run(agent, "What's the weather in Tokyo?")
    print(result.final_output)
```

## 4. stdio MCP 服务

对于以本地子进程运行的 MCP 服务，请使用 [`MCPServerStdio`][agents.mcp.server.MCPServerStdio]。SDK 会启动该进程、保持管道打开，并在上下文管理器退出时自动关闭。该选项适合快速概念验证，或服务仅暴露命令行入口的场景。

```python
from pathlib import Path
from agents import Agent, Runner
from agents.mcp import MCPServerStdio

current_dir = Path(__file__).parent
samples_dir = current_dir / "sample_files"

async with MCPServerStdio(
    name="Filesystem Server via npx",
    params={
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-filesystem", str(samples_dir)],
    },
) as server:
    agent = Agent(
        name="Assistant",
        instructions="Use the files in the sample directory to answer questions.",
        mcp_servers=[server],
    )
    result = await Runner.run(agent, "List the files available to you.")
    print(result.final_output)
```

## 5. MCP 服务管理器

当你有多个 MCP 服务时，请使用 `MCPServerManager` 提前连接它们，并将已连接子集暴露给智能体。
构造参数和重连行为请参阅 [MCPServerManager API 参考](ref/mcp/manager.md)。

```python
from agents import Agent, Runner
from agents.mcp import MCPServerManager, MCPServerStreamableHttp

servers = [
    MCPServerStreamableHttp(name="calendar", params={"url": "http://localhost:8000/mcp"}),
    MCPServerStreamableHttp(name="docs", params={"url": "http://localhost:8001/mcp"}),
]

async with MCPServerManager(servers) as manager:
    agent = Agent(
        name="Assistant",
        instructions="Use MCP tools when they help.",
        mcp_servers=manager.active_servers,
    )
    result = await Runner.run(agent, "Which MCP tools are available?")
    print(result.final_output)
```

关键行为：

- 当 `drop_failed_servers=True`（默认）时，`active_servers` 仅包含成功连接的服务。
- 失败会记录在 `failed_servers` 和 `errors` 中。
- 设置 `strict=True` 可在首次连接失败时抛出异常。
- 调用 `reconnect(failed_only=True)` 可重试失败服务，或调用 `reconnect(failed_only=False)` 以重启所有服务。
- 使用 `connect_timeout_seconds`、`cleanup_timeout_seconds` 和 `connect_in_parallel` 调整生命周期行为。

## 常见服务能力

下文适用于各类 MCP 服务传输（具体 API 取决于服务类）。

## 工具过滤

每个 MCP 服务都支持工具过滤，使你仅暴露智能体所需功能。过滤可在构造时进行，也可在每次运行时动态进行。

### 静态工具过滤

使用 [`create_static_tool_filter`][agents.mcp.create_static_tool_filter] 配置简单的允许/阻止列表：

```python
from pathlib import Path

from agents.mcp import MCPServerStdio, create_static_tool_filter

samples_dir = Path("/path/to/files")

filesystem_server = MCPServerStdio(
    params={
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-filesystem", str(samples_dir)],
    },
    tool_filter=create_static_tool_filter(allowed_tool_names=["read_file", "write_file"]),
)
```

当同时提供 `allowed_tool_names` 与 `blocked_tool_names` 时，SDK 会先应用允许列表，再从剩余集合中移除被阻止工具。

### 动态工具过滤

对于更复杂逻辑，可传入一个接收 [`ToolFilterContext`][agents.mcp.ToolFilterContext] 的可调用对象。该可调用对象可为同步或异步，并在工具应被暴露时返回 `True`。

```python
from pathlib import Path

from agents.mcp import MCPServerStdio, ToolFilterContext

samples_dir = Path("/path/to/files")

async def context_aware_filter(context: ToolFilterContext, tool) -> bool:
    if context.agent.name == "Code Reviewer" and tool.name.startswith("danger_"):
        return False
    return True

async with MCPServerStdio(
    params={
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-filesystem", str(samples_dir)],
    },
    tool_filter=context_aware_filter,
) as server:
    ...
```

过滤上下文暴露当前 `run_context`、请求工具的 `agent` 以及 `server_name`。

## Prompts

MCP 服务还可提供动态生成智能体指令的提示词。支持提示词的服务会暴露两个方法：

- `list_prompts()` 枚举可用的提示词模板。
- `get_prompt(name, arguments)` 获取具体提示词，可选传入参数。

```python
from agents import Agent

prompt_result = await server.get_prompt(
    "generate_code_review_instructions",
    {"focus": "security vulnerabilities", "language": "python"},
)
instructions = prompt_result.messages[0].content.text

agent = Agent(
    name="Code Reviewer",
    instructions=instructions,
    mcp_servers=[server],
)
```

## 缓存

每次智能体运行都会在每个 MCP 服务上调用 `list_tools()`。远程服务可能引入明显延迟，因此所有 MCP 服务类都提供 `cache_tools_list` 选项。仅当你确信工具定义不会频繁变化时才将其设为 `True`。若后续要强制获取最新列表，请在服务实例上调用 `invalidate_tools_cache()`。

## 追踪

[追踪](./tracing.md)会自动捕获 MCP 活动，包括：

1. 调用 MCP 服务以列出工具。
2. 工具调用中的 MCP 相关信息。

![MCP Tracing Screenshot](../assets/images/mcp-tracing.jpg)

## 延伸阅读

- [Model Context Protocol](https://modelcontextprotocol.io/) – 规范与设计指南。
- [examples/mcp](https://github.com/openai/openai-agents-python/tree/main/examples/mcp) – 可运行的 stdio、SSE 与 Streamable HTTP 示例。
- [examples/hosted_mcp](https://github.com/openai/openai-agents-python/tree/main/examples/hosted_mcp) – 完整的托管 MCP 演示，包括审批与连接器。

================
File: docs/zh/multi_agent.md
================
---
search:
  exclude: true
---
# 智能体编排

编排是指你应用中智能体的流程。哪些智能体运行、按什么顺序运行，以及它们如何决定下一步发生什么？主要有两种智能体编排方式：

1. 让LLM做决策：利用LLM的智能进行规划、推理，并据此决定采取哪些步骤。
2. 通过代码编排：通过你的代码来确定智能体流程。

你可以混合使用这些模式。每种方式都有各自的权衡，详见下文。

## 通过LLM编排

智能体是配备了指令、工具调用和任务转移的LLM。这意味着，对于开放式任务，LLM可以自主规划如何完成任务，使用工具采取行动并获取数据，并通过任务转移将任务委派给子智能体。例如，一个研究智能体可以配备如下工具：

-   网络检索，用于在线查找信息
-   文件检索与检索回传，用于搜索专有数据和连接
-   计算机操作，用于在计算机上执行操作
-   代码执行，用于进行数据分析
-   向擅长规划、报告撰写等工作的专门智能体进行任务转移

### 核心SDK模式

在 Python SDK 中，最常见的两种编排模式是：

| 模式 | 工作方式 | 最适用场景 |
| --- | --- | --- |
| Agents as tools | 管理智能体保持对对话的控制，并通过 `Agent.as_tool()` 调用专家智能体。 | 你希望由一个智能体负责最终答案、整合多个专家的输出，或在一个位置统一执行共享安全防护措施。 |
| 任务转移 | 分流智能体将对话路由给某个专家，该专家在本轮剩余时间内成为活动智能体。 | 你希望由专家直接回复、保持提示词聚焦，或在不由管理者转述结果的情况下切换指令。 |

当专家只需协助完成边界清晰的子任务、但不应接管面向用户的对话时，使用**Agents as tools**。当“路由”本身就是工作流的一部分，且你希望被选中的专家主导下一阶段交互时，使用**任务转移**。

你也可以将两者结合。一个分流智能体可以先转移给专家，而该专家仍可将其他智能体作为工具调用来处理更窄的子任务。

这种模式非常适合开放式任务，且你希望依赖LLM的智能。这里最重要的策略是：

1. 投入高质量提示词。明确可用工具、如何使用它们，以及它必须遵守的参数边界。
2. 监控并迭代你的应用。找出问题出现的位置，并迭代优化提示词。
3. 允许智能体自省与改进。例如，让它在循环中运行并自我评估；或提供错误信息并让它自行改进。
4. 使用在单一任务上表现卓越的专门智能体，而不是期望一个通用智能体样样精通。
5. 投入使用[评测](https://platform.openai.com/docs/guides/evals)。这能让你训练智能体持续改进并更擅长任务。

如果你想了解这种编排风格背后的核心 SDK 基本组件，请从[工具](tools.md)、[任务转移](handoffs.md)和[运行智能体](running_agents.md)开始。

## 通过代码编排

虽然通过LLM编排很强大，但通过代码编排能让任务在速度、成本和性能方面更具确定性和可预测性。常见模式包括：

-   使用[structured outputs](https://platform.openai.com/docs/guides/structured-outputs)生成你可在代码中检查的格式良好的数据。例如，你可以让智能体先将任务分类到若干目录，再根据目录选择下一个智能体。
-   串联多个智能体：将前一个智能体的输出转换为下一个智能体的输入。你可以把“撰写博客文章”拆解为一系列步骤——做研究、写大纲、写文章、进行评审，然后改进。
-   在 `while` 循环中运行执行任务的智能体，并配合一个负责评估和反馈的智能体，直到评估者判定输出通过特定标准。
-   并行运行多个智能体，例如使用 Python 基本组件 `asyncio.gather`。当多个任务彼此不依赖时，这对提速很有帮助。

我们在 [`examples/agent_patterns`](https://github.com/openai/openai-agents-python/tree/main/examples/agent_patterns) 中提供了多个示例。

## 相关指南

-   [智能体](agents.md)：了解组合模式与智能体配置。
-   [工具](tools.md#agents-as-tools)：了解 `Agent.as_tool()` 与管理者风格编排。
-   [任务转移](handoffs.md)：了解专门智能体之间的委派。
-   [运行智能体](running_agents.md)：了解按次运行的编排控制与对话状态。
-   [快速开始](quickstart.md)：查看最小化端到端任务转移示例。

================
File: docs/zh/quickstart.md
================
---
search:
  exclude: true
---
# 快速入门

## 创建项目和虚拟环境

你只需要做一次。

```bash
mkdir my_project
cd my_project
python -m venv .venv
```

### 激活虚拟环境

每次开始新的终端会话时都要执行此操作。

```bash
source .venv/bin/activate
```

### 安装 Agents SDK

```bash
pip install openai-agents # or `uv add openai-agents`, etc
```

### 设置 OpenAI API 密钥

如果你还没有，请按照[这些说明](https://platform.openai.com/docs/quickstart#create-and-export-an-api-key)创建 OpenAI API 密钥。

```bash
export OPENAI_API_KEY=sk-...
```

## 创建你的第一个智能体

智能体通过 instructions、名称以及可选配置（例如特定模型）来定义。

```python
from agents import Agent

agent = Agent(
    name="History Tutor",
    instructions="You answer history questions clearly and concisely.",
)
```

## 运行你的第一个智能体

使用 [`Runner`][agents.run.Runner] 执行智能体，并获取返回的 [`RunResult`][agents.result.RunResult]。

```python
import asyncio
from agents import Agent, Runner

agent = Agent(
    name="History Tutor",
    instructions="You answer history questions clearly and concisely.",
)

async def main():
    result = await Runner.run(agent, "When did the Roman Empire fall?")
    print(result.final_output)

if __name__ == "__main__":
    asyncio.run(main())
```

在第二轮中，你可以将 `result.to_input_list()` 传回 `Runner.run(...)`，附加一个 [session](sessions/index.md)，或使用 `conversation_id` / `previous_response_id` 复用由 OpenAI 服务端管理的状态。[运行智能体](running_agents.md)指南对这些方法进行了比较。

可参考以下经验法则：

| 如果你想要... | 建议从...开始 |
| --- | --- |
| 完全手动控制且与提供商无关的历史记录 | `result.to_input_list()` |
| 由 SDK 为你加载和保存历史记录 | [`session=...`](sessions/index.md) |
| 由 OpenAI 管理的服务端续接 | `previous_response_id` 或 `conversation_id` |

有关权衡和精确行为，请参见[运行智能体](running_agents.md#choose-a-memory-strategy)。

## 为你的智能体提供工具

你可以为智能体提供工具来查找信息或执行操作。

```python
import asyncio
from agents import Agent, Runner, function_tool


@function_tool
def history_fun_fact() -> str:
    """Return a short history fact."""
    return "Sharks are older than trees."


agent = Agent(
    name="History Tutor",
    instructions="Answer history questions clearly. Use history_fun_fact when it helps.",
    tools=[history_fun_fact],
)


async def main():
    result = await Runner.run(
        agent,
        "Tell me something surprising about ancient life on Earth.",
    )
    print(result.final_output)


if __name__ == "__main__":
    asyncio.run(main())
```

## 再添加几个智能体

在选择多智能体模式之前，先决定由谁来负责最终答案：

-   **任务转移**：某位专家接管该轮对话中的这部分内容。
-   **Agents as tools**：编排器保持控制，并将专家作为工具调用。

本快速入门继续使用**任务转移**，因为这是最简短的首个示例。关于管理者风格模式，请参阅[智能体编排](multi_agent.md)和[工具：Agents as tools](tools.md#agents-as-tools)。

其他智能体也可以用同样方式定义。`handoff_description` 会为路由智能体提供额外上下文，以判断何时委派。

```python
from agents import Agent

history_tutor_agent = Agent(
    name="History Tutor",
    handoff_description="Specialist agent for historical questions",
    instructions="You answer history questions clearly and concisely.",
)

math_tutor_agent = Agent(
    name="Math Tutor",
    handoff_description="Specialist agent for math questions",
    instructions="You explain math step by step and include worked examples.",
)
```

## 定义你的任务转移

在一个智能体上，你可以定义一个可对外发起的任务转移选项清单，以便它在解决任务时进行选择。

```python
triage_agent = Agent(
    name="Triage Agent",
    instructions="Route each homework question to the right specialist.",
    handoffs=[history_tutor_agent, math_tutor_agent],
)
```

## 运行智能体编排

Runner 会处理执行各个智能体、任何任务转移以及任何工具调用。

```python
import asyncio
from agents import Runner


async def main():
    result = await Runner.run(
        triage_agent,
        "Who was the first president of the United States?",
    )
    print(result.final_output)
    print(f"Answered by: {result.last_agent.name}")


if __name__ == "__main__":
    asyncio.run(main())
```

## 参考代码示例

该仓库包含了相同核心模式的完整脚本：

-   [`examples/basic/hello_world.py`](https://github.com/openai/openai-agents-python/tree/main/examples/basic/hello_world.py) 用于首次运行。
-   [`examples/basic/tools.py`](https://github.com/openai/openai-agents-python/tree/main/examples/basic/tools.py) 用于工具调用。
-   [`examples/agent_patterns/routing.py`](https://github.com/openai/openai-agents-python/tree/main/examples/agent_patterns/routing.py) 用于多智能体路由。

## 查看追踪

要查看智能体运行期间发生了什么，请前往 [OpenAI 控制台中的 Trace viewer](https://platform.openai.com/traces) 查看智能体运行的追踪。

## 后续步骤

了解如何构建更复杂的智能体流程：

-   了解如何配置[智能体](agents.md)。
-   了解[运行智能体](running_agents.md)和[sessions](sessions/index.md)。
-   了解[tools](tools.md)、[安全防护措施](guardrails.md)和[模型](models/index.md)。

================
File: docs/zh/release.md
================
---
search:
  exclude: true
---
# 发布流程/变更日志

该项目遵循一种略微修改过的语义化版本规范，格式为 `0.Y.Z`。开头的 `0` 表示 SDK 仍在快速演进。各组件的递增规则如下：

## 次版本（`Y`）

对于任何未标记为 beta 的公共接口的**破坏性变更**，我们会递增次版本号 `Y`。例如，从 `0.0.x` 升级到 `0.1.x` 可能包含破坏性变更。

如果你不希望引入破坏性变更，我们建议在项目中将版本固定在 `0.0.x`。

## 补丁版本（`Z`）

对于非破坏性变更，我们会递增 `Z`：

- Bug 修复
- 新功能
- 对私有接口的更改
- 对 beta 功能的更新

## 破坏性变更变更日志

### 0.10.0

此次数版本发布**不会**引入破坏性变更，但它为 OpenAI Responses 用户带来了一个重要的新功能领域：Responses API 的 websocket 传输支持。

要点：

- 为 OpenAI Responses 模型新增 websocket 传输支持（可选启用；HTTP 仍为默认传输方式）。
- 新增 `responses_websocket_session()` 辅助函数 / `ResponsesWebSocketSession`，用于在多轮运行中复用同一个支持 websocket 的 provider 与 `RunConfig`。
- 新增一个 websocket 流式传输示例（`examples/basic/stream_ws.py`），涵盖 流式传输、工具、审批以及后续轮次。

### 0.9.0

在此版本中，不再支持 Python 3.9，因为该主要版本已在三个月前到达 EOL。请升级到更新的运行时版本。

此外，`Agent#as_tool()` 方法返回值的类型提示已从 `Tool` 收窄为 `FunctionTool`。这通常不会造成破坏性问题，但如果你的代码依赖更宽的联合类型，你可能需要在你这边做一些调整。

### 0.8.0

在此版本中，两处运行时行为变化可能需要迁移工作：

- 包装**同步** Python 可调用对象的工具调用现在会通过 `asyncio.to_thread(...)` 在工作线程上执行，而不是在事件循环线程中运行。如果你的工具逻辑依赖线程本地状态或线程亲和资源，请迁移到异步工具实现，或在工具代码中显式处理线程亲和性。
- 本地 MCP 工具的失败处理现在可配置，且默认行为可以返回对模型可见的错误输出，而不是让整个运行失败。如果你依赖快速失败（fail-fast）语义，请设置 `mcp_config={"failure_error_function": None}`。服务级别的 `failure_error_function` 值会覆盖智能体级别的设置，因此请在每个带有显式处理器的本地 MCP 服务上设置 `failure_error_function=None`。

### 0.7.0

在此版本中，有一些行为变化可能影响现有应用：

- 嵌套的任务转移历史现在为**可选启用**（默认禁用）。如果你依赖 v0.6.x 默认的嵌套行为，请显式设置 `RunConfig(nest_handoff_history=True)`。
- `gpt-5.1` / `gpt-5.2` 的默认 `reasoning.effort` 改为 `"none"`（此前由 SDK 默认配置的默认值是 `"low"`）。如果你的提示词或质量/成本配置依赖 `"low"`，请在 `model_settings` 中显式设置。

### 0.6.0

在此版本中，默认的任务转移历史现在会被打包为单条 assistant 消息，而不是暴露原始的 user/assistant 轮次，从而为下游智能体提供简洁、可预测的回顾
- 现有的单消息任务转移记录现在默认会在 `<CONVERSATION HISTORY>` 块之前以 "For context, here is the conversation so far between the user and the previous agent:" 开头，从而让下游智能体获得清晰标注的回顾

### 0.5.0

此版本不会引入任何可见的破坏性变更，但它包含新功能以及一些底层的重要更新：

- 新增对 `RealtimeRunner` 的支持，以处理 [SIP 协议连接](https://platform.openai.com/docs/guides/realtime-sip)
- 为兼容 Python 3.14，显著修订了 `Runner#run_sync` 的内部逻辑

### 0.4.0

在此版本中，不再支持 [openai](https://pypi.org/project/openai/) 包的 v1.x 版本。请使用 openai v2.x 并搭配此 SDK。

### 0.3.0

在此版本中，Realtime API 支持迁移到 gpt-realtime 模型及其 API 接口（GA 版本）。

### 0.2.0

在此版本中，若干过去以 `Agent` 作为参数的位置，现在改为以 `AgentBase` 作为参数。例如，MCP 服务中的 `list_tools()` 调用。这仅是类型层面的变更，你仍会收到 `Agent` 对象。更新方式是：将 `Agent` 替换为 `AgentBase` 以修复类型错误。

### 0.1.0

在此版本中，[`MCPServer.list_tools()`][agents.mcp.server.MCPServer] 新增了两个参数：`run_context` 和 `agent`。你需要将这些参数添加到所有继承 `MCPServer` 的类中。

================
File: docs/zh/repl.md
================
---
search:
  exclude: true
---
# REPL 实用工具

该 SDK 提供 `run_demo_loop`，可在终端中直接对智能体行为进行快速、交互式测试。

```python
import asyncio
from agents import Agent, run_demo_loop

async def main() -> None:
    agent = Agent(name="Assistant", instructions="You are a helpful assistant.")
    await run_demo_loop(agent)

if __name__ == "__main__":
    asyncio.run(main())
```

`run_demo_loop` 会在循环中提示输入用户输入，并在轮次之间保留对话历史。默认情况下，它会在模型生成输出的同时进行流式传输。运行上面的示例后，run_demo_loop 会启动一个交互式聊天会话。它会持续请求你的输入，在轮次之间记住完整的对话历史（因此你的智能体知道已经讨论过什么），并在生成回复的同时将智能体的响应实时流式传输给你。

要结束此聊天会话，只需输入 `quit` 或 `exit`（然后按回车），或使用键盘快捷键 `Ctrl-D`。

================
File: docs/zh/results.md
================
---
search:
  exclude: true
---
# 结果

当你调用 `Runner.run` 方法时，会收到以下两种结果类型之一：

-   来自 `Runner.run(...)` 或 `Runner.run_sync(...)` 的 [`RunResult`][agents.result.RunResult]
-   来自 `Runner.run_streamed(...)` 的 [`RunResultStreaming`][agents.result.RunResultStreaming]

二者都继承自 [`RunResultBase`][agents.result.RunResultBase]，后者公开了共享的结果接口，如 `final_output`、`new_items`、`last_agent`、`raw_responses` 和 `to_state()`。

`RunResultStreaming` 增加了流式传输专用控制项，例如 [`stream_events()`][agents.result.RunResultStreaming.stream_events]、[`current_agent`][agents.result.RunResultStreaming.current_agent]、[`is_complete`][agents.result.RunResultStreaming.is_complete] 和 [`cancel(...)`][agents.result.RunResultStreaming.cancel]。

## 合适结果接口选择

大多数应用只需要少量结果属性或辅助方法：

| 如果你需要... | 使用 |
| --- | --- |
| 展示给用户的最终答案 | `final_output` |
| 可重放的下一轮输入列表（包含完整本地对话记录） | `to_input_list()` |
| 带有智能体、工具、任务转移与审批元数据的丰富运行条目 | `new_items` |
| 通常应处理下一轮用户输入的智能体 | `last_agent` |
| 使用 `previous_response_id` 进行 OpenAI Responses API 链式调用 | `last_response_id` |
| 待处理审批和可恢复快照 | `interruptions` 和 `to_state()` |
| 当前嵌套 `Agent.as_tool()` 调用的元数据 | `agent_tool_invocation` |
| 原始模型调用或安全防护措施诊断信息 | `raw_responses` 和各类安全防护措施结果数组 |

## 最终输出

[`final_output`][agents.result.RunResultBase.final_output] 属性包含最后一个运行智能体的最终输出。它可能是：

-   `str`，如果最后一个智能体未定义 `output_type`
-   `last_agent.output_type` 类型的对象，如果最后一个智能体定义了输出类型
-   `None`，如果运行在生成最终输出前已停止，例如因审批中断而暂停

!!! note

    `final_output` 的类型为 `Any`。任务转移可能改变最终完成运行的智能体，因此 SDK 无法在静态层面获知所有可能的输出类型集合。

在流式传输模式下，`final_output` 会在流处理完成前一直保持 `None`。关于逐事件流程，请参见 [流式传输](streaming.md)。

## 输入、下一轮历史与新条目

这些接口回答的是不同问题：

| 属性或辅助方法 | 包含内容 | 最适用场景 |
| --- | --- | --- |
| [`input`][agents.result.RunResultBase.input] | 此运行片段的基础输入。如果任务转移输入过滤器重写了历史，这里反映的是运行继续使用的已过滤输入。 | 审计该次运行实际使用了什么输入 |
| [`to_input_list()`][agents.result.RunResultBase.to_input_list] | 由 `input` 加上本次运行中 `new_items` 转换结果构成的、可重放的下一轮输入列表。 | 手动聊天循环与客户端管理的对话状态 |
| [`new_items`][agents.result.RunResultBase.new_items] | 带有智能体、工具、任务转移和审批元数据的丰富 [`RunItem`][agents.items.RunItem] 包装对象。 | 日志、UI、审计与调试 |
| [`raw_responses`][agents.result.RunResultBase.raw_responses] | 运行中每次模型调用返回的原始 [`ModelResponse`][agents.items.ModelResponse] 对象。 | 提供商级诊断或原始响应检查 |

在实践中：

-   当你的应用手动维护完整对话记录时，使用 `to_input_list()`。
-   当你希望 SDK 为你加载和保存历史时，使用 [`session=...`](sessions/index.md)。
-   如果你在用带 `conversation_id` 或 `previous_response_id` 的 OpenAI 服务端托管状态，通常只需传入新的用户输入并复用已存储 ID，而不是重新发送 `to_input_list()`。

不同于 JavaScript SDK，Python 不会额外公开一个仅含模型形状增量的 `output` 属性。需要 SDK 元数据时用 `new_items`，需要原始模型负载时检查 `raw_responses`。

### 新条目

[`new_items`][agents.result.RunResultBase.new_items] 能让你最完整地看到运行期间发生了什么。常见条目类型包括：

-   用于助手消息的 [`MessageOutputItem`][agents.items.MessageOutputItem]
-   用于推理条目的 [`ReasoningItem`][agents.items.ReasoningItem]
-   用于工具调用及其结果的 [`ToolCallItem`][agents.items.ToolCallItem] 和 [`ToolCallOutputItem`][agents.items.ToolCallOutputItem]
-   用于因审批而暂停的工具调用的 [`ToolApprovalItem`][agents.items.ToolApprovalItem]
-   用于任务转移请求和完成转移的 [`HandoffCallItem`][agents.items.HandoffCallItem] 和 [`HandoffOutputItem`][agents.items.HandoffOutputItem]

当你需要智能体关联、工具输出、任务转移边界或审批边界时，应优先选择 `new_items` 而非 `to_input_list()`。

## 对话延续或恢复

### 下一轮智能体

[`last_agent`][agents.result.RunResultBase.last_agent] 包含最后运行的智能体。在发生任务转移后，它通常是下一轮用户输入最合适复用的智能体。

在流式传输模式下，[`RunResultStreaming.current_agent`][agents.result.RunResultStreaming.current_agent] 会随运行进展更新，因此你可以在流结束前观察到任务转移。

### 中断与运行状态

如果工具需要审批，待处理审批会暴露在 [`RunResult.interruptions`][agents.result.RunResult.interruptions] 或 [`RunResultStreaming.interruptions`][agents.result.RunResultStreaming.interruptions] 中。这可能包括：直接工具触发的审批、任务转移后到达工具触发的审批，或嵌套 [`Agent.as_tool()`][agents.agent.Agent.as_tool] 运行触发的审批。

调用 [`to_state()`][agents.result.RunResult.to_state] 可捕获一个可恢复的 [`RunState`][agents.run_state.RunState]，对待处理条目进行批准或拒绝，然后用 `Runner.run(...)` 或 `Runner.run_streamed(...)` 继续运行。

```python
from agents import Agent, Runner

agent = Agent(name="Assistant", instructions="Use tools when needed.")
result = await Runner.run(agent, "Delete temp files that are no longer needed.")

if result.interruptions:
    state = result.to_state()
    for interruption in result.interruptions:
        state.approve(interruption)
    result = await Runner.run(agent, state)
```

对于流式运行，先消费完 [`stream_events()`][agents.result.RunResultStreaming.stream_events]，再检查 `result.interruptions` 并从 `result.to_state()` 恢复。完整审批流程请参见 [Human-in-the-loop](human_in_the_loop.md)。

### 服务端托管的延续

[`last_response_id`][agents.result.RunResultBase.last_response_id] 是此次运行最新的模型响应 ID。若你想继续一个 OpenAI Responses API 链，可在下一轮把它作为 `previous_response_id` 传回。

如果你已经通过 `to_input_list()`、`session` 或 `conversation_id` 来延续对话，通常不需要 `last_response_id`。如果你需要多步骤运行中的每个模型响应，请改为检查 `raw_responses`。

## Agent-as-tool 元数据

当结果来自嵌套 [`Agent.as_tool()`][agents.agent.Agent.as_tool] 运行时，[`agent_tool_invocation`][agents.result.RunResultBase.agent_tool_invocation] 会公开外层工具调用的不可变元数据：

-   `tool_name`
-   `tool_call_id`
-   `tool_arguments`

对于普通顶层运行，`agent_tool_invocation` 为 `None`。

这在 `custom_output_extractor` 中尤其有用：当你对嵌套结果做后处理时，可能需要外层工具名、调用 ID 或原始参数。有关周边 `Agent.as_tool()` 模式，请参见 [工具](tools.md)。

如果你还需要该嵌套运行的已解析结构化输入，请读取 `context_wrapper.tool_input`。这是 [`RunState`][agents.run_state.RunState] 以通用方式序列化嵌套工具输入所用的字段，而 `agent_tool_invocation` 是当前嵌套调用的实时结果访问器。

## 流式传输生命周期与诊断

[`RunResultStreaming`][agents.result.RunResultStreaming] 继承了上述相同结果接口，但增加了流式传输专用控制项：

-   使用 [`stream_events()`][agents.result.RunResultStreaming.stream_events] 消费语义化流事件
-   使用 [`current_agent`][agents.result.RunResultStreaming.current_agent] 跟踪运行中当前活跃智能体
-   使用 [`is_complete`][agents.result.RunResultStreaming.is_complete] 查看流式运行是否已完全结束
-   使用 [`cancel(...)`][agents.result.RunResultStreaming.cancel] 立即停止运行或在当前轮次后停止

持续消费 `stream_events()`，直到异步迭代器结束。流式运行在该迭代器结束前都不算完成；并且诸如 `final_output`、`interruptions`、`raw_responses` 以及 session 持久化副作用等汇总属性，可能在最后一个可见 token 到达后仍在收敛。

如果你调用了 `cancel()`，仍应继续消费 `stream_events()`，以便取消与清理过程正确完成。

Python 不提供独立的流式 `completed` promise 或 `error` 属性。终止性流错误会通过 `stream_events()` 抛出异常体现，而 `is_complete` 反映运行是否已到达终止状态。

### 原始响应

[`raw_responses`][agents.result.RunResultBase.raw_responses] 包含运行期间收集到的原始模型响应。多步骤运行可能产生不止一个响应，例如跨任务转移或重复的模型/工具/模型循环。

[`last_response_id`][agents.result.RunResultBase.last_response_id] 只是 `raw_responses` 最后一项的 ID。

### 安全防护措施结果

智能体级安全防护措施结果通过 [`input_guardrail_results`][agents.result.RunResultBase.input_guardrail_results] 和 [`output_guardrail_results`][agents.result.RunResultBase.output_guardrail_results] 暴露。

工具级安全防护措施结果则通过 [`tool_input_guardrail_results`][agents.result.RunResultBase.tool_input_guardrail_results] 和 [`tool_output_guardrail_results`][agents.result.RunResultBase.tool_output_guardrail_results] 分别暴露。

这些数组会在整个运行中持续累积，因此很适合用于记录决策、存储额外安全防护措施元数据，或调试运行被阻止的原因。

### 上下文与用量

[`context_wrapper`][agents.result.RunResultBase.context_wrapper] 会公开你的应用上下文，以及由 SDK 管理的运行时元数据（如审批、用量和嵌套 `tool_input`）。

用量记录在 `context_wrapper.usage` 上。对于流式运行，用量总计可能会滞后，直到流的最终分块处理完毕。完整包装器结构和持久化注意事项请参见 [上下文管理](context.md)。

================
File: docs/zh/running_agents.md
================
---
search:
  exclude: true
---
# 运行智能体

你可以通过 [`Runner`][agents.run.Runner] 类运行智能体。你有 3 个选项：

1. [`Runner.run()`][agents.run.Runner.run]，异步运行并返回 [`RunResult`][agents.result.RunResult]。
2. [`Runner.run_sync()`][agents.run.Runner.run_sync]，这是一个同步方法，底层只是运行 `.run()`。
3. [`Runner.run_streamed()`][agents.run.Runner.run_streamed]，异步运行并返回 [`RunResultStreaming`][agents.result.RunResultStreaming]。它会以流式模式调用 LLM，并在事件到达时将其流式传给你。

```python
from agents import Agent, Runner

async def main():
    agent = Agent(name="Assistant", instructions="You are a helpful assistant")

    result = await Runner.run(agent, "Write a haiku about recursion in programming.")
    print(result.final_output)
    # Code within the code,
    # Functions calling themselves,
    # Infinite loop's dance
```

在[结果指南](results.md)中阅读更多内容。

## Runner 生命周期与配置

### 智能体循环

当你在 `Runner` 中使用 run 方法时，需要传入一个起始智能体和输入。输入可以是：

-   字符串（视为一条用户消息），
-   OpenAI Responses API 格式的输入项列表，或
-   在恢复中断运行时传入 [`RunState`][agents.run_state.RunState]。

随后 runner 会运行一个循环：

1. 我们使用当前输入为当前智能体调用 LLM。
2. LLM 生成输出。
    1. 如果 LLM 返回 `final_output`，循环结束并返回结果。
    2. 如果 LLM 执行任务转移，我们会更新当前智能体和输入，然后重新运行循环。
    3. 如果 LLM 产生工具调用，我们会执行这些工具调用、追加结果，然后重新运行循环。
3. 如果超过传入的 `max_turns`，我们会抛出 [`MaxTurnsExceeded`][agents.exceptions.MaxTurnsExceeded] 异常。

!!! note

    判断 LLM 输出是否为“最终输出”的规则是：它生成了目标类型的文本输出，且没有工具调用。

### 流式传输

流式传输让你在 LLM 运行时额外接收流式事件。流结束后，[`RunResultStreaming`][agents.result.RunResultStreaming] 将包含本次运行的完整信息，包括所有新生成的输出。你可以调用 `.stream_events()` 获取流式事件。在[流式传输指南](streaming.md)中阅读更多内容。

#### Responses WebSocket 传输（可选辅助）

如果你启用 OpenAI Responses websocket 传输，仍可继续使用常规 `Runner` API。推荐使用 websocket 会话辅助器来复用连接，但并非必需。

这是通过 websocket 传输的 Responses API，而不是 [Realtime API](realtime/guide.md)。

关于传输选择规则以及具体模型对象或自定义 provider 的注意事项，请参见[模型](models/index.md#responses-websocket-transport)。

##### 模式 1：不使用会话辅助器（可用）

当你只想使用 websocket 传输且不需要 SDK 为你管理共享 provider/session 时，请使用此模式。

```python
import asyncio

from agents import Agent, Runner, set_default_openai_responses_transport


async def main():
    set_default_openai_responses_transport("websocket")

    agent = Agent(name="Assistant", instructions="Be concise.")
    result = Runner.run_streamed(agent, "Summarize recursion in one sentence.")

    async for event in result.stream_events():
        if event.type == "raw_response_event":
            continue
        print(event.type)


asyncio.run(main())
```

这种模式适用于单次运行。如果你反复调用 `Runner.run()` / `Runner.run_streamed()`，除非你手动复用相同的 `RunConfig` / provider 实例，否则每次运行都可能重新连接。

##### 模式 2：使用 `responses_websocket_session()`（推荐用于多轮复用）

当你希望在多次运行之间共享支持 websocket 的 provider 和 `RunConfig`（包括继承同一 `run_config` 的嵌套 Agents-as-tools 调用）时，请使用 [`responses_websocket_session()`][agents.responses_websocket_session]。

```python
import asyncio

from agents import Agent, responses_websocket_session


async def main():
    agent = Agent(name="Assistant", instructions="Be concise.")

    async with responses_websocket_session() as ws:
        first = ws.run_streamed(agent, "Say hello in one short sentence.")
        async for _event in first.stream_events():
            pass

        second = ws.run_streamed(
            agent,
            "Now say goodbye.",
            previous_response_id=first.last_response_id,
        )
        async for _event in second.stream_events():
            pass


asyncio.run(main())
```

请在上下文退出前完成对流式结果的消费。如果 websocket 请求仍在进行时就退出上下文，可能会强制关闭共享连接。

### 运行配置

`run_config` 参数允许你为智能体运行配置一些全局设置：

#### 常见运行配置目录

使用 `RunConfig` 可以在不修改每个智能体定义的情况下，为单次运行覆盖行为。

##### 模型、provider 与 session 默认值

-   [`model`][agents.run.RunConfig.model]：允许设置全局 LLM 模型，不受各 Agent 自身 `model` 设置影响。
-   [`model_provider`][agents.run.RunConfig.model_provider]：用于查找模型名称的模型 provider，默认是 OpenAI。
-   [`model_settings`][agents.run.RunConfig.model_settings]：覆盖智能体特定设置。例如，你可以设置全局 `temperature` 或 `top_p`。
-   [`session_settings`][agents.run.RunConfig.session_settings]：在运行期间检索历史时，覆盖 session 级默认值（例如 `SessionSettings(limit=...)`）。
-   [`session_input_callback`][agents.run.RunConfig.session_input_callback]：在使用 Sessions 时，自定义每轮前如何将新用户输入与会话历史合并。该回调可为同步或异步。

##### 安全防护措施、任务转移与模型输入整形

-   [`input_guardrails`][agents.run.RunConfig.input_guardrails], [`output_guardrails`][agents.run.RunConfig.output_guardrails]：要在所有运行中包含的输入或输出安全防护措施列表。
-   [`handoff_input_filter`][agents.run.RunConfig.handoff_input_filter]：应用于所有任务转移的全局输入过滤器（如果该任务转移尚未设置过滤器）。输入过滤器允许你编辑发送到新智能体的输入。更多细节见 [`Handoff.input_filter`][agents.handoffs.Handoff.input_filter] 文档。
-   [`nest_handoff_history`][agents.run.RunConfig.nest_handoff_history]：可选启用的 beta 功能，在调用下一个智能体前将先前转录折叠为单条 assistant 消息。默认禁用（我们仍在稳定嵌套任务转移）；设为 `True` 可启用，保持 `False` 则透传原始转录。当你不传入 `RunConfig` 时，所有 [Runner 方法][agents.run.Runner] 会自动创建一个，因此快速入门和示例默认保持关闭；任何显式的 [`Handoff.input_filter`][agents.handoffs.Handoff.input_filter] 回调仍会覆盖它。单个任务转移可通过 [`Handoff.nest_handoff_history`][agents.handoffs.Handoff.nest_handoff_history] 覆盖该设置。
-   [`handoff_history_mapper`][agents.run.RunConfig.handoff_history_mapper]：可选可调用对象，在你启用 `nest_handoff_history` 时，每次都会接收标准化转录（历史 + 任务转移项）。它必须返回要转发给下一个智能体的精确输入项列表，使你无需编写完整任务转移过滤器即可替换内置摘要。
-   [`call_model_input_filter`][agents.run.RunConfig.call_model_input_filter]：在模型调用前立即编辑已完整准备的模型输入（instructions 和输入项）的钩子，例如裁剪历史或注入系统提示词。
-   [`reasoning_item_id_policy`][agents.run.RunConfig.reasoning_item_id_policy]：控制 runner 在将先前输出转换为下一轮模型输入时，是否保留或省略 reasoning 项 ID。

##### 追踪与可观测性

-   [`tracing_disabled`][agents.run.RunConfig.tracing_disabled]：允许你为整个运行禁用[追踪](tracing.md)。
-   [`tracing`][agents.run.RunConfig.tracing]：传入 [`TracingConfig`][agents.tracing.TracingConfig] 以覆盖本次运行的导出器、进程或追踪元数据。
-   [`trace_include_sensitive_data`][agents.run.RunConfig.trace_include_sensitive_data]：配置追踪是否包含潜在敏感数据，如 LLM 与工具调用输入/输出。
-   [`workflow_name`][agents.run.RunConfig.workflow_name], [`trace_id`][agents.run.RunConfig.trace_id], [`group_id`][agents.run.RunConfig.group_id]：设置本次运行的追踪工作流名称、追踪 ID 与追踪组 ID。我们建议至少设置 `workflow_name`。group ID 是可选字段，可用于跨多次运行关联追踪。
-   [`trace_metadata`][agents.run.RunConfig.trace_metadata]：包含在所有追踪中的元数据。

##### 工具审批与工具错误行为

-   [`tool_error_formatter`][agents.run.RunConfig.tool_error_formatter]：在审批流程中工具调用被拒绝时，自定义模型可见消息。

嵌套任务转移作为可选启用的 beta 功能提供。可通过传入 `RunConfig(nest_handoff_history=True)` 启用折叠转录行为，或设置 `handoff(..., nest_handoff_history=True)` 仅对特定任务转移启用。若你更希望保留原始转录（默认行为），请保持该标志未设置，或提供会按你的需要原样转发对话的 `handoff_input_filter`（或 `handoff_history_mapper`）。若要在不编写自定义 mapper 的情况下修改生成摘要使用的包装文本，请调用 [`set_conversation_history_wrappers`][agents.handoffs.set_conversation_history_wrappers]（并通过 [`reset_conversation_history_wrappers`][agents.handoffs.reset_conversation_history_wrappers] 恢复默认值）。

#### 运行配置细节

##### `tool_error_formatter`

使用 `tool_error_formatter` 可在审批流程中工具调用被拒绝时，自定义返回给模型的消息。

格式化器接收包含以下字段的 [`ToolErrorFormatterArgs`][agents.run_config.ToolErrorFormatterArgs]：

-   `kind`：错误类别。当前为 `"approval_rejected"`。
-   `tool_type`：工具运行时（`"function"`、`"computer"`、`"shell"` 或 `"apply_patch"`）。
-   `tool_name`：工具名称。
-   `call_id`：工具调用 ID。
-   `default_message`：SDK 默认的模型可见消息。
-   `run_context`：当前活动运行上下文包装器。

返回字符串以替换该消息，或返回 `None` 以使用 SDK 默认值。

```python
from agents import Agent, RunConfig, Runner, ToolErrorFormatterArgs


def format_rejection(args: ToolErrorFormatterArgs[None]) -> str | None:
    if args.kind == "approval_rejected":
        return (
            f"Tool call '{args.tool_name}' was rejected by a human reviewer. "
            "Ask for confirmation or propose a safer alternative."
        )
    return None


agent = Agent(name="Assistant")
result = Runner.run_sync(
    agent,
    "Please delete the production database.",
    run_config=RunConfig(tool_error_formatter=format_rejection),
)
```

##### `reasoning_item_id_policy`

`reasoning_item_id_policy` 控制当 runner 继续携带历史时（例如使用 `RunResult.to_input_list()` 或基于 session 的运行），如何将 reasoning 项转换为下一轮模型输入。

-   `None` 或 `"preserve"`（默认）：保留 reasoning 项 ID。
-   `"omit"`：从生成的下一轮输入中移除 reasoning 项 ID。

`"omit"` 主要用于可选缓解一类 Responses API 400 错误：当发送了带 `id` 的 reasoning 项，但缺少必需的后续项时（例如 `Item 'rs_...' of type 'reasoning' was provided without its required following item.`）。

这可能发生在多轮智能体运行中：SDK 从先前输出构造后续输入（包括 session 持久化、服务端管理的会话增量、流式/非流式后续轮次与恢复路径）时，保留了 reasoning 项 ID，但 provider 要求该 ID 必须与其对应后续项保持配对。

设置 `reasoning_item_id_policy="omit"` 会保留 reasoning 内容，但移除 reasoning 项 `id`，从而避免在 SDK 生成的后续输入中触发该 API 不变量约束。

作用范围说明：

-   这只会影响 SDK 在构建后续输入时生成/转发的 reasoning 项。
-   不会改写用户提供的初始输入项。
-   在应用此策略后，`call_model_input_filter` 仍可有意重新引入 reasoning ID。

## 状态与会话管理

### 内存策略选择

将状态带入下一轮有四种常见方式：

| Strategy | Where state lives | Best for | What you pass on the next turn |
| --- | --- | --- | --- |
| `result.to_input_list()` | 你的应用内存 | 小型聊天循环、完全手动控制、任意 provider | 来自 `result.to_input_list()` 的列表加上下一个用户消息 |
| `session` | 你的存储加 SDK | 持久聊天状态、可恢复运行、自定义存储 | 同一个 `session` 实例，或指向同一存储的另一个实例 |
| `conversation_id` | OpenAI Conversations API | 你希望在多个 worker 或服务间共享的命名服务端会话 | 相同的 `conversation_id`，外加仅新的用户轮次 |
| `previous_response_id` | OpenAI Responses API | 无需创建会话资源的轻量级服务端托管延续 | `result.last_response_id`，外加仅新的用户轮次 |

`result.to_input_list()` 与 `session` 属于客户端管理。`conversation_id` 与 `previous_response_id` 属于 OpenAI 管理，且仅在你使用 OpenAI Responses API 时适用。在大多数应用中，每个会话选择一种持久化策略即可。除非你有意协调这两层，否则混用客户端管理历史与 OpenAI 托管状态可能导致上下文重复。

!!! note

    Session 持久化不能与服务端托管会话设置
    （`conversation_id`、`previous_response_id` 或 `auto_previous_response_id`）
    在同一次运行中组合使用。每次调用请选择一种方式。

### 会话/聊天线程

调用任一 run 方法都可能导致一个或多个智能体运行（从而发生一次或多次 LLM 调用），但它在聊天会话中表示单个逻辑轮次。例如：

1. 用户轮次：用户输入文本
2. Runner 运行：第一个智能体调用 LLM、运行工具、将任务转移给第二个智能体，第二个智能体运行更多工具，然后生成输出。

在智能体运行结束时，你可以选择向用户展示什么。例如，你可以向用户展示智能体生成的每个新项，或只展示最终输出。无论哪种方式，用户随后都可能提出追问，此时你可以再次调用 run 方法。

#### 手动会话管理

你可以使用 [`RunResultBase.to_input_list()`][agents.result.RunResultBase.to_input_list] 方法获取下一轮输入，从而手动管理会话历史：

```python
async def main():
    agent = Agent(name="Assistant", instructions="Reply very concisely.")

    thread_id = "thread_123"  # Example thread ID
    with trace(workflow_name="Conversation", group_id=thread_id):
        # First turn
        result = await Runner.run(agent, "What city is the Golden Gate Bridge in?")
        print(result.final_output)
        # San Francisco

        # Second turn
        new_input = result.to_input_list() + [{"role": "user", "content": "What state is it in?"}]
        result = await Runner.run(agent, new_input)
        print(result.final_output)
        # California
```

#### 使用 session 自动会话管理

更简单的方法是使用[Sessions](sessions/index.md) 自动处理会话历史，而无需手动调用 `.to_input_list()`：

```python
from agents import Agent, Runner, SQLiteSession

async def main():
    agent = Agent(name="Assistant", instructions="Reply very concisely.")

    # Create session instance
    session = SQLiteSession("conversation_123")

    thread_id = "thread_123"  # Example thread ID
    with trace(workflow_name="Conversation", group_id=thread_id):
        # First turn
        result = await Runner.run(agent, "What city is the Golden Gate Bridge in?", session=session)
        print(result.final_output)
        # San Francisco

        # Second turn - agent automatically remembers previous context
        result = await Runner.run(agent, "What state is it in?", session=session)
        print(result.final_output)
        # California
```

Sessions 会自动：

-   在每次运行前检索会话历史
-   在每次运行后存储新消息
-   为不同 session ID 维护独立会话

更多细节请参见 [Sessions 文档](sessions/index.md)。


#### 服务端托管会话

你也可以让 OpenAI 会话状态功能在服务端管理会话状态，而不是在本地使用 `to_input_list()` 或 `Sessions` 处理。这使你无需手动重发全部历史消息也能保留会话历史。对于下面任一种服务端托管方式，每次请求只传入新一轮输入并复用已保存 ID。更多细节见 [OpenAI 会话状态指南](https://platform.openai.com/docs/guides/conversation-state?api-mode=responses)。

OpenAI 提供两种跨轮次跟踪状态的方法：

##### 1. 使用 `conversation_id`

你先使用 OpenAI Conversations API 创建会话，然后在后续每次调用中复用其 ID：

```python
from agents import Agent, Runner
from openai import AsyncOpenAI

client = AsyncOpenAI()

async def main():
    agent = Agent(name="Assistant", instructions="Reply very concisely.")

    # Create a server-managed conversation
    conversation = await client.conversations.create()
    conv_id = conversation.id

    while True:
        user_input = input("You: ")
        result = await Runner.run(agent, user_input, conversation_id=conv_id)
        print(f"Assistant: {result.final_output}")
```

##### 2. 使用 `previous_response_id`

另一种选项是**响应链式传递**，每一轮都显式链接到前一轮的响应 ID。

```python
from agents import Agent, Runner

async def main():
    agent = Agent(name="Assistant", instructions="Reply very concisely.")

    previous_response_id = None

    while True:
        user_input = input("You: ")

        # Setting auto_previous_response_id=True enables response chaining automatically
        # for the first turn, even when there's no actual previous response ID yet.
        result = await Runner.run(
            agent,
            user_input,
            previous_response_id=previous_response_id,
            auto_previous_response_id=True,
        )
        previous_response_id = result.last_response_id
        print(f"Assistant: {result.final_output}")
```

如果某次运行因审批而暂停，并且你从 [`RunState`][agents.run_state.RunState] 恢复，
SDK 会保留保存的 `conversation_id` / `previous_response_id` / `auto_previous_response_id`
设置，从而使恢复后的轮次继续在同一服务端托管会话中进行。

`conversation_id` 与 `previous_response_id` 互斥。若你希望使用可在系统间共享的命名会话资源，请使用 `conversation_id`。若你希望使用从一轮到下一轮最轻量的 Responses API 延续机制，请使用 `previous_response_id`。

!!! note

    SDK 会自动对 `conversation_locked` 错误执行带退避的重试。在服务端托管
    会话运行中，它会在重试前回滚内部会话跟踪器输入，以便可干净地重新发送
    相同的已准备项。

    在本地基于 session 的运行中（不能与 `conversation_id`、
    `previous_response_id` 或 `auto_previous_response_id` 组合使用），SDK 也会尽力
    回滚最近持久化的输入项，以减少重试后重复历史条目。

## 钩子与自定义

### 模型调用输入过滤器

使用 `call_model_input_filter` 可在模型调用前立即编辑模型输入。该钩子接收当前智能体、上下文和合并后的输入项（若存在 session 历史也包含在内），并返回新的 `ModelInputData`。

返回值必须是 [`ModelInputData`][agents.run.ModelInputData] 对象。其 `input` 字段为必填，且必须是输入项列表。返回其他结构会抛出 `UserError`。

```python
from agents import Agent, Runner, RunConfig
from agents.run import CallModelData, ModelInputData

def drop_old_messages(data: CallModelData[None]) -> ModelInputData:
    # Keep only the last 5 items and preserve existing instructions.
    trimmed = data.model_data.input[-5:]
    return ModelInputData(input=trimmed, instructions=data.model_data.instructions)

agent = Agent(name="Assistant", instructions="Answer concisely.")
result = Runner.run_sync(
    agent,
    "Explain quines",
    run_config=RunConfig(call_model_input_filter=drop_old_messages),
)
```

runner 会将已准备输入列表的副本传给钩子，因此你可以裁剪、替换或重排它，而不会原地修改调用方的原始列表。

如果你正在使用 session，`call_model_input_filter` 会在 session 历史已加载并与当前轮次合并后运行。如果你想自定义更早的合并步骤本身，请使用 [`session_input_callback`][agents.run.RunConfig.session_input_callback]。

如果你正在使用 `conversation_id`、`previous_response_id` 或 `auto_previous_response_id` 的 OpenAI 服务端托管会话状态，该钩子会作用于下一次 Responses API 调用的已准备负载。该负载可能已仅表示新轮次增量，而非完整重放历史。只有你返回的项会被标记为已发送，用于该服务端托管延续。

通过 `run_config` 按运行设置该钩子，可用于脱敏、裁剪长历史或注入额外系统指引。

## 错误与恢复

### 错误处理器

所有 `Runner` 入口都接受 `error_handlers`（按错误类型键控的字典）。当前支持的键是 `"max_turns"`。当你希望返回受控最终输出而非抛出 `MaxTurnsExceeded` 时可使用它。

```python
from agents import (
    Agent,
    RunErrorHandlerInput,
    RunErrorHandlerResult,
    Runner,
)

agent = Agent(name="Assistant", instructions="Be concise.")


def on_max_turns(_data: RunErrorHandlerInput[None]) -> RunErrorHandlerResult:
    return RunErrorHandlerResult(
        final_output="I couldn't finish within the turn limit. Please narrow the request.",
        include_in_history=False,
    )


result = Runner.run_sync(
    agent,
    "Analyze this long transcript",
    max_turns=3,
    error_handlers={"max_turns": on_max_turns},
)
print(result.final_output)
```

当你不希望将回退输出追加到会话历史时，设置 `include_in_history=False`。

## 持久执行集成与 human-in-the-loop

对于工具审批暂停/恢复模式，请先阅读专门的 [Human-in-the-loop 指南](human_in_the_loop.md)。
下面的集成适用于运行可能跨越长时间等待、重试或进程重启的持久化编排场景。

### Temporal

你可以使用 Agents SDK 的 [Temporal](https://temporal.io/) 集成来运行持久化、长时工作流，包括 human-in-the-loop 任务。查看 Temporal 与 Agents SDK 协同完成长时任务的演示[视频](https://www.youtube.com/watch?v=fFBZqzT4DD8)，并在[此处查看文档](https://github.com/temporalio/sdk-python/tree/main/temporalio/contrib/openai_agents)。 

### Restate

你可以使用 Agents SDK 的 [Restate](https://restate.dev/) 集成来实现轻量、持久的智能体能力，包括人工审批、任务转移和 session 管理。该集成依赖 Restate 的单二进制运行时，并支持将智能体作为进程/容器或无服务器函数运行。
请阅读[概览](https://www.restate.dev/blog/durable-orchestration-for-ai-agents-with-restate-and-openai-sdk)或查看[文档](https://docs.restate.dev/ai)了解更多细节。

### DBOS

你可以使用 Agents SDK 的 [DBOS](https://dbos.dev/) 集成来运行可靠智能体，在故障与重启间保留进度。它支持长时智能体、human-in-the-loop 工作流和任务转移，并同时支持同步与异步方法。该集成仅需 SQLite 或 Postgres 数据库。请查看集成 [repo](https://github.com/dbos-inc/dbos-openai-agents) 和[文档](https://docs.dbos.dev/integrations/openai-agents)了解更多细节。

## 异常

SDK 在某些情况下会抛出异常。完整列表见 [`agents.exceptions`][]。概览如下：

-   [`AgentsException`][agents.exceptions.AgentsException]：这是 SDK 内所有异常的基类，作为其他具体异常派生的通用类型。
-   [`MaxTurnsExceeded`][agents.exceptions.MaxTurnsExceeded]：当智能体运行超过传给 `Runner.run`、`Runner.run_sync` 或 `Runner.run_streamed` 方法的 `max_turns` 限制时抛出。它表示智能体无法在指定交互轮次数内完成任务。
-   [`ModelBehaviorError`][agents.exceptions.ModelBehaviorError]：当底层模型（LLM）产生意外或无效输出时发生。包括：
    -   JSON 格式错误：当模型在工具调用或其直接输出中提供了格式错误的 JSON 结构，尤其是在定义了特定 `output_type` 时。
    -   与工具相关的意外失败：当模型未按预期方式使用工具时
-   [`ToolTimeoutError`][agents.exceptions.ToolTimeoutError]：当工具调用超过其配置超时时间，且该工具使用 `timeout_behavior="raise_exception"` 时抛出。
-   [`UserError`][agents.exceptions.UserError]：当你（使用 SDK 编写代码的人）在使用 SDK 时发生错误而抛出。通常源于代码实现不正确、配置无效或误用 SDK API。
-   [`InputGuardrailTripwireTriggered`][agents.exceptions.InputGuardrailTripwireTriggered], [`OutputGuardrailTripwireTriggered`][agents.exceptions.OutputGuardrailTripwireTriggered]：当输入安全防护措施或输出安全防护措施的触发条件分别满足时抛出。输入安全防护措施会在处理前检查传入消息，而输出安全防护措施会在交付前检查智能体最终响应。

================
File: docs/zh/streaming.md
================
---
search:
  exclude: true
---
# 流式传输

流式传输可让你在智能体运行过程中订阅更新。这对于向终端用户展示进度更新和部分响应非常有用。

要进行流式传输，你可以调用 [`Runner.run_streamed()`][agents.run.Runner.run_streamed]，它会返回一个 [`RunResultStreaming`][agents.result.RunResultStreaming]。调用 `result.stream_events()` 会得到一个由 [`StreamEvent`][agents.stream_events.StreamEvent] 对象组成的异步流，相关说明如下。

请持续消费 `result.stream_events()`，直到异步迭代器结束。流式运行在迭代器结束前都不算完成，并且诸如会话持久化、审批记录维护或历史压缩等后处理，可能会在最后一个可见 token 到达后才完成。循环退出时，`result.is_complete` 会反映最终的运行状态。

## 原始响应事件

[`RawResponsesStreamEvent`][agents.stream_events.RawResponsesStreamEvent] 是直接从 LLM 传递的原始事件。它们采用 OpenAI Responses API 格式，这意味着每个事件都有类型（如 `response.created`、`response.output_text.delta` 等）和数据。如果你希望在响应消息生成后立刻流式推送给用户，这些事件会很有用。

例如，下面的代码会逐 token 输出 LLM 生成的文本。

```python
import asyncio
from openai.types.responses import ResponseTextDeltaEvent
from agents import Agent, Runner

async def main():
    agent = Agent(
        name="Joker",
        instructions="You are a helpful assistant.",
    )

    result = Runner.run_streamed(agent, input="Please tell me 5 jokes.")
    async for event in result.stream_events():
        if event.type == "raw_response_event" and isinstance(event.data, ResponseTextDeltaEvent):
            print(event.data.delta, end="", flush=True)


if __name__ == "__main__":
    asyncio.run(main())
```

## 流式传输与审批

流式传输与会因工具审批而暂停的运行兼容。如果某个工具需要审批，`result.stream_events()` 会结束，待处理审批会出现在 [`RunResultStreaming.interruptions`][agents.result.RunResultStreaming.interruptions] 中。使用 `result.to_state()` 将结果转换为 [`RunState`][agents.run_state.RunState]，批准或拒绝该中断后，再通过 `Runner.run_streamed(...)` 恢复运行。

```python
result = Runner.run_streamed(agent, "Delete temporary files if they are no longer needed.")
async for _event in result.stream_events():
    pass

if result.interruptions:
    state = result.to_state()
    for interruption in result.interruptions:
        state.approve(interruption)
    result = Runner.run_streamed(agent, state)
    async for _event in result.stream_events():
        pass
```

有关完整的暂停/恢复流程，请参阅[人在回路指南](human_in_the_loop.md)。

## 运行项事件与智能体事件

[`RunItemStreamEvent`][agents.stream_events.RunItemStreamEvent] 是更高层级的事件。它们会在某个运行项被完整生成时通知你。这使你可以按“消息已生成”“工具已运行”等级别推送进度更新，而不是按每个 token 推送。类似地，[`AgentUpdatedStreamEvent`][agents.stream_events.AgentUpdatedStreamEvent] 会在当前智能体发生变化时（例如由于任务转移）提供更新。

### 运行项事件名称

`RunItemStreamEvent.name` 使用一组固定的语义事件名称：

-   `message_output_created`
-   `handoff_requested`
-   `handoff_occured`
-   `tool_called`
-   `tool_output`
-   `reasoning_item_created`
-   `mcp_approval_requested`
-   `mcp_approval_response`
-   `mcp_list_tools`

`handoff_occured` 的拼写错误是有意保留的，以实现向后兼容。

例如，下面的代码会忽略原始事件，并向用户流式推送更新。

```python
import asyncio
import random
from agents import Agent, ItemHelpers, Runner, function_tool

@function_tool
def how_many_jokes() -> int:
    return random.randint(1, 10)


async def main():
    agent = Agent(
        name="Joker",
        instructions="First call the `how_many_jokes` tool, then tell that many jokes.",
        tools=[how_many_jokes],
    )

    result = Runner.run_streamed(
        agent,
        input="Hello",
    )
    print("=== Run starting ===")

    async for event in result.stream_events():
        # We'll ignore the raw responses event deltas
        if event.type == "raw_response_event":
            continue
        # When the agent updates, print that
        elif event.type == "agent_updated_stream_event":
            print(f"Agent updated: {event.new_agent.name}")
            continue
        # When items are generated, print them
        elif event.type == "run_item_stream_event":
            if event.item.type == "tool_call_item":
                print("-- Tool was called")
            elif event.item.type == "tool_call_output_item":
                print(f"-- Tool output: {event.item.output}")
            elif event.item.type == "message_output_item":
                print(f"-- Message output:\n {ItemHelpers.text_message_output(event.item)}")
            else:
                pass  # Ignore other event types

    print("=== Run complete ===")


if __name__ == "__main__":
    asyncio.run(main())
```

================
File: docs/zh/tools.md
================
---
search:
  exclude: true
---
# 工具

工具让智能体能够执行操作：例如获取数据、运行代码、调用外部 API，甚至使用计算机。SDK 支持五个目录：

-   由OpenAI托管的工具：与模型一起在 OpenAI 服务上运行。
-   本地/运行时执行工具：`ComputerTool` 和 `ApplyPatchTool` 始终在你的环境中运行，而 `ShellTool` 可在本地或托管容器中运行。
-   Function Calling：将任意 Python 函数封装为工具。
-   Agents as tools：将智能体暴露为可调用工具，而不进行完整任务转移。
-   实验性：Codex 工具：通过工具调用运行工作区范围的 Codex 任务。

## 工具类型选择

将本页作为目录使用，然后跳转到与你可控制的运行时相匹配的章节。

| 如果你想要... | 从这里开始 |
| --- | --- |
| 使用 OpenAI 管理的工具（网络检索、文件检索、Code Interpreter、托管 MCP、图像生成） | [托管工具](#hosted-tools) |
| 在你自己的进程或环境中运行工具 | [本地运行时工具](#local-runtime-tools) |
| 将 Python 函数封装为工具 | [工具调用](#function-tools) |
| 让一个智能体在不任务转移的情况下调用另一个智能体 | [Agents as tools](#agents-as-tools) |
| 从智能体运行工作区范围的 Codex 任务 | [实验性：Codex 工具](#experimental-codex-tool) |

## 托管工具

在使用 [`OpenAIResponsesModel`][agents.models.openai_responses.OpenAIResponsesModel] 时，OpenAI 提供了一些内置工具：

-   [`WebSearchTool`][agents.tool.WebSearchTool] 让智能体可以搜索网络。
-   [`FileSearchTool`][agents.tool.FileSearchTool] 允许从你的 OpenAI 向量存储中检索信息。
-   [`CodeInterpreterTool`][agents.tool.CodeInterpreterTool] 让 LLM 在沙箱环境中执行代码。
-   [`HostedMCPTool`][agents.tool.HostedMCPTool] 将远程 MCP 服务的工具暴露给模型。
-   [`ImageGenerationTool`][agents.tool.ImageGenerationTool] 根据提示词生成图像。

高级托管检索选项：

-   `FileSearchTool` 除了 `vector_store_ids` 和 `max_num_results` 外，还支持 `filters`、`ranking_options` 和 `include_search_results`。
-   `WebSearchTool` 支持 `filters`、`user_location` 和 `search_context_size`。

```python
from agents import Agent, FileSearchTool, Runner, WebSearchTool

agent = Agent(
    name="Assistant",
    tools=[
        WebSearchTool(),
        FileSearchTool(
            max_num_results=3,
            vector_store_ids=["VECTOR_STORE_ID"],
        ),
    ],
)

async def main():
    result = await Runner.run(agent, "Which coffee shop should I go to, taking into account my preferences and the weather today in SF?")
    print(result.final_output)
```

### 托管容器 shell + skills

`ShellTool` 也支持由 OpenAI 托管的容器执行。当你希望模型在受管容器中运行 shell 命令而不是在本地运行时时，请使用此模式。

```python
from agents import Agent, Runner, ShellTool, ShellToolSkillReference

csv_skill: ShellToolSkillReference = {
    "type": "skill_reference",
    "skill_id": "skill_698bbe879adc81918725cbc69dcae7960bc5613dadaed377",
    "version": "1",
}

agent = Agent(
    name="Container shell agent",
    model="gpt-5.2",
    instructions="Use the mounted skill when helpful.",
    tools=[
        ShellTool(
            environment={
                "type": "container_auto",
                "network_policy": {"type": "disabled"},
                "skills": [csv_skill],
            }
        )
    ],
)

result = await Runner.run(
    agent,
    "Use the configured skill to analyze CSV files in /mnt/data and summarize totals by region.",
)
print(result.final_output)
```

要在后续运行中复用现有容器，请设置 `environment={"type": "container_reference", "container_id": "cntr_..."}`。

须知事项：

-   托管 shell 可通过 Responses API 的 shell 工具使用。
-   `container_auto` 会为请求配置容器；`container_reference` 会复用现有容器。
-   `container_auto` 也可包含 `file_ids` 和 `memory_limit`。
-   `environment.skills` 接受 skill 引用和内联 skill bundle。
-   使用托管环境时，不要在 `ShellTool` 上设置 `executor`、`needs_approval` 或 `on_approval`。
-   `network_policy` 支持 `disabled` 和 `allowlist` 模式。
-   在 allowlist 模式下，`network_policy.domain_secrets` 可按名称注入域范围密钥。
-   完整示例见 `examples/tools/container_shell_skill_reference.py` 和 `examples/tools/container_shell_inline_skill.py`。
-   OpenAI 平台指南：[Shell](https://platform.openai.com/docs/guides/tools-shell) 和 [Skills](https://platform.openai.com/docs/guides/tools-skills)。

## 本地运行时工具

本地运行时工具在模型响应本身之外执行。模型仍会决定何时调用它们，但实际工作由你的应用或已配置的执行环境完成。

`ComputerTool` 和 `ApplyPatchTool` 始终需要你提供本地实现。`ShellTool` 同时覆盖两种模式：当你需要受管执行时，使用上面的托管容器配置；当你希望命令在自己的进程中运行时，使用下面的本地运行时配置。

本地运行时工具要求你提供实现：

-   [`ComputerTool`][agents.tool.ComputerTool]：实现 [`Computer`][agents.computer.Computer] 或 [`AsyncComputer`][agents.computer.AsyncComputer] 接口以启用 GUI/浏览器自动化。
-   [`ShellTool`][agents.tool.ShellTool]：同时支持本地执行和托管容器执行的最新 shell 工具。
-   [`LocalShellTool`][agents.tool.LocalShellTool]：旧版本地 shell 集成。
-   [`ApplyPatchTool`][agents.tool.ApplyPatchTool]：实现 [`ApplyPatchEditor`][agents.editor.ApplyPatchEditor] 以在本地应用差异补丁。
-   可通过 `ShellTool(environment={"type": "local", "skills": [...]})` 使用本地 shell skills。

```python
from agents import Agent, ApplyPatchTool, ShellTool
from agents.computer import AsyncComputer
from agents.editor import ApplyPatchResult, ApplyPatchOperation, ApplyPatchEditor


class NoopComputer(AsyncComputer):
    environment = "browser"
    dimensions = (1024, 768)
    async def screenshot(self): return ""
    async def click(self, x, y, button): ...
    async def double_click(self, x, y): ...
    async def scroll(self, x, y, scroll_x, scroll_y): ...
    async def type(self, text): ...
    async def wait(self): ...
    async def move(self, x, y): ...
    async def keypress(self, keys): ...
    async def drag(self, path): ...


class NoopEditor(ApplyPatchEditor):
    async def create_file(self, op: ApplyPatchOperation): return ApplyPatchResult(status="completed")
    async def update_file(self, op: ApplyPatchOperation): return ApplyPatchResult(status="completed")
    async def delete_file(self, op: ApplyPatchOperation): return ApplyPatchResult(status="completed")


async def run_shell(request):
    return "shell output"


agent = Agent(
    name="Local tools agent",
    tools=[
        ShellTool(executor=run_shell),
        ApplyPatchTool(editor=NoopEditor()),
        # ComputerTool expects a Computer/AsyncComputer implementation; omitted here for brevity.
    ],
)
```

## 工具调用

你可以将任何 Python 函数用作工具。Agents SDK 会自动设置该工具：

-   工具名称将是 Python 函数名称（也可自行提供名称）
-   工具描述将取自函数 docstring（也可自行提供描述）
-   函数输入的 schema 会根据函数参数自动创建
-   每个输入的描述会从函数 docstring 中提取，除非禁用

我们使用 Python 的 `inspect` 模块提取函数签名，并结合 [`griffe`](https://mkdocstrings.github.io/griffe/) 解析 docstring，再使用 `pydantic` 创建 schema。

```python
import json

from typing_extensions import TypedDict, Any

from agents import Agent, FunctionTool, RunContextWrapper, function_tool


class Location(TypedDict):
    lat: float
    long: float

@function_tool  # (1)!
async def fetch_weather(location: Location) -> str:
    # (2)!
    """Fetch the weather for a given location.

    Args:
        location: The location to fetch the weather for.
    """
    # In real life, we'd fetch the weather from a weather API
    return "sunny"


@function_tool(name_override="fetch_data")  # (3)!
def read_file(ctx: RunContextWrapper[Any], path: str, directory: str | None = None) -> str:
    """Read the contents of a file.

    Args:
        path: The path to the file to read.
        directory: The directory to read the file from.
    """
    # In real life, we'd read the file from the file system
    return "<file contents>"


agent = Agent(
    name="Assistant",
    tools=[fetch_weather, read_file],  # (4)!
)

for tool in agent.tools:
    if isinstance(tool, FunctionTool):
        print(tool.name)
        print(tool.description)
        print(json.dumps(tool.params_json_schema, indent=2))
        print()

```

1.  你的函数参数可以使用任何 Python 类型，函数也可以是同步或异步。
2.  如果存在 docstring，会用于提取描述和参数描述
3.  函数可选择接收 `context`（必须是第一个参数）。你也可以设置覆盖项，例如工具名称、描述、使用哪种 docstring 风格等。
4.  你可以将装饰后的函数传入工具列表。

??? note "展开查看输出"

    ```
    fetch_weather
    Fetch the weather for a given location.
    {
    "$defs": {
      "Location": {
        "properties": {
          "lat": {
            "title": "Lat",
            "type": "number"
          },
          "long": {
            "title": "Long",
            "type": "number"
          }
        },
        "required": [
          "lat",
          "long"
        ],
        "title": "Location",
        "type": "object"
      }
    },
    "properties": {
      "location": {
        "$ref": "#/$defs/Location",
        "description": "The location to fetch the weather for."
      }
    },
    "required": [
      "location"
    ],
    "title": "fetch_weather_args",
    "type": "object"
    }

    fetch_data
    Read the contents of a file.
    {
    "properties": {
      "path": {
        "description": "The path to the file to read.",
        "title": "Path",
        "type": "string"
      },
      "directory": {
        "anyOf": [
          {
            "type": "string"
          },
          {
            "type": "null"
          }
        ],
        "default": null,
        "description": "The directory to read the file from.",
        "title": "Directory"
      }
    },
    "required": [
      "path"
    ],
    "title": "fetch_data_args",
    "type": "object"
    }
    ```

### 从工具调用返回图像或文件

除了返回文本输出外，你还可以将一个或多个图像或文件作为工具调用的输出返回。为此，你可以返回以下任意类型：

-   图像：[`ToolOutputImage`][agents.tool.ToolOutputImage]（或其 TypedDict 版本 [`ToolOutputImageDict`][agents.tool.ToolOutputImageDict]）
-   文件：[`ToolOutputFileContent`][agents.tool.ToolOutputFileContent]（或其 TypedDict 版本 [`ToolOutputFileContentDict`][agents.tool.ToolOutputFileContentDict]）
-   文本：字符串或可转为字符串的对象，或 [`ToolOutputText`][agents.tool.ToolOutputText]（或其 TypedDict 版本 [`ToolOutputTextDict`][agents.tool.ToolOutputTextDict]）

### 自定义工具调用

有时你并不想将 Python 函数作为工具。你也可以直接创建 [`FunctionTool`][agents.tool.FunctionTool]。你需要提供：

-   `name`
-   `description`
-   `params_json_schema`，即参数的 JSON schema
-   `on_invoke_tool`，即一个异步函数，接收 [`ToolContext`][agents.tool_context.ToolContext] 和 JSON 字符串形式的参数，并返回工具输出（例如文本、结构化工具输出对象或输出列表）。

```python
from typing import Any

from pydantic import BaseModel

from agents import RunContextWrapper, FunctionTool



def do_some_work(data: str) -> str:
    return "done"


class FunctionArgs(BaseModel):
    username: str
    age: int


async def run_function(ctx: RunContextWrapper[Any], args: str) -> str:
    parsed = FunctionArgs.model_validate_json(args)
    return do_some_work(data=f"{parsed.username} is {parsed.age} years old")


tool = FunctionTool(
    name="process_user",
    description="Processes extracted user data",
    params_json_schema=FunctionArgs.model_json_schema(),
    on_invoke_tool=run_function,
)
```

### 自动参数与 docstring 解析

如前所述，我们会自动解析函数签名以提取工具 schema，并解析 docstring 以提取工具和各参数的描述。说明如下：

1. 函数签名解析通过 `inspect` 模块完成。我们使用类型注解理解参数类型，并动态构建一个 Pydantic 模型来表示整体 schema。它支持大多数类型，包括 Python 基本类型、Pydantic 模型、TypedDict 等。
2. 我们使用 `griffe` 解析 docstring。支持的 docstring 格式包括 `google`、`sphinx` 和 `numpy`。我们会尝试自动检测 docstring 格式，但这是尽力而为；你也可以在调用 `function_tool` 时显式设置。你还可以通过将 `use_docstring_info` 设为 `False` 来禁用 docstring 解析。

schema 提取代码位于 [`agents.function_schema`][]。

### 使用 Pydantic Field 约束并描述参数

你可以使用 Pydantic 的 [`Field`](https://docs.pydantic.dev/latest/concepts/fields/) 为工具参数添加约束（例如数字最小/最大值、字符串长度或模式）和描述。与 Pydantic 一样，两种形式都支持：基于默认值（`arg: int = Field(..., ge=1)`）和 `Annotated`（`arg: Annotated[int, Field(..., ge=1)]`）。生成的 JSON schema 与校验将包含这些约束。

```python
from typing import Annotated
from pydantic import Field
from agents import function_tool

# Default-based form
@function_tool
def score_a(score: int = Field(..., ge=0, le=100, description="Score from 0 to 100")) -> str:
    return f"Score recorded: {score}"

# Annotated form
@function_tool
def score_b(score: Annotated[int, Field(..., ge=0, le=100, description="Score from 0 to 100")]) -> str:
    return f"Score recorded: {score}"
```

### 工具调用超时

你可以通过 `@function_tool(timeout=...)` 为异步工具调用设置单次调用超时。

```python
import asyncio
from agents import Agent, Runner, function_tool


@function_tool(timeout=2.0)
async def slow_lookup(query: str) -> str:
    await asyncio.sleep(10)
    return f"Result for {query}"


agent = Agent(
    name="Timeout demo",
    instructions="Use tools when helpful.",
    tools=[slow_lookup],
)
```

达到超时时，默认行为是 `timeout_behavior="error_as_result"`，会向模型发送可见的超时消息（例如 `Tool 'slow_lookup' timed out after 2 seconds.`）。

你可以控制超时处理方式：

-   `timeout_behavior="error_as_result"`（默认）：向模型返回超时消息，以便其恢复。
-   `timeout_behavior="raise_exception"`：抛出 [`ToolTimeoutError`][agents.exceptions.ToolTimeoutError] 并使运行失败。
-   `timeout_error_function=...`：在使用 `error_as_result` 时自定义超时消息。

```python
import asyncio
from agents import Agent, Runner, ToolTimeoutError, function_tool


@function_tool(timeout=1.5, timeout_behavior="raise_exception")
async def slow_tool() -> str:
    await asyncio.sleep(5)
    return "done"


agent = Agent(name="Timeout hard-fail", tools=[slow_tool])

try:
    await Runner.run(agent, "Run the tool")
except ToolTimeoutError as e:
    print(f"{e.tool_name} timed out in {e.timeout_seconds} seconds")
```

!!! note

    超时配置仅支持异步 `@function_tool` 处理器。

### 处理工具调用中的错误

当你通过 `@function_tool` 创建工具调用时，可以传入 `failure_error_function`。这是在工具调用崩溃时向 LLM 提供错误响应的函数。

-   默认情况下（即你不传任何值），会运行 `default_tool_error_function`，告知 LLM 发生了错误。
-   如果你传入自己的错误函数，则会改为运行该函数，并将其响应发送给 LLM。
-   如果你显式传入 `None`，则任何工具调用错误都会被重新抛出，由你处理。这可能是模型生成无效 JSON 导致的 `ModelBehaviorError`，也可能是代码崩溃导致的 `UserError` 等。

```python
from agents import function_tool, RunContextWrapper
from typing import Any

def my_custom_error_function(context: RunContextWrapper[Any], error: Exception) -> str:
    """A custom function to provide a user-friendly error message."""
    print(f"A tool call failed with the following error: {error}")
    return "An internal server error occurred. Please try again later."

@function_tool(failure_error_function=my_custom_error_function)
def get_user_profile(user_id: str) -> str:
    """Fetches a user profile from a mock API.
     This function demonstrates a 'flaky' or failing API call.
    """
    if user_id == "user_123":
        return "User profile for user_123 successfully retrieved."
    else:
        raise ValueError(f"Could not retrieve profile for user_id: {user_id}. API returned an error.")

```

如果你是手动创建 `FunctionTool` 对象，则必须在 `on_invoke_tool` 函数内部处理错误。

## Agents as tools

在某些工作流中，你可能希望由一个中心智能体进行智能体编排一个由专用智能体组成的网络，而不是移交控制权。你可以通过将智能体建模为工具来实现。

```python
from agents import Agent, Runner
import asyncio

spanish_agent = Agent(
    name="Spanish agent",
    instructions="You translate the user's message to Spanish",
)

french_agent = Agent(
    name="French agent",
    instructions="You translate the user's message to French",
)

orchestrator_agent = Agent(
    name="orchestrator_agent",
    instructions=(
        "You are a translation agent. You use the tools given to you to translate."
        "If asked for multiple translations, you call the relevant tools."
    ),
    tools=[
        spanish_agent.as_tool(
            tool_name="translate_to_spanish",
            tool_description="Translate the user's message to Spanish",
        ),
        french_agent.as_tool(
            tool_name="translate_to_french",
            tool_description="Translate the user's message to French",
        ),
    ],
)

async def main():
    result = await Runner.run(orchestrator_agent, input="Say 'Hello, how are you?' in Spanish.")
    print(result.final_output)
```

### 工具智能体自定义

`agent.as_tool` 函数是一个便捷方法，可轻松将智能体转换为工具。它支持常见运行时选项，如 `max_turns`、`run_config`、`hooks`、`previous_response_id`、`conversation_id`、`session` 和 `needs_approval`。它还支持通过 `parameters`、`input_builder` 和 `include_input_schema` 进行结构化输入。对于高级编排（例如条件重试、回退行为或串联多个智能体调用），请在你的工具实现中直接使用 `Runner.run`：

```python
@function_tool
async def run_my_agent() -> str:
    """A tool that runs the agent with custom configs"""

    agent = Agent(name="My agent", instructions="...")

    result = await Runner.run(
        agent,
        input="...",
        max_turns=5,
        run_config=...
    )

    return str(result.final_output)
```

### 工具智能体的结构化输入

默认情况下，`Agent.as_tool()` 期望单个字符串输入（`{"input": "..."}`），但你可以通过传入 `parameters`（Pydantic 模型或 dataclass 类型）来暴露结构化 schema。

附加选项：

- `include_input_schema=True` 会在生成的嵌套输入中包含完整 JSON Schema。
- `input_builder=...` 允许你完全自定义结构化工具参数如何转换为嵌套智能体输入。
- `RunContextWrapper.tool_input` 包含嵌套运行上下文中已解析的结构化载荷。

```python
from pydantic import BaseModel, Field


class TranslationInput(BaseModel):
    text: str = Field(description="Text to translate.")
    source: str = Field(description="Source language.")
    target: str = Field(description="Target language.")


translator_tool = translator_agent.as_tool(
    tool_name="translate_text",
    tool_description="Translate text between languages.",
    parameters=TranslationInput,
    include_input_schema=True,
)
```

完整可运行示例见 `examples/agent_patterns/agents_as_tools_structured.py`。

### 工具智能体的审批关卡

`Agent.as_tool(..., needs_approval=...)` 使用与 `function_tool` 相同的审批流程。如果需要审批，运行会暂停，待处理项会出现在 `result.interruptions` 中；然后使用 `result.to_state()`，并在调用 `state.approve(...)` 或 `state.reject(...)` 后恢复。完整暂停/恢复模式见[Human-in-the-loop 指南](human_in_the_loop.md)。

### 自定义输出提取

在某些情况下，你可能希望在将工具智能体输出返回给中心智能体之前进行修改。这在以下场景中很有用：

-   从子智能体聊天历史中提取特定信息（例如 JSON 载荷）。
-   转换或重格式化智能体最终答案（例如将 Markdown 转为纯文本或 CSV）。
-   当智能体响应缺失或格式错误时，校验输出或提供回退值。

你可以通过向 `as_tool` 方法提供 `custom_output_extractor` 参数来实现：

```python
async def extract_json_payload(run_result: RunResult) -> str:
    # Scan the agent’s outputs in reverse order until we find a JSON-like message from a tool call.
    for item in reversed(run_result.new_items):
        if isinstance(item, ToolCallOutputItem) and item.output.strip().startswith("{"):
            return item.output.strip()
    # Fallback to an empty JSON object if nothing was found
    return "{}"


json_tool = data_agent.as_tool(
    tool_name="get_data_json",
    tool_description="Run the data agent and return only its JSON payload",
    custom_output_extractor=extract_json_payload,
)
```

在自定义提取器中，嵌套的 [`RunResult`][agents.result.RunResult] 还会暴露
[`agent_tool_invocation`][agents.result.RunResultBase.agent_tool_invocation]，当你在后处理嵌套结果时需要外层工具名称、调用 ID 或原始参数时，这很有用。
参见[结果指南](results.md#agent-as-tool-metadata)。

### 流式传输嵌套智能体运行

向 `as_tool` 传入 `on_stream` 回调，以监听嵌套智能体发出的流式事件，同时在流结束后仍返回其最终输出。

```python
from agents import AgentToolStreamEvent


async def handle_stream(event: AgentToolStreamEvent) -> None:
    # Inspect the underlying StreamEvent along with agent metadata.
    print(f"[stream] {event['agent'].name} :: {event['event'].type}")


billing_agent_tool = billing_agent.as_tool(
    tool_name="billing_helper",
    tool_description="Answer billing questions.",
    on_stream=handle_stream,  # Can be sync or async.
)
```

预期行为：

- 事件类型与 `StreamEvent["type"]` 一致：`raw_response_event`、`run_item_stream_event`、`agent_updated_stream_event`。
- 提供 `on_stream` 会自动以流式模式运行嵌套智能体，并在返回最终输出前消费完整个流。
- 处理器可以是同步或异步；每个事件会按到达顺序传递。
- 当工具通过模型工具调用触发时会有 `tool_call`；直接调用时它可能为 `None`。
- 完整可运行示例见 `examples/agent_patterns/agents_as_tools_streaming.py`。

### 条件工具启用

你可以使用 `is_enabled` 参数在运行时有条件地启用或禁用智能体工具。这使你能够基于上下文、用户偏好或运行时条件，动态筛选哪些工具可供 LLM 使用。

```python
import asyncio
from agents import Agent, AgentBase, Runner, RunContextWrapper
from pydantic import BaseModel

class LanguageContext(BaseModel):
    language_preference: str = "french_spanish"

def french_enabled(ctx: RunContextWrapper[LanguageContext], agent: AgentBase) -> bool:
    """Enable French for French+Spanish preference."""
    return ctx.context.language_preference == "french_spanish"

# Create specialized agents
spanish_agent = Agent(
    name="spanish_agent",
    instructions="You respond in Spanish. Always reply to the user's question in Spanish.",
)

french_agent = Agent(
    name="french_agent",
    instructions="You respond in French. Always reply to the user's question in French.",
)

# Create orchestrator with conditional tools
orchestrator = Agent(
    name="orchestrator",
    instructions=(
        "You are a multilingual assistant. You use the tools given to you to respond to users. "
        "You must call ALL available tools to provide responses in different languages. "
        "You never respond in languages yourself, you always use the provided tools."
    ),
    tools=[
        spanish_agent.as_tool(
            tool_name="respond_spanish",
            tool_description="Respond to the user's question in Spanish",
            is_enabled=True,  # Always enabled
        ),
        french_agent.as_tool(
            tool_name="respond_french",
            tool_description="Respond to the user's question in French",
            is_enabled=french_enabled,
        ),
    ],
)

async def main():
    context = RunContextWrapper(LanguageContext(language_preference="french_spanish"))
    result = await Runner.run(orchestrator, "How are you?", context=context.context)
    print(result.final_output)

asyncio.run(main())
```

`is_enabled` 参数接受：

-   **布尔值**：`True`（始终启用）或 `False`（始终禁用）
-   **可调用函数**：接收 `(context, agent)` 并返回布尔值的函数
-   **异步函数**：用于复杂条件逻辑的异步函数

被禁用的工具在运行时会对 LLM 完全隐藏，这在以下场景中很有用：

-   基于用户权限的功能门控
-   特定环境的工具可用性（开发 vs 生产）
-   不同工具配置的 A/B 测试
-   基于运行时状态的动态工具过滤

## 实验性：Codex 工具

`codex_tool` 封装了 Codex CLI，使智能体能够在工具调用期间运行工作区范围任务（shell、文件编辑、MCP 工具）。此接口为实验性功能，未来可能变化。

当你希望主智能体在不离开当前运行的情况下，将一个有边界的工作区任务委托给 Codex 时可使用它。默认工具名为 `codex`。如果设置自定义名称，必须是 `codex` 或以 `codex_` 开头。当一个智能体包含多个 Codex 工具时，每个工具都必须使用唯一名称。

```python
from agents import Agent
from agents.extensions.experimental.codex import ThreadOptions, TurnOptions, codex_tool

agent = Agent(
    name="Codex Agent",
    instructions="Use the codex tool to inspect the workspace and answer the question.",
    tools=[
        codex_tool(
            sandbox_mode="workspace-write",
            working_directory="/path/to/repo",
            default_thread_options=ThreadOptions(
                model="gpt-5.2-codex",
                model_reasoning_effort="low",
                network_access_enabled=True,
                web_search_mode="disabled",
                approval_policy="never",
            ),
            default_turn_options=TurnOptions(
                idle_timeout_seconds=60,
            ),
            persist_session=True,
        )
    ],
)
```

从以下选项组开始：

-   执行范围：`sandbox_mode` 和 `working_directory` 定义 Codex 可操作的位置。请配套使用；当工作目录不在 Git 仓库内时，设置 `skip_git_repo_check=True`。
-   线程默认值：`default_thread_options=ThreadOptions(...)` 配置模型、推理强度、审批策略、附加目录、网络访问和网络检索模式。优先使用 `web_search_mode`，而不是旧版 `web_search_enabled`。
-   轮次默认值：`default_turn_options=TurnOptions(...)` 配置每轮行为，例如 `idle_timeout_seconds` 和可选取消 `signal`。
-   工具 I/O：工具调用必须至少包含一个 `inputs` 项，格式为 `{ "type": "text", "text": ... }` 或 `{ "type": "local_image", "path": ... }`。`output_schema` 可用于要求 Codex 返回结构化响应。

线程复用与持久化是分开的控制项：

-   `persist_session=True` 会在对同一工具实例的重复调用中复用一个 Codex 线程。
-   `use_run_context_thread_id=True` 会在共享同一可变上下文对象的跨运行中，将线程 ID 存储并复用在运行上下文中。
-   线程 ID 优先级为：每次调用的 `thread_id`，然后是运行上下文线程 ID（若启用），最后是配置的 `thread_id` 选项。
-   默认运行上下文键：当 `name="codex"` 时为 `codex_thread_id`，当 `name="codex_<suffix>"` 时为 `codex_thread_id_<suffix>`。可通过 `run_context_thread_id_key` 覆盖。

运行时配置：

-   认证：设置 `CODEX_API_KEY`（推荐）或 `OPENAI_API_KEY`，或传入 `codex_options={"api_key": "..."}`。
-   运行时：`codex_options.base_url` 会覆盖 CLI 基础 URL。
-   二进制解析：设置 `codex_options.codex_path_override`（或 `CODEX_PATH`）以固定 CLI 路径。否则 SDK 会先从 `PATH` 解析 `codex`，再回退到内置 vendor 二进制文件。
-   环境：`codex_options.env` 完整控制子进程环境。提供后，子进程不会继承 `os.environ`。
-   流限制：`codex_options.codex_subprocess_stream_limit_bytes`（或 `OPENAI_AGENTS_CODEX_SUBPROCESS_STREAM_LIMIT_BYTES`）控制 stdout/stderr 读取器限制。有效范围是 `65536` 到 `67108864`；默认是 `8388608`。
-   流式传输：`on_stream` 接收线程/轮次生命周期事件和条目事件（`reasoning`、`command_execution`、`mcp_tool_call`、`file_change`、`web_search`、`todo_list` 以及 `error` 条目更新）。
-   输出：结果包含 `response`、`usage` 和 `thread_id`；usage 会加入 `RunContextWrapper.usage`。

参考：

-   [Codex 工具 API 参考](ref/extensions/experimental/codex/codex_tool.md)
-   [ThreadOptions 参考](ref/extensions/experimental/codex/thread_options.md)
-   [TurnOptions 参考](ref/extensions/experimental/codex/turn_options.md)
-   完整可运行示例见 `examples/tools/codex.py` 和 `examples/tools/codex_same_thread.py`。

================
File: docs/zh/tracing.md
================
---
search:
  exclude: true
---
# 追踪

Agents SDK 内置了追踪功能，可收集智能体运行期间事件的完整记录：LLM 生成、工具调用、任务转移、安全防护措施，甚至包括发生的自定义事件。通过使用[追踪仪表盘](https://platform.openai.com/traces)，你可以在开发和生产环境中调试、可视化并监控工作流。

!!!note

    追踪默认启用。你可以通过以下三种常见方式将其禁用：

    1. 你可以通过设置环境变量 `OPENAI_AGENTS_DISABLE_TRACING=1` 全局禁用追踪
    2. 你可以在代码中通过 [`set_tracing_disabled(True)`][agents.set_tracing_disabled] 全局禁用追踪
    3. 你可以通过将 [`agents.run.RunConfig.tracing_disabled`][] 设为 `True` 来为单次运行禁用追踪

***对于在使用 OpenAI API 时采用零数据保留（ZDR）策略的组织，追踪功能不可用。***

## 追踪与跨度

-   **追踪**表示“工作流”的一次端到端操作。它由多个跨度组成。追踪具有以下属性：
    -   `workflow_name`：逻辑工作流或应用。例如“代码生成”或“客户服务”。
    -   `trace_id`：追踪的唯一 ID。如果你未传入则会自动生成。格式必须为 `trace_<32_alphanumeric>`。
    -   `group_id`：可选分组 ID，用于关联同一会话中的多个追踪。例如，你可以使用聊天线程 ID。
    -   `disabled`：若为 True，则不会记录该追踪。
    -   `metadata`：追踪的可选元数据。
-   **跨度**表示具有开始和结束时间的操作。跨度具有：
    -   `started_at` 和 `ended_at` 时间戳。
    -   `trace_id`，表示其所属追踪
    -   `parent_id`，指向该跨度的父跨度（如有）
    -   `span_data`，即跨度信息。例如，`AgentSpanData` 包含智能体信息，`GenerationSpanData` 包含 LLM 生成信息，等等。

## 默认追踪

默认情况下，SDK 会追踪以下内容：

-   整个 `Runner.{run, run_sync, run_streamed}()` 会被包装在 `trace()` 中。
-   每次智能体运行时，都会包装在 `agent_span()` 中
-   LLM 生成会包装在 `generation_span()` 中
-   每次函数工具调用都会分别包装在 `function_span()` 中
-   安全防护措施会包装在 `guardrail_span()` 中
-   任务转移会包装在 `handoff_span()` 中
-   音频输入（语音转文本）会包装在 `transcription_span()` 中
-   音频输出（文本转语音）会包装在 `speech_span()` 中
-   相关音频跨度可能会作为 `speech_group_span()` 的子级

默认情况下，追踪名称为“Agent workflow”。如果你使用 `trace`，可以设置此名称；你也可以通过 [`RunConfig`][agents.run.RunConfig] 配置名称和其他属性。

此外，你还可以设置[自定义追踪处理器](#custom-tracing-processors)，将追踪推送到其他目标（作为替代目标或次要目标）。

## 更高层级追踪

有时，你可能希望多次调用 `run()` 都属于同一条追踪。你可以通过将整段代码包裹在 `trace()` 中来实现。

```python
from agents import Agent, Runner, trace

async def main():
    agent = Agent(name="Joke generator", instructions="Tell funny jokes.")

    with trace("Joke workflow"): # (1)!
        first_result = await Runner.run(agent, "Tell me a joke")
        second_result = await Runner.run(agent, f"Rate this joke: {first_result.final_output}")
        print(f"Joke: {first_result.final_output}")
        print(f"Rating: {second_result.final_output}")
```

1. 由于对 `Runner.run` 的两次调用都被包裹在 `with trace()` 中，因此这些单独运行会成为整体追踪的一部分，而不是创建两条追踪。

## 创建追踪

你可以使用 [`trace()`][agents.tracing.trace] 函数创建追踪。追踪需要被启动和结束。你有两种方式：

1. **推荐**：将 trace 用作上下文管理器，即 `with trace(...) as my_trace`。这样会在正确时间自动启动并结束追踪。
2. 你也可以手动调用 [`trace.start()`][agents.tracing.Trace.start] 和 [`trace.finish()`][agents.tracing.Trace.finish]。

当前追踪通过 Python 的 [`contextvar`](https://docs.python.org/3/library/contextvars.html) 跟踪。这意味着它可自动适配并发。如果你手动启动/结束追踪，则需要向 `start()`/`finish()` 传递 `mark_as_current` 和 `reset_current` 来更新当前追踪。

## 创建跨度

你可以使用各种 [`*_span()`][agents.tracing.create] 方法创建跨度。通常你无需手动创建跨度。可使用 [`custom_span()`][agents.tracing.custom_span] 函数来追踪自定义跨度信息。

跨度会自动归属于当前追踪，并嵌套在最近的当前跨度下；这通过 Python 的 [`contextvar`](https://docs.python.org/3/library/contextvars.html) 进行跟踪。

## 敏感数据

某些跨度可能会捕获潜在敏感数据。

`generation_span()` 会存储 LLM 生成的输入/输出，`function_span()` 会存储函数调用的输入/输出。这些内容可能包含敏感数据，因此你可以通过 [`RunConfig.trace_include_sensitive_data`][agents.run.RunConfig.trace_include_sensitive_data] 禁用这类数据的捕获。

类似地，音频跨度默认包含输入和输出音频的 base64 编码 PCM 数据。你可以通过配置 [`VoicePipelineConfig.trace_include_sensitive_audio_data`][agents.voice.pipeline_config.VoicePipelineConfig.trace_include_sensitive_audio_data] 禁用该音频数据的捕获。

默认情况下，`trace_include_sensitive_data` 为 `True`。你也可以在不改代码的情况下，在运行应用前导出 `OPENAI_AGENTS_TRACE_INCLUDE_SENSITIVE_DATA` 环境变量并设为 `true/1` 或 `false/0` 来设置默认值。

## 自定义追踪处理器

追踪的高层架构如下：

-   在初始化时，我们会创建一个全局 [`TraceProvider`][agents.tracing.setup.TraceProvider]，负责创建追踪。
-   我们会为 `TraceProvider` 配置一个 [`BatchTraceProcessor`][agents.tracing.processors.BatchTraceProcessor]，它会将追踪/跨度按批次发送到 [`BackendSpanExporter`][agents.tracing.processors.BackendSpanExporter]，后者会将跨度和追踪按批次导出到 OpenAI 后端。

要自定义这套默认配置，以将追踪发送到替代或额外后端，或修改导出器行为，你有两个选项：

1. [`add_trace_processor()`][agents.tracing.add_trace_processor] 允许你添加一个**额外**的追踪处理器，它会在追踪和跨度就绪时接收数据。这样你可以在将追踪发送到 OpenAI 后端之外执行自己的处理。
2. [`set_trace_processors()`][agents.tracing.set_trace_processors] 允许你用自己的追踪处理器**替换**默认处理器。这意味着除非你包含一个执行该操作的 `TracingProcessor`，否则追踪不会发送到 OpenAI 后端。


## 使用非 OpenAI 模型进行追踪

你可以将 OpenAI API 密钥与非 OpenAI 模型一起使用，以在 OpenAI 追踪仪表盘中启用免费追踪，而无需禁用追踪。

```python
import os
from agents import set_tracing_export_api_key, Agent, Runner
from agents.extensions.models.litellm_model import LitellmModel

tracing_api_key = os.environ["OPENAI_API_KEY"]
set_tracing_export_api_key(tracing_api_key)

model = LitellmModel(
    model="your-model-name",
    api_key="your-api-key",
)

agent = Agent(
    name="Assistant",
    model=model,
)
```

如果你只需要为单次运行使用不同的追踪密钥，请通过 `RunConfig` 传入，而不是更改全局导出器。

```python
from agents import Runner, RunConfig

await Runner.run(
    agent,
    input="Hello",
    run_config=RunConfig(tracing={"api_key": "sk-tracing-123"}),
)
```

## 附加说明
- 在 Openai 追踪仪表盘查看免费追踪。


## 生态系统集成

以下社区和供应商集成支持 OpenAI Agents SDK 的追踪能力。

### 外部追踪处理器列表

-   [Weights & Biases](https://weave-docs.wandb.ai/guides/integrations/openai_agents)
-   [Arize-Phoenix](https://docs.arize.com/phoenix/tracing/integrations-tracing/openai-agents-sdk)
-   [Future AGI](https://docs.futureagi.com/future-agi/products/observability/auto-instrumentation/openai_agents)
-   [MLflow（自托管/开源）](https://mlflow.org/docs/latest/tracing/integrations/openai-agent)
-   [MLflow（Databricks 托管）](https://docs.databricks.com/aws/en/mlflow/mlflow-tracing#-automatic-tracing)
-   [Braintrust](https://braintrust.dev/docs/guides/traces/integrations#openai-agents-sdk)
-   [Pydantic Logfire](https://logfire.pydantic.dev/docs/integrations/llms/openai/#openai-agents)
-   [AgentOps](https://docs.agentops.ai/v1/integrations/agentssdk)
-   [Scorecard](https://docs.scorecard.io/docs/documentation/features/tracing#openai-agents-sdk-integration)
-   [Keywords AI](https://docs.keywordsai.co/integration/development-frameworks/openai-agent)
-   [LangSmith](https://docs.smith.langchain.com/observability/how_to_guides/trace_with_openai_agents_sdk)
-   [Maxim AI](https://www.getmaxim.ai/docs/observe/integrations/openai-agents-sdk)
-   [Comet Opik](https://www.comet.com/docs/opik/tracing/integrations/openai_agents)
-   [Langfuse](https://langfuse.com/docs/integrations/openaiagentssdk/openai-agents)
-   [Langtrace](https://docs.langtrace.ai/supported-integrations/llm-frameworks/openai-agents-sdk)
-   [Okahu-Monocle](https://github.com/monocle2ai/monocle)
-   [Galileo](https://v2docs.galileo.ai/integrations/openai-agent-integration#openai-agent-integration)
-   [Portkey AI](https://portkey.ai/docs/integrations/agents/openai-agents)
-   [LangDB AI](https://docs.langdb.ai/getting-started/working-with-agent-frameworks/working-with-openai-agents-sdk)
-   [Agenta](https://docs.agenta.ai/observability/integrations/openai-agents)
-   [PostHog](https://posthog.com/docs/llm-analytics/installation/openai-agents)
-   [Traccia](https://traccia.ai/docs/integrations/openai-agents)

================
File: docs/zh/usage.md
================
---
search:
  exclude: true
---
# 用法

Agents SDK 会自动跟踪每次运行的 token 使用情况。你可以从运行上下文中访问它，并用它来监控成本、强制限制或记录分析数据。

## 跟踪内容

- **requests**: 发起的 LLM API 调用次数
- **input_tokens**: 发送的输入 token 总数
- **output_tokens**: 接收的输出 token 总数
- **total_tokens**: 输入 + 输出
- **request_usage_entries**: 按请求划分的使用情况明细列表
- **details**:
  - `input_tokens_details.cached_tokens`
  - `output_tokens_details.reasoning_tokens`

## 从运行中访问 usage

在 `Runner.run(...)` 之后，通过 `result.context_wrapper.usage` 访问 usage。

```python
result = await Runner.run(agent, "What's the weather in Tokyo?")
usage = result.context_wrapper.usage

print("Requests:", usage.requests)
print("Input tokens:", usage.input_tokens)
print("Output tokens:", usage.output_tokens)
print("Total tokens:", usage.total_tokens)
```

usage 会聚合该次运行期间的所有模型调用（包括工具调用和任务转移）。

### 使用 LiteLLM 模型启用 usage

LiteLLM 提供方默认不会上报 usage 指标。使用 [`LitellmModel`](models/litellm.md) 时，请向你的智能体传入 `ModelSettings(include_usage=True)`，这样 LiteLLM 的响应才会填充 `result.context_wrapper.usage`。

```python
from agents import Agent, ModelSettings, Runner
from agents.extensions.models.litellm_model import LitellmModel

agent = Agent(
    name="Assistant",
    model=LitellmModel(model="your/model", api_key="..."),
    model_settings=ModelSettings(include_usage=True),
)

result = await Runner.run(agent, "What's the weather in Tokyo?")
print(result.context_wrapper.usage.total_tokens)
```

## 按请求 usage 跟踪

SDK 会自动在 `request_usage_entries` 中跟踪每个 API 请求的 usage，这对于精细化成本计算和监控上下文窗口消耗非常有用。

```python
result = await Runner.run(agent, "What's the weather in Tokyo?")

for i, request in enumerate(result.context_wrapper.usage.request_usage_entries):
    print(f"Request {i + 1}: {request.input_tokens} in, {request.output_tokens} out")
```

## 在会话中访问 usage

当你使用 `Session`（例如 `SQLiteSession`）时，每次调用 `Runner.run(...)` 都会返回该次运行的 usage。会话会为上下文维护对话历史，但每次运行的 usage 是独立的。

```python
session = SQLiteSession("my_conversation")

first = await Runner.run(agent, "Hi!", session=session)
print(first.context_wrapper.usage.total_tokens)  # Usage for first run

second = await Runner.run(agent, "Can you elaborate?", session=session)
print(second.context_wrapper.usage.total_tokens)  # Usage for second run
```

请注意，虽然会话会在多次运行之间保留对话上下文，但每次 `Runner.run()` 调用返回的 usage 指标仅代表该次执行。在会话中，之前的消息可能会在每次运行时作为输入再次提供，这会影响后续轮次的输入 token 计数。

## 在 hooks 中使用 usage

如果你在使用 `RunHooks`，传递给每个 hook 的 `context` 对象都包含 `usage`。这让你可以在关键生命周期节点记录 usage。

```python
class MyHooks(RunHooks):
    async def on_agent_end(self, context: RunContextWrapper, agent: Agent, output: Any) -> None:
        u = context.usage
        print(f"{agent.name} → {u.requests} requests, {u.total_tokens} total tokens")
```

## API 参考

详细 API 文档请参阅：

-   [`Usage`][agents.usage.Usage] - usage 跟踪数据结构
-   [`RequestUsage`][agents.usage.RequestUsage] - 按请求划分的 usage 详情
-   [`RunContextWrapper`][agents.run.RunContextWrapper] - 从运行上下文访问 usage
-   [`RunHooks`][agents.run.RunHooks] - 挂接 usage 跟踪生命周期

================
File: docs/zh/visualization.md
================
---
search:
  exclude: true
---
# 智能体可视化

智能体可视化允许你使用 **Graphviz** 生成智能体及其关系的结构化图形表示。这有助于理解智能体、工具调用和任务转移在应用中的交互方式。

## 安装

安装可选的 `viz` 依赖组：

```bash
pip install "openai-agents[viz]"
```

## 生成图

你可以使用 `draw_graph` 函数生成智能体可视化。该函数会创建一个有向图，其中：

- **智能体** 以黄色方框表示。
- **MCP 服务** 以灰色方框表示。
- **工具调用** 以绿色椭圆表示。
- **任务转移** 是从一个智能体指向另一个智能体的有向边。

### 使用示例

```python
import os

from agents import Agent, function_tool
from agents.mcp.server import MCPServerStdio
from agents.extensions.visualization import draw_graph

@function_tool
def get_weather(city: str) -> str:
    return f"The weather in {city} is sunny."

spanish_agent = Agent(
    name="Spanish agent",
    instructions="You only speak Spanish.",
)

english_agent = Agent(
    name="English agent",
    instructions="You only speak English",
)

current_dir = os.path.dirname(os.path.abspath(__file__))
samples_dir = os.path.join(current_dir, "sample_files")
mcp_server = MCPServerStdio(
    name="Filesystem Server, via npx",
    params={
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-filesystem", samples_dir],
    },
)

triage_agent = Agent(
    name="Triage agent",
    instructions="Handoff to the appropriate agent based on the language of the request.",
    handoffs=[spanish_agent, english_agent],
    tools=[get_weather],
    mcp_servers=[mcp_server],
)

draw_graph(triage_agent)
```

![Agent Graph](../assets/images/graph.png)

这会生成一张图，直观展示**分诊智能体**及其与子智能体和工具的连接关系。


## 理解可视化

生成的图包括：

- 一个 **起始节点**（`__start__`），表示入口点。
- 以黄色填充的**矩形**表示的智能体。
- 以绿色填充的**椭圆**表示的工具。
- 以灰色填充的**矩形**表示的 MCP 服务。
- 表示交互的有向边：
  - 智能体到智能体任务转移使用**实线箭头**。
  - 工具调用使用**点线箭头**。
  - MCP 服务调用使用**虚线箭头**。
- 一个 **结束节点**（`__end__`），表示执行终止的位置。

**注意：** MCP 服务会在较新版本的
`agents` 包中渲染（已在 **v0.2.8** 验证）。如果你在可视化中看不到 MCP 方框，
请升级到最新版本。

## 自定义图

### 显示图
默认情况下，`draw_graph` 会以内联方式显示图。若要在单独窗口中显示图，请写入以下内容：

```python
draw_graph(triage_agent).view()
```

### 保存图
默认情况下，`draw_graph` 会以内联方式显示图。若要将其保存为文件，请指定文件名：

```python
draw_graph(triage_agent, filename="agent_graph")
```

这会在工作目录中生成 `agent_graph.png`。

================
File: docs/agents.md
================
# Agents

Agents are the core building block in your apps. An agent is a large language model (LLM) configured with instructions, tools, and optional runtime behavior such as handoffs, guardrails, and structured outputs.

Use this page when you want to define or customize a single agent. If you are deciding how multiple agents should collaborate, read [Agent orchestration](multi_agent.md).

## Choose the next guide

Use this page as the hub for agent definition. Jump to the adjacent guide that matches the next decision you need to make.

| If you want to... | Read next |
| --- | --- |
| Choose a model or provider setup | [Models](models/index.md) |
| Add capabilities to the agent | [Tools](tools.md) |
| Decide between manager-style orchestration and handoffs | [Agent orchestration](multi_agent.md) |
| Configure handoff behavior | [Handoffs](handoffs.md) |
| Run turns, stream events, or manage conversation state | [Running agents](running_agents.md) |
| Inspect final output, run items, or resumable state | [Results](results.md) |
| Share local dependencies and runtime state | [Context management](context.md) |

## Basic configuration

The most common properties of an agent are:

| Property | Required | Description |
| --- | --- | --- |
| `name` | yes | Human-readable agent name. |
| `instructions` | yes | System prompt or dynamic instructions callback. See [Dynamic instructions](#dynamic-instructions). |
| `prompt` | no | OpenAI Responses API prompt configuration. Accepts a static prompt object or a function. See [Prompt templates](#prompt-templates). |
| `handoff_description` | no | Short description exposed when this agent is offered as a handoff target. |
| `handoffs` | no | Delegate the conversation to specialist agents. See [handoffs](handoffs.md). |
| `model` | no | Which LLM to use. See [Models](models/index.md). |
| `model_settings` | no | Model tuning parameters such as `temperature`, `top_p`, and `tool_choice`. |
| `tools` | no | Tools the agent can call. See [Tools](tools.md). |
| `mcp_servers` | no | MCP-backed tools for the agent. See the [MCP guide](mcp.md). |
| `input_guardrails` | no | Guardrails that run on the first user input for this agent chain. See [Guardrails](guardrails.md). |
| `output_guardrails` | no | Guardrails that run on the final output for this agent. See [Guardrails](guardrails.md). |
| `output_type` | no | Structured output type instead of plain text. See [Output types](#output-types). |
| `tool_use_behavior` | no | Control whether tool results loop back to the model or end the run. See [Tool use behavior](#tool-use-behavior). |
| `reset_tool_choice` | no | Reset `tool_choice` after a tool call (default: `True`) to avoid tool-use loops. See [Forcing tool use](#forcing-tool-use). |

```python
from agents import Agent, ModelSettings, function_tool

@function_tool
def get_weather(city: str) -> str:
    """returns weather info for the specified city."""
    return f"The weather in {city} is sunny"

agent = Agent(
    name="Haiku agent",
    instructions="Always respond in haiku form",
    model="gpt-5-nano",
    tools=[get_weather],
)
```

## Prompt templates

You can reference a prompt template created in the OpenAI platform by setting `prompt`. This works with OpenAI models using the Responses API.

To use it, please:

1. Go to https://platform.openai.com/playground/prompts
2. Create a new prompt variable, `poem_style`.
3. Create a system prompt with the content:

    ```
    Write a poem in {{poem_style}}
    ```

4. Run the example with the `--prompt-id` flag.

```python
from agents import Agent

agent = Agent(
    name="Prompted assistant",
    prompt={
        "id": "pmpt_123",
        "version": "1",
        "variables": {"poem_style": "haiku"},
    },
)
```

You can also generate the prompt dynamically at run time:

```python
from dataclasses import dataclass

from agents import Agent, GenerateDynamicPromptData, Runner

@dataclass
class PromptContext:
    prompt_id: str
    poem_style: str


async def build_prompt(data: GenerateDynamicPromptData):
    ctx: PromptContext = data.context.context
    return {
        "id": ctx.prompt_id,
        "version": "1",
        "variables": {"poem_style": ctx.poem_style},
    }


agent = Agent(name="Prompted assistant", prompt=build_prompt)
result = await Runner.run(
    agent,
    "Say hello",
    context=PromptContext(prompt_id="pmpt_123", poem_style="limerick"),
)
```

## Context

Agents are generic on their `context` type. Context is a dependency-injection tool: it's an object you create and pass to `Runner.run()`, that is passed to every agent, tool, handoff etc, and it serves as a grab bag of dependencies and state for the agent run. You can provide any Python object as the context.

Read the [context guide](context.md) for the full `RunContextWrapper` surface, shared usage tracking, nested `tool_input`, and serialization caveats.

```python
@dataclass
class UserContext:
    name: str
    uid: str
    is_pro_user: bool

    async def fetch_purchases() -> list[Purchase]:
        return ...

agent = Agent[UserContext](
    ...,
)
```

## Output types

By default, agents produce plain text (i.e. `str`) outputs. If you want the agent to produce a particular type of output, you can use the `output_type` parameter. A common choice is to use [Pydantic](https://docs.pydantic.dev/) objects, but we support any type that can be wrapped in a Pydantic [TypeAdapter](https://docs.pydantic.dev/latest/api/type_adapter/) - dataclasses, lists, TypedDict, etc.

```python
from pydantic import BaseModel
from agents import Agent


class CalendarEvent(BaseModel):
    name: str
    date: str
    participants: list[str]

agent = Agent(
    name="Calendar extractor",
    instructions="Extract calendar events from text",
    output_type=CalendarEvent,
)
```

!!! note

    When you pass an `output_type`, that tells the model to use [structured outputs](https://platform.openai.com/docs/guides/structured-outputs) instead of regular plain text responses.

## Multi-agent system design patterns

There are many ways to design multi‑agent systems, but we commonly see two broadly applicable patterns:

1. Manager (agents as tools): A central manager/orchestrator invokes specialized sub‑agents as tools and retains control of the conversation.
2. Handoffs: Peer agents hand off control to a specialized agent that takes over the conversation. This is decentralized.

See [our practical guide to building agents](https://cdn.openai.com/business-guides-and-resources/a-practical-guide-to-building-agents.pdf) for more details.

### Manager (agents as tools)

The `customer_facing_agent` handles all user interaction and invokes specialized sub‑agents exposed as tools. Read more in the [tools](tools.md#agents-as-tools) documentation.

```python
from agents import Agent

booking_agent = Agent(...)
refund_agent = Agent(...)

customer_facing_agent = Agent(
    name="Customer-facing agent",
    instructions=(
        "Handle all direct user communication. "
        "Call the relevant tools when specialized expertise is needed."
    ),
    tools=[
        booking_agent.as_tool(
            tool_name="booking_expert",
            tool_description="Handles booking questions and requests.",
        ),
        refund_agent.as_tool(
            tool_name="refund_expert",
            tool_description="Handles refund questions and requests.",
        )
    ],
)
```

### Handoffs

Handoffs are sub‑agents the agent can delegate to. When a handoff occurs, the delegated agent receives the conversation history and takes over the conversation. This pattern enables modular, specialized agents that excel at a single task. Read more in the [handoffs](handoffs.md) documentation.

```python
from agents import Agent

booking_agent = Agent(...)
refund_agent = Agent(...)

triage_agent = Agent(
    name="Triage agent",
    instructions=(
        "Help the user with their questions. "
        "If they ask about booking, hand off to the booking agent. "
        "If they ask about refunds, hand off to the refund agent."
    ),
    handoffs=[booking_agent, refund_agent],
)
```

## Dynamic instructions

In most cases, you can provide instructions when you create the agent. However, you can also provide dynamic instructions via a function. The function will receive the agent and context, and must return the prompt. Both regular and `async` functions are accepted.

```python
def dynamic_instructions(
    context: RunContextWrapper[UserContext], agent: Agent[UserContext]
) -> str:
    return f"The user's name is {context.context.name}. Help them with their questions."


agent = Agent[UserContext](
    name="Triage agent",
    instructions=dynamic_instructions,
)
```

## Lifecycle events (hooks)

Sometimes, you want to observe the lifecycle of an agent. For example, you may want to log events, pre-fetch data, or record usage when certain events occur.

There are two hook scopes:

-   [`RunHooks`][agents.lifecycle.RunHooks] observe the entire `Runner.run(...)` invocation, including handoffs to other agents.
-   [`AgentHooks`][agents.lifecycle.AgentHooks] are attached to a specific agent instance via `agent.hooks`.

The callback context also changes depending on the event:

-   Agent start/end hooks receive [`AgentHookContext`][agents.run_context.AgentHookContext], which wraps your original context and carries the shared run usage state.
-   LLM, tool, and handoff hooks receive [`RunContextWrapper`][agents.run_context.RunContextWrapper].

Typical hook timing:

-   `on_agent_start` / `on_agent_end`: when a specific agent begins or finishes producing a final output.
-   `on_llm_start` / `on_llm_end`: immediately around each model call.
-   `on_tool_start` / `on_tool_end`: around each local tool invocation.
-   `on_handoff`: when control moves from one agent to another.

Use `RunHooks` when you want a single observer for the whole workflow, and `AgentHooks` when one agent needs custom side effects.

```python
from agents import Agent, RunHooks, Runner


class LoggingHooks(RunHooks):
    async def on_agent_start(self, context, agent):
        print(f"Starting {agent.name}")

    async def on_llm_end(self, context, agent, response):
        print(f"{agent.name} produced {len(response.output)} output items")

    async def on_agent_end(self, context, agent, output):
        print(f"{agent.name} finished with usage: {context.usage}")


agent = Agent(name="Assistant", instructions="Be concise.")
result = await Runner.run(agent, "Explain quines", hooks=LoggingHooks())
print(result.final_output)
```

For the full callback surface, see the [Lifecycle API reference](ref/lifecycle.md).

## Guardrails

Guardrails allow you to run checks/validations on user input in parallel to the agent running, and on the agent's output once it is produced. For example, you could screen the user's input and agent's output for relevance. Read more in the [guardrails](guardrails.md) documentation.

## Cloning/copying agents

By using the `clone()` method on an agent, you can duplicate an Agent, and optionally change any properties you like.

```python
pirate_agent = Agent(
    name="Pirate",
    instructions="Write like a pirate",
    model="gpt-5.2",
)

robot_agent = pirate_agent.clone(
    name="Robot",
    instructions="Write like a robot",
)
```

## Forcing tool use

Supplying a list of tools doesn't always mean the LLM will use a tool. You can force tool use by setting [`ModelSettings.tool_choice`][agents.model_settings.ModelSettings.tool_choice]. Valid values are:

1. `auto`, which allows the LLM to decide whether or not to use a tool.
2. `required`, which requires the LLM to use a tool (but it can intelligently decide which tool).
3. `none`, which requires the LLM to _not_ use a tool.
4. Setting a specific string e.g. `my_tool`, which requires the LLM to use that specific tool.

```python
from agents import Agent, Runner, function_tool, ModelSettings

@function_tool
def get_weather(city: str) -> str:
    """Returns weather info for the specified city."""
    return f"The weather in {city} is sunny"

agent = Agent(
    name="Weather Agent",
    instructions="Retrieve weather details.",
    tools=[get_weather],
    model_settings=ModelSettings(tool_choice="get_weather")
)
```

## Tool use behavior

The `tool_use_behavior` parameter in the `Agent` configuration controls how tool outputs are handled:

- `"run_llm_again"`: The default. Tools are run, and the LLM processes the results to produce a final response.
- `"stop_on_first_tool"`: The output of the first tool call is used as the final response, without further LLM processing.

```python
from agents import Agent, Runner, function_tool, ModelSettings

@function_tool
def get_weather(city: str) -> str:
    """Returns weather info for the specified city."""
    return f"The weather in {city} is sunny"

agent = Agent(
    name="Weather Agent",
    instructions="Retrieve weather details.",
    tools=[get_weather],
    tool_use_behavior="stop_on_first_tool"
)
```

- `StopAtTools(stop_at_tool_names=[...])`: Stops if any specified tool is called, using its output as the final response.

```python
from agents import Agent, Runner, function_tool
from agents.agent import StopAtTools

@function_tool
def get_weather(city: str) -> str:
    """Returns weather info for the specified city."""
    return f"The weather in {city} is sunny"

@function_tool
def sum_numbers(a: int, b: int) -> int:
    """Adds two numbers."""
    return a + b

agent = Agent(
    name="Stop At Stock Agent",
    instructions="Get weather or sum numbers.",
    tools=[get_weather, sum_numbers],
    tool_use_behavior=StopAtTools(stop_at_tool_names=["get_weather"])
)
```

- `ToolsToFinalOutputFunction`: A custom function that processes tool results and decides whether to stop or continue with the LLM.

```python
from agents import Agent, Runner, function_tool, FunctionToolResult, RunContextWrapper
from agents.agent import ToolsToFinalOutputResult
from typing import List, Any

@function_tool
def get_weather(city: str) -> str:
    """Returns weather info for the specified city."""
    return f"The weather in {city} is sunny"

def custom_tool_handler(
    context: RunContextWrapper[Any],
    tool_results: List[FunctionToolResult]
) -> ToolsToFinalOutputResult:
    """Processes tool results to decide final output."""
    for result in tool_results:
        if result.output and "sunny" in result.output:
            return ToolsToFinalOutputResult(
                is_final_output=True,
                final_output=f"Final weather: {result.output}"
            )
    return ToolsToFinalOutputResult(
        is_final_output=False,
        final_output=None
    )

agent = Agent(
    name="Weather Agent",
    instructions="Retrieve weather details.",
    tools=[get_weather],
    tool_use_behavior=custom_tool_handler
)
```

!!! note

    To prevent infinite loops, the framework automatically resets `tool_choice` to "auto" after a tool call. This behavior is configurable via [`agent.reset_tool_choice`][agents.agent.Agent.reset_tool_choice]. The infinite loop is because tool results are sent to the LLM, which then generates another tool call because of `tool_choice`, ad infinitum.

================
File: docs/config.md
================
# Configuration

This page covers SDK-wide defaults that you usually set once during application startup, such as the default OpenAI key or client, the default OpenAI API shape, tracing export defaults, and logging behavior.

If you need to configure a specific agent or run instead, start with:

-   [Running agents](running_agents.md) for `RunConfig`, sessions, and conversation-state options.
-   [Models](models/index.md) for model selection and provider configuration.
-   [Tracing](tracing.md) for per-run tracing metadata and custom trace processors.

## API keys and clients

By default, the SDK uses the `OPENAI_API_KEY` environment variable for LLM requests and tracing. The key is resolved when the SDK first creates an OpenAI client (lazy initialization), so set the environment variable before your first model call. If you are unable to set that environment variable before your app starts, you can use the [set_default_openai_key()][agents.set_default_openai_key] function to set the key.

```python
from agents import set_default_openai_key

set_default_openai_key("sk-...")
```

Alternatively, you can also configure an OpenAI client to be used. By default, the SDK creates an `AsyncOpenAI` instance, using the API key from the environment variable or the default key set above. You can change this by using the [set_default_openai_client()][agents.set_default_openai_client] function.

```python
from openai import AsyncOpenAI
from agents import set_default_openai_client

custom_client = AsyncOpenAI(base_url="...", api_key="...")
set_default_openai_client(custom_client)
```

Finally, you can also customize the OpenAI API that is used. By default, we use the OpenAI Responses API. You can override this to use the Chat Completions API by using the [set_default_openai_api()][agents.set_default_openai_api] function.

```python
from agents import set_default_openai_api

set_default_openai_api("chat_completions")
```

## Tracing

Tracing is enabled by default. By default it uses the same OpenAI API key as your model requests from the section above (that is, the environment variable or the default key you set). You can specifically set the API key used for tracing by using the [`set_tracing_export_api_key`][agents.set_tracing_export_api_key] function.

```python
from agents import set_tracing_export_api_key

set_tracing_export_api_key("sk-...")
```

If you need to attribute traces to a specific organization or project when using the default exporter, set these environment variables before your app starts:

```bash
export OPENAI_ORG_ID="org_..."
export OPENAI_PROJECT_ID="proj_..."
```

You can also set a tracing API key per run without changing the global exporter.

```python
from agents import Runner, RunConfig

await Runner.run(
    agent,
    input="Hello",
    run_config=RunConfig(tracing={"api_key": "sk-tracing-123"}),
)
```

You can also disable tracing entirely by using the [`set_tracing_disabled()`][agents.set_tracing_disabled] function.

```python
from agents import set_tracing_disabled

set_tracing_disabled(True)
```

If you want to keep tracing enabled but exclude potentially sensitive inputs/outputs from trace payloads, set [`RunConfig.trace_include_sensitive_data`][agents.run.RunConfig.trace_include_sensitive_data] to `False`:

```python
from agents import Runner, RunConfig

await Runner.run(
    agent,
    input="Hello",
    run_config=RunConfig(trace_include_sensitive_data=False),
)
```

You can also change the default without code by setting this environment variable before your app starts:

```bash
export OPENAI_AGENTS_TRACE_INCLUDE_SENSITIVE_DATA=0
```

For full tracing controls, see the [tracing guide](tracing.md).

## Debug logging

The SDK defines two Python loggers (`openai.agents` and `openai.agents.tracing`) and does not attach handlers by default. Logs follow your application's Python logging configuration.

To enable verbose logging, use the [`enable_verbose_stdout_logging()`][agents.enable_verbose_stdout_logging] function.

```python
from agents import enable_verbose_stdout_logging

enable_verbose_stdout_logging()
```

Alternatively, you can customize the logs by adding handlers, filters, formatters, etc. You can read more in the [Python logging guide](https://docs.python.org/3/howto/logging.html).

```python
import logging

logger = logging.getLogger("openai.agents") # or openai.agents.tracing for the Tracing logger

# To make all logs show up
logger.setLevel(logging.DEBUG)
# To make info and above show up
logger.setLevel(logging.INFO)
# To make warning and above show up
logger.setLevel(logging.WARNING)
# etc

# You can customize this as needed, but this will output to `stderr` by default
logger.addHandler(logging.StreamHandler())
```

### Sensitive data in logs

Certain logs may contain sensitive data (for example, user data).

By default, the SDK does **not** log LLM inputs/outputs or tool inputs/outputs. These protections are controlled by:

```bash
OPENAI_AGENTS_DONT_LOG_MODEL_DATA=1
OPENAI_AGENTS_DONT_LOG_TOOL_DATA=1
```

If you need to include this data temporarily for debugging, set either variable to `0` (or `false`) before your app starts:

```bash
export OPENAI_AGENTS_DONT_LOG_MODEL_DATA=0
export OPENAI_AGENTS_DONT_LOG_TOOL_DATA=0
```

================
File: docs/context.md
================
# Context management

Context is an overloaded term. There are two main classes of context you might care about:

1. Context available locally to your code: this is data and dependencies you might need when tool functions run, during callbacks like `on_handoff`, in lifecycle hooks, etc.
2. Context available to LLMs: this is data the LLM sees when generating a response.

## Local context

This is represented via the [`RunContextWrapper`][agents.run_context.RunContextWrapper] class and the [`context`][agents.run_context.RunContextWrapper.context] property within it. The way this works is:

1. You create any Python object you want. A common pattern is to use a dataclass or a Pydantic object.
2. You pass that object to the various run methods (e.g. `Runner.run(..., context=whatever)`).
3. All your tool calls, lifecycle hooks etc will be passed a wrapper object, `RunContextWrapper[T]`, where `T` represents your context object type which you can access via `wrapper.context`.

The **most important** thing to be aware of: every agent, tool function, lifecycle etc for a given agent run must use the same _type_ of context.

You can use the context for things like:

-   Contextual data for your run (e.g. things like a username/uid or other information about the user)
-   Dependencies (e.g. logger objects, data fetchers, etc)
-   Helper functions

!!! danger "Note"

    The context object is **not** sent to the LLM. It is purely a local object that you can read from, write to and call methods on it.

Within a single run, derived wrappers share the same underlying app context, approval state, and usage tracking. Nested [`Agent.as_tool()`][agents.agent.Agent.as_tool] runs may attach a different `tool_input`, but they do not get an isolated copy of your app state by default.

### What `RunContextWrapper` exposes

[`RunContextWrapper`][agents.run_context.RunContextWrapper] is a wrapper around your app-defined context object. In practice you will most often use:

-   [`wrapper.context`][agents.run_context.RunContextWrapper.context] for your own mutable app state and dependencies.
-   [`wrapper.usage`][agents.run_context.RunContextWrapper.usage] for aggregated request and token usage across the current run.
-   [`wrapper.tool_input`][agents.run_context.RunContextWrapper.tool_input] for structured input when the current run is executing inside [`Agent.as_tool()`][agents.agent.Agent.as_tool].
-   [`wrapper.approve_tool(...)`][agents.run_context.RunContextWrapper.approve_tool] / [`wrapper.reject_tool(...)`][agents.run_context.RunContextWrapper.reject_tool] when you need to update approval state programmatically.

Only `wrapper.context` is your app-defined object. The other fields are runtime metadata managed by the SDK.

If you later serialize a [`RunState`][agents.run_state.RunState] for human-in-the-loop or durable job workflows, that runtime metadata is saved with the state. Avoid putting secrets in [`RunContextWrapper.context`][agents.run_context.RunContextWrapper.context] if you intend to persist or transmit serialized state.

Conversation state is a separate concern. Use `result.to_input_list()`, `session`, `conversation_id`, or `previous_response_id` depending on how you want to carry turns forward. See [results](results.md), [running agents](running_agents.md), and [sessions](sessions/index.md) for that decision.

```python
import asyncio
from dataclasses import dataclass

from agents import Agent, RunContextWrapper, Runner, function_tool

@dataclass
class UserInfo:  # (1)!
    name: str
    uid: int

@function_tool
async def fetch_user_age(wrapper: RunContextWrapper[UserInfo]) -> str:  # (2)!
    """Fetch the age of the user. Call this function to get user's age information."""
    return f"The user {wrapper.context.name} is 47 years old"

async def main():
    user_info = UserInfo(name="John", uid=123)

    agent = Agent[UserInfo](  # (3)!
        name="Assistant",
        tools=[fetch_user_age],
    )

    result = await Runner.run(  # (4)!
        starting_agent=agent,
        input="What is the age of the user?",
        context=user_info,
    )

    print(result.final_output)  # (5)!
    # The user John is 47 years old.

if __name__ == "__main__":
    asyncio.run(main())
```

1. This is the context object. We've used a dataclass here, but you can use any type.
2. This is a tool. You can see it takes a `RunContextWrapper[UserInfo]`. The tool implementation reads from the context.
3. We mark the agent with the generic `UserInfo`, so that the typechecker can catch errors (for example, if we tried to pass a tool that took a different context type).
4. The context is passed to the `run` function.
5. The agent correctly calls the tool and gets the age.

---

### Advanced: `ToolContext`

In some cases, you might want to access extra metadata about the tool being executed — such as its name, call ID, or raw argument string.  
For this, you can use the [`ToolContext`][agents.tool_context.ToolContext] class, which extends `RunContextWrapper`.

```python
from typing import Annotated
from pydantic import BaseModel, Field
from agents import Agent, Runner, function_tool
from agents.tool_context import ToolContext

class WeatherContext(BaseModel):
    user_id: str

class Weather(BaseModel):
    city: str = Field(description="The city name")
    temperature_range: str = Field(description="The temperature range in Celsius")
    conditions: str = Field(description="The weather conditions")

@function_tool
def get_weather(ctx: ToolContext[WeatherContext], city: Annotated[str, "The city to get the weather for"]) -> Weather:
    print(f"[debug] Tool context: (name: {ctx.tool_name}, call_id: {ctx.tool_call_id}, args: {ctx.tool_arguments})")
    return Weather(city=city, temperature_range="14-20C", conditions="Sunny with wind.")

agent = Agent(
    name="Weather Agent",
    instructions="You are a helpful agent that can tell the weather of a given city.",
    tools=[get_weather],
)
```

`ToolContext` provides the same `.context` property as `RunContextWrapper`,  
plus additional fields specific to the current tool call:

- `tool_name` – the name of the tool being invoked  
- `tool_call_id` – a unique identifier for this tool call  
- `tool_arguments` – the raw argument string passed to the tool  

Use `ToolContext` when you need tool-level metadata during execution.  
For general context sharing between agents and tools, `RunContextWrapper` remains sufficient. Because `ToolContext` extends `RunContextWrapper`, it can also expose `.tool_input` when a nested `Agent.as_tool()` run supplied structured input.

---

## Agent/LLM context

When an LLM is called, the **only** data it can see is from the conversation history. This means that if you want to make some new data available to the LLM, you must do it in a way that makes it available in that history. There are a few ways to do this:

1. You can add it to the Agent `instructions`. This is also known as a "system prompt" or "developer message". System prompts can be static strings, or they can be dynamic functions that receive the context and output a string. This is a common tactic for information that is always useful (for example, the user's name or the current date).
2. Add it to the `input` when calling the `Runner.run` functions. This is similar to the `instructions` tactic, but allows you to have messages that are lower in the [chain of command](https://cdn.openai.com/spec/model-spec-2024-05-08.html#follow-the-chain-of-command).
3. Expose it via function tools. This is useful for _on-demand_ context - the LLM decides when it needs some data, and can call the tool to fetch that data.
4. Use retrieval or web search. These are special tools that are able to fetch relevant data from files or databases (retrieval), or from the web (web search). This is useful for "grounding" the response in relevant contextual data.

================
File: docs/examples.md
================
# Examples

Check out a variety of sample implementations of the SDK in the examples section of the [repo](https://github.com/openai/openai-agents-python/tree/main/examples). The examples are organized into several categories that demonstrate different patterns and capabilities.

## Categories

-   **[agent_patterns](https://github.com/openai/openai-agents-python/tree/main/examples/agent_patterns):**
    Examples in this category illustrate common agent design patterns, such as

    -   Deterministic workflows
    -   Agents as tools
    -   Parallel agent execution
    -   Conditional tool usage
    -   Input/output guardrails
    -   LLM as a judge
    -   Routing
    -   Streaming guardrails

-   **[basic](https://github.com/openai/openai-agents-python/tree/main/examples/basic):**
    These examples showcase foundational capabilities of the SDK, such as

    -   Hello world examples (Default model, GPT-5, open-weight model)
    -   Agent lifecycle management
    -   Dynamic system prompts
    -   Streaming outputs (text, items, function call args)
    -   Responses websocket transport with a shared session helper across turns (`examples/basic/stream_ws.py`)
    -   Prompt templates
    -   File handling (local and remote, images and PDFs)
    -   Usage tracking
    -   Non-strict output types
    -   Previous response ID usage

-   **[customer_service](https://github.com/openai/openai-agents-python/tree/main/examples/customer_service):**
    Example customer service system for an airline.

-   **[financial_research_agent](https://github.com/openai/openai-agents-python/tree/main/examples/financial_research_agent):**
    A financial research agent that demonstrates structured research workflows with agents and tools for financial data analysis.

-   **[handoffs](https://github.com/openai/openai-agents-python/tree/main/examples/handoffs):**
    See practical examples of agent handoffs with message filtering.

-   **[hosted_mcp](https://github.com/openai/openai-agents-python/tree/main/examples/hosted_mcp):**
    Examples demonstrating how to use hosted MCP (Model Context Protocol) connectors and approvals.

-   **[mcp](https://github.com/openai/openai-agents-python/tree/main/examples/mcp):**
    Learn how to build agents with MCP (Model Context Protocol), including:

    -   Filesystem examples
    -   Git examples
    -   MCP prompt server examples
    -   SSE (Server-Sent Events) examples
    -   Streamable HTTP examples

-   **[memory](https://github.com/openai/openai-agents-python/tree/main/examples/memory):**
    Examples of different memory implementations for agents, including:

    -   SQLite session storage
    -   Advanced SQLite session storage
    -   Redis session storage
    -   SQLAlchemy session storage
    -   Dapr state store session storage
    -   Encrypted session storage
    -   OpenAI Conversations session storage
    -   Responses compaction session storage

-   **[model_providers](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers):**
    Explore how to use non-OpenAI models with the SDK, including custom providers and LiteLLM integration.

-   **[realtime](https://github.com/openai/openai-agents-python/tree/main/examples/realtime):**
    Examples showing how to build real-time experiences using the SDK, including:

    -   Web application patterns with structured text and image messages
    -   Command-line audio loops and playback handling
    -   Twilio Media Streams integration over WebSocket
    -   Twilio SIP integration using Realtime Calls API attach flows

-   **[reasoning_content](https://github.com/openai/openai-agents-python/tree/main/examples/reasoning_content):**
    Examples demonstrating how to work with reasoning content and structured outputs.

-   **[research_bot](https://github.com/openai/openai-agents-python/tree/main/examples/research_bot):**
    Simple deep research clone that demonstrates complex multi-agent research workflows.

-   **[tools](https://github.com/openai/openai-agents-python/tree/main/examples/tools):**
    Learn how to implement OAI hosted tools and experimental Codex tooling such as:

    -   Web search and web search with filters
    -   File search
    -   Code interpreter
    -   Hosted container shell with inline skills (`examples/tools/container_shell_inline_skill.py`)
    -   Hosted container shell with skill references (`examples/tools/container_shell_skill_reference.py`)
    -   Computer use
    -   Image generation
    -   Experimental Codex tool workflows (`examples/tools/codex.py`)
    -   Experimental Codex same-thread workflows (`examples/tools/codex_same_thread.py`)

-   **[voice](https://github.com/openai/openai-agents-python/tree/main/examples/voice):**
    See examples of voice agents, using our TTS and STT models, including streamed voice examples.

================
File: docs/guardrails.md
================
# Guardrails

Guardrails enable you to do checks and validations of user input and agent output. For example, imagine you have an agent that uses a very smart (and hence slow/expensive) model to help with customer requests. You wouldn't want malicious users to ask the model to help them with their math homework. So, you can run a guardrail with a fast/cheap model. If the guardrail detects malicious usage, it can immediately raise an error and prevent the expensive model from running, saving you time and money (**when using blocking guardrails; for parallel guardrails, the expensive model may have already started running before the guardrail completes. See "Execution modes" below for details**).

There are two kinds of guardrails:

1. Input guardrails run on the initial user input
2. Output guardrails run on the final agent output

## Workflow boundaries

Guardrails are attached to agents and tools, but they do not all run at the same points in a workflow:

-   **Input guardrails** run only for the first agent in the chain.
-   **Output guardrails** run only for the agent that produces the final output.
-   **Tool guardrails** run on every custom function-tool invocation, with input guardrails before execution and output guardrails after execution.

If you need checks around each custom function-tool call in a workflow that includes managers, handoffs, or delegated specialists, use tool guardrails instead of relying only on agent-level input/output guardrails.

## Input guardrails

Input guardrails run in 3 steps:

1. First, the guardrail receives the same input passed to the agent.
2. Next, the guardrail function runs to produce a [`GuardrailFunctionOutput`][agents.guardrail.GuardrailFunctionOutput], which is then wrapped in an [`InputGuardrailResult`][agents.guardrail.InputGuardrailResult]
3. Finally, we check if [`.tripwire_triggered`][agents.guardrail.GuardrailFunctionOutput.tripwire_triggered] is true. If true, an [`InputGuardrailTripwireTriggered`][agents.exceptions.InputGuardrailTripwireTriggered] exception is raised, so you can appropriately respond to the user or handle the exception.

!!! Note

    Input guardrails are intended to run on user input, so an agent's guardrails only run if the agent is the *first* agent. You might wonder, why is the `guardrails` property on the agent instead of passed to `Runner.run`? It's because guardrails tend to be related to the actual Agent - you'd run different guardrails for different agents, so colocating the code is useful for readability.

### Execution modes

Input guardrails support two execution modes:

- **Parallel execution** (default, `run_in_parallel=True`): The guardrail runs concurrently with the agent's execution. This provides the best latency since both start at the same time. However, if the guardrail fails, the agent may have already consumed tokens and executed tools before being cancelled.

- **Blocking execution** (`run_in_parallel=False`): The guardrail runs and completes *before* the agent starts. If the guardrail tripwire is triggered, the agent never executes, preventing token consumption and tool execution. This is ideal for cost optimization and when you want to avoid potential side effects from tool calls.

## Output guardrails

Output guardrails run in 3 steps:

1. First, the guardrail receives the output produced by the agent.
2. Next, the guardrail function runs to produce a [`GuardrailFunctionOutput`][agents.guardrail.GuardrailFunctionOutput], which is then wrapped in an [`OutputGuardrailResult`][agents.guardrail.OutputGuardrailResult]
3. Finally, we check if [`.tripwire_triggered`][agents.guardrail.GuardrailFunctionOutput.tripwire_triggered] is true. If true, an [`OutputGuardrailTripwireTriggered`][agents.exceptions.OutputGuardrailTripwireTriggered] exception is raised, so you can appropriately respond to the user or handle the exception.

!!! Note

    Output guardrails are intended to run on the final agent output, so an agent's guardrails only run if the agent is the *last* agent. Similar to the input guardrails, we do this because guardrails tend to be related to the actual Agent - you'd run different guardrails for different agents, so colocating the code is useful for readability.

    Output guardrails always run after the agent completes, so they don't support the `run_in_parallel` parameter.

## Tool guardrails

Tool guardrails wrap **function tools** and let you validate or block tool calls before and after execution. They are configured on the tool itself and run every time that tool is invoked.

- Input tool guardrails run before the tool executes and can skip the call, replace the output with a message, or raise a tripwire.
- Output tool guardrails run after the tool executes and can replace the output or raise a tripwire.
- Tool guardrails apply only to function tools created with [`function_tool`][agents.tool.function_tool]. Handoffs run through the SDK's handoff pipeline rather than the normal function-tool pipeline, so tool guardrails do not apply to the handoff call itself. Hosted tools (`WebSearchTool`, `FileSearchTool`, `HostedMCPTool`, `CodeInterpreterTool`, `ImageGenerationTool`) and built-in execution tools (`ComputerTool`, `ShellTool`, `ApplyPatchTool`, `LocalShellTool`) also do not use this guardrail pipeline, and [`Agent.as_tool()`][agents.agent.Agent.as_tool] does not currently expose tool-guardrail options directly.

See the code snippet below for details.

## Tripwires

If the input or output fails the guardrail, the Guardrail can signal this with a tripwire. As soon as we see a guardrail that has triggered the tripwires, we immediately raise a `{Input,Output}GuardrailTripwireTriggered` exception and halt the Agent execution.

## Implementing a guardrail

You need to provide a function that receives input, and returns a [`GuardrailFunctionOutput`][agents.guardrail.GuardrailFunctionOutput]. In this example, we'll do this by running an Agent under the hood.

```python
from pydantic import BaseModel
from agents import (
    Agent,
    GuardrailFunctionOutput,
    InputGuardrailTripwireTriggered,
    RunContextWrapper,
    Runner,
    TResponseInputItem,
    input_guardrail,
)

class MathHomeworkOutput(BaseModel):
    is_math_homework: bool
    reasoning: str

guardrail_agent = Agent( # (1)!
    name="Guardrail check",
    instructions="Check if the user is asking you to do their math homework.",
    output_type=MathHomeworkOutput,
)


@input_guardrail
async def math_guardrail( # (2)!
    ctx: RunContextWrapper[None], agent: Agent, input: str | list[TResponseInputItem]
) -> GuardrailFunctionOutput:
    result = await Runner.run(guardrail_agent, input, context=ctx.context)

    return GuardrailFunctionOutput(
        output_info=result.final_output, # (3)!
        tripwire_triggered=result.final_output.is_math_homework,
    )


agent = Agent(  # (4)!
    name="Customer support agent",
    instructions="You are a customer support agent. You help customers with their questions.",
    input_guardrails=[math_guardrail],
)

async def main():
    # This should trip the guardrail
    try:
        await Runner.run(agent, "Hello, can you help me solve for x: 2x + 3 = 11?")
        print("Guardrail didn't trip - this is unexpected")

    except InputGuardrailTripwireTriggered:
        print("Math homework guardrail tripped")
```

1. We'll use this agent in our guardrail function.
2. This is the guardrail function that receives the agent's input/context, and returns the result.
3. We can include extra information in the guardrail result.
4. This is the actual agent that defines the workflow.

Output guardrails are similar.

```python
from pydantic import BaseModel
from agents import (
    Agent,
    GuardrailFunctionOutput,
    OutputGuardrailTripwireTriggered,
    RunContextWrapper,
    Runner,
    output_guardrail,
)
class MessageOutput(BaseModel): # (1)!
    response: str

class MathOutput(BaseModel): # (2)!
    reasoning: str
    is_math: bool

guardrail_agent = Agent(
    name="Guardrail check",
    instructions="Check if the output includes any math.",
    output_type=MathOutput,
)

@output_guardrail
async def math_guardrail(  # (3)!
    ctx: RunContextWrapper, agent: Agent, output: MessageOutput
) -> GuardrailFunctionOutput:
    result = await Runner.run(guardrail_agent, output.response, context=ctx.context)

    return GuardrailFunctionOutput(
        output_info=result.final_output,
        tripwire_triggered=result.final_output.is_math,
    )

agent = Agent( # (4)!
    name="Customer support agent",
    instructions="You are a customer support agent. You help customers with their questions.",
    output_guardrails=[math_guardrail],
    output_type=MessageOutput,
)

async def main():
    # This should trip the guardrail
    try:
        await Runner.run(agent, "Hello, can you help me solve for x: 2x + 3 = 11?")
        print("Guardrail didn't trip - this is unexpected")

    except OutputGuardrailTripwireTriggered:
        print("Math output guardrail tripped")
```

1. This is the actual agent's output type.
2. This is the guardrail's output type.
3. This is the guardrail function that receives the agent's output, and returns the result.
4. This is the actual agent that defines the workflow.

Lastly, here are examples of tool guardrails.

```python
import json
from agents import (
    Agent,
    Runner,
    ToolGuardrailFunctionOutput,
    function_tool,
    tool_input_guardrail,
    tool_output_guardrail,
)

@tool_input_guardrail
def block_secrets(data):
    args = json.loads(data.context.tool_arguments or "{}")
    if "sk-" in json.dumps(args):
        return ToolGuardrailFunctionOutput.reject_content(
            "Remove secrets before calling this tool."
        )
    return ToolGuardrailFunctionOutput.allow()


@tool_output_guardrail
def redact_output(data):
    text = str(data.output or "")
    if "sk-" in text:
        return ToolGuardrailFunctionOutput.reject_content("Output contained sensitive data.")
    return ToolGuardrailFunctionOutput.allow()


@function_tool(
    tool_input_guardrails=[block_secrets],
    tool_output_guardrails=[redact_output],
)
def classify_text(text: str) -> str:
    """Classify text for internal routing."""
    return f"length:{len(text)}"


agent = Agent(name="Classifier", tools=[classify_text])
result = Runner.run_sync(agent, "hello world")
print(result.final_output)
```

================
File: docs/handoffs.md
================
# Handoffs

Handoffs allow an agent to delegate tasks to another agent. This is particularly useful in scenarios where different agents specialize in distinct areas. For example, a customer support app might have agents that each specifically handle tasks like order status, refunds, FAQs, etc.

Handoffs are represented as tools to the LLM. So if there's a handoff to an agent named `Refund Agent`, the tool would be called `transfer_to_refund_agent`.

## Creating a handoff

All agents have a [`handoffs`][agents.agent.Agent.handoffs] param, which can either take an `Agent` directly, or a `Handoff` object that customizes the Handoff.

If you pass plain `Agent` instances, their [`handoff_description`][agents.agent.Agent.handoff_description] (when set) is appended to the default tool description. Use it to hint when the model should pick that handoff without writing a full `handoff()` object.

You can create a handoff using the [`handoff()`][agents.handoffs.handoff] function provided by the Agents SDK. This function allows you to specify the agent to hand off to, along with optional overrides and input filters.

### Basic usage

Here's how you can create a simple handoff:

```python
from agents import Agent, handoff

billing_agent = Agent(name="Billing agent")
refund_agent = Agent(name="Refund agent")

# (1)!
triage_agent = Agent(name="Triage agent", handoffs=[billing_agent, handoff(refund_agent)])
```

1. You can use the agent directly (as in `billing_agent`), or you can use the `handoff()` function.

### Customizing handoffs via the `handoff()` function

The [`handoff()`][agents.handoffs.handoff] function lets you customize things.

-   `agent`: This is the agent to which things will be handed off.
-   `tool_name_override`: By default, the `Handoff.default_tool_name()` function is used, which resolves to `transfer_to_<agent_name>`. You can override this.
-   `tool_description_override`: Override the default tool description from `Handoff.default_tool_description()`
-   `on_handoff`: A callback function executed when the handoff is invoked. This is useful for things like kicking off some data fetching as soon as you know a handoff is being invoked. This function receives the agent context, and can optionally also receive LLM generated input. The input data is controlled by the `input_type` param.
-   `input_type`: The schema for the handoff tool-call arguments. When set, the parsed payload is passed to `on_handoff`.
-   `input_filter`: This lets you filter the input received by the next agent. See below for more.
-   `is_enabled`: Whether the handoff is enabled. This can be a boolean or a function that returns a boolean, allowing you to dynamically enable or disable the handoff at runtime.
-   `nest_handoff_history`: Optional per-call override for the RunConfig-level `nest_handoff_history` setting. If `None`, the value defined in the active run configuration is used instead.

The [`handoff()`][agents.handoffs.handoff] helper always transfers control to the specific `agent` you passed in. If you have multiple possible destinations, register one handoff per destination and let the model choose among them. Use a custom [`Handoff`][agents.handoffs.Handoff] only when your own handoff code must decide which agent to return at invocation time.

```python
from agents import Agent, handoff, RunContextWrapper

def on_handoff(ctx: RunContextWrapper[None]):
    print("Handoff called")

agent = Agent(name="My agent")

handoff_obj = handoff(
    agent=agent,
    on_handoff=on_handoff,
    tool_name_override="custom_handoff_tool",
    tool_description_override="Custom description",
)
```

## Handoff inputs

In certain situations, you want the LLM to provide some data when it calls a handoff. For example, imagine a handoff to an "Escalation agent". You might want a reason to be provided, so you can log it.

```python
from pydantic import BaseModel

from agents import Agent, handoff, RunContextWrapper

class EscalationData(BaseModel):
    reason: str

async def on_handoff(ctx: RunContextWrapper[None], input_data: EscalationData):
    print(f"Escalation agent called with reason: {input_data.reason}")

agent = Agent(name="Escalation agent")

handoff_obj = handoff(
    agent=agent,
    on_handoff=on_handoff,
    input_type=EscalationData,
)
```

`input_type` describes the arguments for the handoff tool call itself. The SDK exposes that schema to the model as the handoff tool's `parameters`, validates the returned JSON locally, and passes the parsed value to `on_handoff`.

It does not replace the next agent's main input, and it does not choose a different destination. The [`handoff()`][agents.handoffs.handoff] helper still transfers to the specific agent you wrapped, and the receiving agent still sees the conversation history unless you change it with an [`input_filter`][agents.handoffs.Handoff.input_filter] or nested handoff history settings.

`input_type` is also separate from [`RunContextWrapper.context`][agents.run_context.RunContextWrapper.context]. Use `input_type` for metadata the model decides at handoff time, not for application state or dependencies you already have locally.

### When to use `input_type`

Use `input_type` when the handoff needs a small piece of model-generated metadata such as `reason`, `language`, `priority`, or `summary`. For example, a triage agent can hand off to a refund agent with `{ "reason": "duplicate_charge", "priority": "high" }`, and `on_handoff` can log or persist that metadata before the refund agent takes over.

Choose a different mechanism when the goal is different:

-   Put existing application state and dependencies in [`RunContextWrapper.context`][agents.run_context.RunContextWrapper.context]. See the [context guide](context.md).
-   Use [`input_filter`][agents.handoffs.Handoff.input_filter], [`RunConfig.nest_handoff_history`][agents.run.RunConfig.nest_handoff_history], or [`RunConfig.handoff_history_mapper`][agents.run.RunConfig.handoff_history_mapper] if you want to change what history the receiving agent sees.
-   Register one handoff per destination if there are multiple possible specialists. `input_type` can add metadata to the chosen handoff, but it does not dispatch between destinations.
-   If you want structured input for a nested specialist without transferring the conversation, prefer [`Agent.as_tool(parameters=...)`][agents.agent.Agent.as_tool]. See [tools](tools.md#structured-input-for-tool-agents).

## Input filters

When a handoff occurs, it's as though the new agent takes over the conversation, and gets to see the entire previous conversation history. If you want to change this, you can set an [`input_filter`][agents.handoffs.Handoff.input_filter]. An input filter is a function that receives the existing input via a [`HandoffInputData`][agents.handoffs.HandoffInputData], and must return a new `HandoffInputData`.

[`HandoffInputData`][agents.handoffs.HandoffInputData] includes:

-   `input_history`: the input history before `Runner.run(...)` started.
-   `pre_handoff_items`: items generated before the agent turn where the handoff was invoked.
-   `new_items`: items generated during the current turn, including the handoff call and handoff output items.
-   `input_items`: optional items to forward to the next agent instead of `new_items`, allowing you to filter model input while keeping `new_items` intact for session history.
-   `run_context`: the active [`RunContextWrapper`][agents.run_context.RunContextWrapper] at the time the handoff was invoked.

Nested handoffs are available as an opt-in beta and are disabled by default while we stabilize them. When you enable [`RunConfig.nest_handoff_history`][agents.run.RunConfig.nest_handoff_history], the runner collapses the prior transcript into a single assistant summary message and wraps it in a `<CONVERSATION HISTORY>` block that keeps appending new turns when multiple handoffs happen during the same run. You can provide your own mapping function via [`RunConfig.handoff_history_mapper`][agents.run.RunConfig.handoff_history_mapper] to replace the generated message without writing a full `input_filter`. The opt-in only applies when neither the handoff nor the run supplies an explicit `input_filter`, so existing code that already customizes the payload (including the examples in this repository) keeps its current behavior without changes. You can override the nesting behaviour for a single handoff by passing `nest_handoff_history=True` or `False` to [`handoff(...)`][agents.handoffs.handoff], which sets [`Handoff.nest_handoff_history`][agents.handoffs.Handoff.nest_handoff_history]. If you just need to change the wrapper text for the generated summary, call [`set_conversation_history_wrappers`][agents.handoffs.set_conversation_history_wrappers] (and optionally [`reset_conversation_history_wrappers`][agents.handoffs.reset_conversation_history_wrappers]) before running your agents.

If both the handoff and the active [`RunConfig.handoff_input_filter`][agents.run.RunConfig.handoff_input_filter] define a filter, the per-handoff [`input_filter`][agents.handoffs.Handoff.input_filter] takes precedence for that specific handoff.

!!! note

    Handoffs stay within a single run. Input guardrails still apply only to the first agent in the chain, and output guardrails only to the agent that produces the final output. Use tool guardrails when you need checks around each custom function-tool call inside the workflow.

There are some common patterns (for example removing all tool calls from the history), which are implemented for you in [`agents.extensions.handoff_filters`][]

```python
from agents import Agent, handoff
from agents.extensions import handoff_filters

agent = Agent(name="FAQ agent")

handoff_obj = handoff(
    agent=agent,
    input_filter=handoff_filters.remove_all_tools, # (1)!
)
```

1. This will automatically remove all tools from the history when `FAQ agent` is called.

## Recommended prompts

To make sure that LLMs understand handoffs properly, we recommend including information about handoffs in your agents. We have a suggested prefix in [`agents.extensions.handoff_prompt.RECOMMENDED_PROMPT_PREFIX`][], or you can call [`agents.extensions.handoff_prompt.prompt_with_handoff_instructions`][] to automatically add recommended data to your prompts.

```python
from agents import Agent
from agents.extensions.handoff_prompt import RECOMMENDED_PROMPT_PREFIX

billing_agent = Agent(
    name="Billing agent",
    instructions=f"""{RECOMMENDED_PROMPT_PREFIX}
    <Fill in the rest of your prompt here>.""",
)
```

================
File: docs/human_in_the_loop.md
================
# Human-in-the-loop

Use the human-in-the-loop (HITL) flow to pause agent execution until a person approves or rejects sensitive tool calls. Tools declare when they need approval, run results surface pending approvals as interruptions, and `RunState` lets you serialize and resume runs after decisions are made.

That approval surface is run-wide, not limited to the current top-level agent. The same pattern applies when the tool belongs to the current agent, to an agent reached through a handoff, or to a nested [`Agent.as_tool()`][agents.agent.Agent.as_tool] execution. In the nested `Agent.as_tool()` case, the interruption still surfaces on the outer run, so you approve or reject it on the outer `RunState` and resume the original top-level run.

With `Agent.as_tool()`, approvals can happen at two different layers: the agent tool itself can require approval via `Agent.as_tool(..., needs_approval=...)`, and tools inside the nested agent can later raise their own approvals after the nested run starts. Both are handled through the same outer-run interruption flow.

This page focuses on the manual approval flow via `interruptions`. If your app can decide in code, some tool types also support programmatic approval callbacks so the run can continue without pausing.

## Marking tools that need approval

Set `needs_approval` to `True` to always require approval or provide an async function that decides per call. The callable receives the run context, parsed tool parameters, and the tool call ID.

```python
from agents import Agent, Runner, function_tool


@function_tool(needs_approval=True)
async def cancel_order(order_id: int) -> str:
    return f"Cancelled order {order_id}"


async def requires_review(_ctx, params, _call_id) -> bool:
    return "refund" in params.get("subject", "").lower()


@function_tool(needs_approval=requires_review)
async def send_email(subject: str, body: str) -> str:
    return f"Sent '{subject}'"


agent = Agent(
    name="Support agent",
    instructions="Handle tickets and ask for approval when needed.",
    tools=[cancel_order, send_email],
)
```

`needs_approval` is available on [`function_tool`][agents.tool.function_tool], [`Agent.as_tool`][agents.agent.Agent.as_tool], [`ShellTool`][agents.tool.ShellTool], and [`ApplyPatchTool`][agents.tool.ApplyPatchTool]. Local MCP servers also support approvals through `require_approval` on [`MCPServerStdio`][agents.mcp.server.MCPServerStdio], [`MCPServerSse`][agents.mcp.server.MCPServerSse], and [`MCPServerStreamableHttp`][agents.mcp.server.MCPServerStreamableHttp]. Hosted MCP servers support approvals via [`HostedMCPTool`][agents.tool.HostedMCPTool] with `tool_config={"require_approval": "always"}` and an optional `on_approval_request` callback. Shell and apply_patch tools accept an `on_approval` callback if you want to auto-approve or auto-reject without surfacing an interruption.

## How the approval flow works

1. When the model emits a tool call, the runner evaluates its approval rule (`needs_approval`, `require_approval`, or the hosted MCP equivalent).
2. If an approval decision for that tool call is already stored in the [`RunContextWrapper`][agents.run_context.RunContextWrapper], the runner proceeds without prompting. Per-call approvals are scoped to the specific call ID; pass `always_approve=True` or `always_reject=True` to persist the same decision for future calls to that tool during the rest of the run.
3. Otherwise, execution pauses and `RunResult.interruptions` (or `RunResultStreaming.interruptions`) contains [`ToolApprovalItem`][agents.items.ToolApprovalItem] entries with details such as `agent.name`, `tool_name`, and `arguments`. This includes approvals raised after a handoff or inside nested `Agent.as_tool()` executions.
4. Convert the result to a `RunState` with `result.to_state()`, call `state.approve(...)` or `state.reject(...)`, and then resume with `Runner.run(agent, state)` or `Runner.run_streamed(agent, state)`, where `agent` is the original top-level agent for the run.
5. The resumed run continues where it left off and will re-enter this flow if new approvals are needed.

Sticky decisions created with `always_approve=True` or `always_reject=True` are stored in the run state, so they survive `state.to_string()` / `RunState.from_string(...)` and `state.to_json()` / `RunState.from_json(...)` when you resume the same paused run later.

You do not need to resolve every pending approval in the same pass. `interruptions` can contain a mix of regular function tools, hosted MCP approvals, and nested `Agent.as_tool()` approvals. If you rerun after approving or rejecting only some items, those resolved calls can continue while unresolved ones remain in `interruptions` and pause the run again.

## Automatic approval decisions

Manual `interruptions` are the most general pattern, but they are not the only one:

-   Local [`ShellTool`][agents.tool.ShellTool] and [`ApplyPatchTool`][agents.tool.ApplyPatchTool] can use `on_approval` to approve or reject immediately in code.
-   [`HostedMCPTool`][agents.tool.HostedMCPTool] can use `tool_config={"require_approval": "always"}` together with `on_approval_request` for the same kind of programmatic decision.
-   Plain [`function_tool`][agents.tool.function_tool] tools and [`Agent.as_tool()`][agents.agent.Agent.as_tool] use the manual interruption flow on this page.

When these callbacks return a decision, the run continues without pausing for a human response. For Realtime and voice session APIs, see the approval flow in the [Realtime guide](realtime/guide.md).

## Streaming and sessions

The same interruption flow works in streaming runs. After a streamed run pauses, keep consuming [`RunResultStreaming.stream_events()`][agents.result.RunResultStreaming.stream_events] until the iterator finishes, inspect [`RunResultStreaming.interruptions`][agents.result.RunResultStreaming.interruptions], resolve them, and resume with [`Runner.run_streamed(...)`][agents.run.Runner.run_streamed] if you want the resumed output to keep streaming. See [Streaming](streaming.md) for the streamed version of this pattern.

If you are also using a session, keep passing the same session instance when you resume from `RunState`, or pass another session object that points at the same backing store. The resumed turn is then appended to the same stored conversation history. See [Sessions](sessions/index.md) for the session lifecycle details.

## Example: pause, approve, resume

The snippet below mirrors the JavaScript HITL guide: it pauses when a tool needs approval, persists state to disk, reloads it, and resumes after collecting a decision.

```python
import asyncio
import json
from pathlib import Path

from agents import Agent, Runner, RunState, function_tool


async def needs_oakland_approval(_ctx, params, _call_id) -> bool:
    return "Oakland" in params.get("city", "")


@function_tool(needs_approval=needs_oakland_approval)
async def get_temperature(city: str) -> str:
    return f"The temperature in {city} is 20° Celsius"


agent = Agent(
    name="Weather assistant",
    instructions="Answer weather questions with the provided tools.",
    tools=[get_temperature],
)

STATE_PATH = Path(".cache/hitl_state.json")


def prompt_approval(tool_name: str, arguments: str | None) -> bool:
    answer = input(f"Approve {tool_name} with {arguments}? [y/N]: ").strip().lower()
    return answer in {"y", "yes"}


async def main() -> None:
    result = await Runner.run(agent, "What is the temperature in Oakland?")

    while result.interruptions:
        # Persist the paused state.
        state = result.to_state()
        STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
        STATE_PATH.write_text(state.to_string())

        # Load the state later (could be a different process).
        stored = json.loads(STATE_PATH.read_text())
        state = await RunState.from_json(agent, stored)

        for interruption in result.interruptions:
            approved = await asyncio.get_running_loop().run_in_executor(
                None, prompt_approval, interruption.name or "unknown_tool", interruption.arguments
            )
            if approved:
                state.approve(interruption, always_approve=False)
            else:
                state.reject(interruption)

        result = await Runner.run(agent, state)

    print(result.final_output)


if __name__ == "__main__":
    asyncio.run(main())
```

In this example, `prompt_approval` is synchronous because it uses `input()` and is executed with `run_in_executor(...)`. If your approval source is already asynchronous (for example, an HTTP request or async database query), you can use an `async def` function and `await` it directly instead.

To stream output while waiting for approvals, call `Runner.run_streamed`, consume `result.stream_events()` until it completes, and then follow the same `result.to_state()` and resume steps shown above.

## Repository patterns and examples

- **Streaming approvals**: `examples/agent_patterns/human_in_the_loop_stream.py` shows how to drain `stream_events()` and then approve pending tool calls before resuming with `Runner.run_streamed(agent, state)`.
- **Agent as tool approvals**: `Agent.as_tool(..., needs_approval=...)` applies the same interruption flow when delegated agent tasks need review. Nested interruptions still surface on the outer run, so resume the original top-level agent rather than the nested one.
- **Local shell and apply_patch tools**: `ShellTool` and `ApplyPatchTool` also support `needs_approval`. Use `state.approve(interruption, always_approve=True)` or `state.reject(..., always_reject=True)` to cache the decision for future calls. For automatic decisions, provide `on_approval` (see `examples/tools/shell.py`); for manual decisions, handle interruptions (see `examples/tools/shell_human_in_the_loop.py`). Hosted shell environments do not support `needs_approval` or `on_approval`; see the [tools guide](tools.md).
- **Local MCP servers**: Use `require_approval` on `MCPServerStdio` / `MCPServerSse` / `MCPServerStreamableHttp` to gate MCP tool calls (see `examples/mcp/get_all_mcp_tools_example/main.py` and `examples/mcp/tool_filter_example/main.py`).
- **Hosted MCP servers**: Set `require_approval` to `"always"` on `HostedMCPTool` to force HITL, optionally providing `on_approval_request` to auto-approve or reject (see `examples/hosted_mcp/human_in_the_loop.py` and `examples/hosted_mcp/on_approval.py`). Use `"never"` for trusted servers (`examples/hosted_mcp/simple.py`).
- **Sessions and memory**: Pass a session to `Runner.run` so approvals and conversation history survive multiple turns. SQLite and OpenAI Conversations session variants are in `examples/memory/memory_session_hitl_example.py` and `examples/memory/openai_session_hitl_example.py`.
- **Realtime agents**: The realtime demo exposes WebSocket messages that approve or reject tool calls via `approve_tool_call` / `reject_tool_call` on the `RealtimeSession` (see `examples/realtime/app/server.py` for the server-side handlers and [Realtime guide](realtime/guide.md#tool-approvals) for the API surface).

## Long-running approvals

`RunState` is designed to be durable. Use `state.to_json()` or `state.to_string()` to store pending work in a database or queue and recreate it later with `RunState.from_json(...)` or `RunState.from_string(...)`.

Useful serialization options:

-   `context_serializer`: Customize how non-mapping context objects are serialized.
-   `context_deserializer`: Rebuild non-mapping context objects when loading state with `RunState.from_json(...)` or `RunState.from_string(...)`.
-   `strict_context=True`: Fail serialization or deserialization unless the context is already a
    mapping or you provide the appropriate serializer/deserializer.
-   `context_override`: Replace the serialized context when loading state. This is useful when you
    do not want to restore the original context object, but it does not remove that context from an
    already serialized payload.
-   `include_tracing_api_key=True`: Include the tracing API key in the serialized trace payload
    when you need resumed work to keep exporting traces with the same credentials.

Serialized run state includes your app context plus SDK-managed runtime metadata such as approvals,
usage, serialized `tool_input`, nested agent-as-tool resumptions, trace metadata, and server-managed
conversation settings. If you plan to store or transmit serialized state, treat
`RunContextWrapper.context` as persisted data and avoid placing secrets there unless you
intentionally want them to travel with the state.

## Versioning pending tasks

If approvals may sit for a while, store a version marker for your agent definitions or SDK alongside the serialized state. You can then route deserialization to the matching code path to avoid incompatibilities when models, prompts, or tool definitions change.

================
File: docs/index.md
================
# OpenAI Agents SDK

The [OpenAI Agents SDK](https://github.com/openai/openai-agents-python) enables you to build agentic AI apps in a lightweight, easy-to-use package with very few abstractions. It's a production-ready upgrade of our previous experimentation for agents, [Swarm](https://github.com/openai/swarm/tree/main). The Agents SDK has a very small set of primitives:

-   **Agents**, which are LLMs equipped with instructions and tools
-   **Agents as tools / Handoffs**, which allow agents to delegate to other agents for specific tasks
-   **Guardrails**, which enable validation of agent inputs and outputs

In combination with Python, these primitives are powerful enough to express complex relationships between tools and agents, and allow you to build real-world applications without a steep learning curve. In addition, the SDK comes with built-in **tracing** that lets you visualize and debug your agentic flows, as well as evaluate them and even fine-tune models for your application.

## Why use the Agents SDK

The SDK has two driving design principles:

1. Enough features to be worth using, but few enough primitives to make it quick to learn.
2. Works great out of the box, but you can customize exactly what happens.

Here are the main features of the SDK:

-   **Agent loop**: A built-in agent loop that handles tool invocation, sends results back to the LLM, and continues until the task is complete.
-   **Python-first**: Use built-in language features to orchestrate and chain agents, rather than needing to learn new abstractions.
-   **Agents as tools / Handoffs**: A powerful mechanism for coordinating and delegating work across multiple agents.
-   **Guardrails**: Run input validation and safety checks in parallel with agent execution, and fail fast when checks do not pass.
-   **Function tools**: Turn any Python function into a tool with automatic schema generation and Pydantic-powered validation.
-   **MCP server tool calling**: Built-in MCP server tool integration that works the same way as function tools.
-   **Sessions**: A persistent memory layer for maintaining working context within an agent loop.
-   **Human in the loop**: Built-in mechanisms for involving humans across agent runs.
-   **Tracing**: Built-in tracing for visualizing, debugging, and monitoring workflows, with support for the OpenAI suite of evaluation, fine-tuning, and distillation tools.
-   **Realtime Agents**: Build powerful voice agents with features such as automatic interruption detection, context management, guardrails, and more.

## Installation

```bash
pip install openai-agents
```

## Hello world example

```python
from agents import Agent, Runner

agent = Agent(name="Assistant", instructions="You are a helpful assistant")

result = Runner.run_sync(agent, "Write a haiku about recursion in programming.")
print(result.final_output)

# Code within the code,
# Functions calling themselves,
# Infinite loop's dance.
```

(_If running this, ensure you set the `OPENAI_API_KEY` environment variable_)

```bash
export OPENAI_API_KEY=sk-...
```

## Start here

-   Build your first text-based agent with the [Quickstart](quickstart.md).
-   Then decide how you want to carry state across turns in [Running agents](running_agents.md#choose-a-memory-strategy).
-   If you are deciding between handoffs and manager-style orchestration, read [Agent orchestration](multi_agent.md).

## Choose your path

Use this table when you know the job you want to do, but not which page explains it.

| Goal | Start here |
| --- | --- |
| Build the first text agent and see one complete run | [Quickstart](quickstart.md) |
| Add function tools, hosted tools, or agents as tools | [Tools](tools.md) |
| Decide between handoffs and manager-style orchestration | [Agent orchestration](multi_agent.md) |
| Keep memory across turns | [Running agents](running_agents.md#choose-a-memory-strategy) and [Sessions](sessions/index.md) |
| Use OpenAI models, websocket transport, or non-OpenAI providers | [Models](models/index.md) |
| Review outputs, run items, interruptions, and resume state | [Results](results.md) |
| Build a low-latency voice agent | [Realtime agents quickstart](realtime/quickstart.md) and [Realtime transport](realtime/transport.md) |
| Build a speech-to-text / agent / text-to-speech pipeline | [Voice pipeline quickstart](voice/quickstart.md) |

================
File: docs/mcp.md
================
# Model context protocol (MCP)

The [Model context protocol](https://modelcontextprotocol.io/introduction) (MCP) standardises how applications expose tools and
context to language models. From the official documentation:

> MCP is an open protocol that standardizes how applications provide context to LLMs. Think of MCP like a USB-C port for AI
> applications. Just as USB-C provides a standardized way to connect your devices to various peripherals and accessories, MCP
> provides a standardized way to connect AI models to different data sources and tools.

The Agents Python SDK understands multiple MCP transports. This lets you reuse existing MCP servers or build your own to expose
filesystem, HTTP, or connector backed tools to an agent.

## Choosing an MCP integration

Before wiring an MCP server into an agent decide where the tool calls should execute and which transports you can reach. The
matrix below summarises the options that the Python SDK supports.

| What you need                                                                        | Recommended option                                    |
| ------------------------------------------------------------------------------------ | ----------------------------------------------------- |
| Let OpenAI's Responses API call a publicly reachable MCP server on the model's behalf| **Hosted MCP server tools** via [`HostedMCPTool`][agents.tool.HostedMCPTool] |
| Connect to Streamable HTTP servers that you run locally or remotely                  | **Streamable HTTP MCP servers** via [`MCPServerStreamableHttp`][agents.mcp.server.MCPServerStreamableHttp] |
| Talk to servers that implement HTTP with Server-Sent Events                          | **HTTP with SSE MCP servers** via [`MCPServerSse`][agents.mcp.server.MCPServerSse] |
| Launch a local process and communicate over stdin/stdout                             | **stdio MCP servers** via [`MCPServerStdio`][agents.mcp.server.MCPServerStdio] |

The sections below walk through each option, how to configure it, and when to prefer one transport over another.

## Agent-level MCP configuration

In addition to choosing a transport, you can tune how MCP tools are prepared by setting `Agent.mcp_config`.

```python
from agents import Agent

agent = Agent(
    name="Assistant",
    mcp_servers=[server],
    mcp_config={
        # Try to convert MCP tool schemas to strict JSON schema.
        "convert_schemas_to_strict": True,
        # If None, MCP tool failures are raised as exceptions instead of
        # returning model-visible error text.
        "failure_error_function": None,
    },
)
```

Notes:

- `convert_schemas_to_strict` is best-effort. If a schema cannot be converted, the original schema is used.
- `failure_error_function` controls how MCP tool call failures are surfaced to the model.
- When `failure_error_function` is unset, the SDK uses the default tool error formatter.
- Server-level `failure_error_function` overrides `Agent.mcp_config["failure_error_function"]` for that server.

## Shared patterns across transports

After you choose a transport, most integrations need the same follow-up decisions:

- How to expose only a subset of tools ([Tool filtering](#tool-filtering)).
- Whether the server also provides reusable prompts ([Prompts](#prompts)).
- Whether `list_tools()` should be cached ([Caching](#caching)).
- How MCP activity appears in traces ([Tracing](#tracing)).

For local MCP servers (`MCPServerStdio`, `MCPServerSse`, `MCPServerStreamableHttp`), approval policies and per-call `_meta` payloads are also shared concepts. The Streamable HTTP section shows the most complete examples, and the same patterns apply to the other local transports.

## 1. Hosted MCP server tools

Hosted tools push the entire tool round-trip into OpenAI's infrastructure. Instead of your code listing and calling tools, the
[`HostedMCPTool`][agents.tool.HostedMCPTool] forwards a server label (and optional connector metadata) to the Responses API. The
model lists the remote server's tools and invokes them without an extra callback to your Python process. Hosted tools currently
work with OpenAI models that support the Responses API's hosted MCP integration.

### Basic hosted MCP tool

Create a hosted tool by adding a [`HostedMCPTool`][agents.tool.HostedMCPTool] to the agent's `tools` list. The `tool_config`
dict mirrors the JSON you would send to the REST API:

```python
import asyncio

from agents import Agent, HostedMCPTool, Runner

async def main() -> None:
    agent = Agent(
        name="Assistant",
        tools=[
            HostedMCPTool(
                tool_config={
                    "type": "mcp",
                    "server_label": "gitmcp",
                    "server_url": "https://gitmcp.io/openai/codex",
                    "require_approval": "never",
                }
            )
        ],
    )

    result = await Runner.run(agent, "Which language is this repository written in?")
    print(result.final_output)

asyncio.run(main())
```

The hosted server exposes its tools automatically; you do not add it to `mcp_servers`.

### Streaming hosted MCP results

Hosted tools support streaming results in exactly the same way as function tools. Use `Runner.run_streamed` to
consume incremental MCP output while the model is still working:

```python
result = Runner.run_streamed(agent, "Summarise this repository's top languages")
async for event in result.stream_events():
    if event.type == "run_item_stream_event":
        print(f"Received: {event.item}")
print(result.final_output)
```

### Optional approval flows

If a server can perform sensitive operations you can require human or programmatic approval before each tool execution. Configure
`require_approval` in the `tool_config` with either a single policy (`"always"`, `"never"`) or a dict mapping tool names to
policies. To make the decision inside Python, provide an `on_approval_request` callback.

```python
from agents import MCPToolApprovalFunctionResult, MCPToolApprovalRequest

SAFE_TOOLS = {"read_project_metadata"}

def approve_tool(request: MCPToolApprovalRequest) -> MCPToolApprovalFunctionResult:
    if request.data.name in SAFE_TOOLS:
        return {"approve": True}
    return {"approve": False, "reason": "Escalate to a human reviewer"}

agent = Agent(
    name="Assistant",
    tools=[
        HostedMCPTool(
            tool_config={
                "type": "mcp",
                "server_label": "gitmcp",
                "server_url": "https://gitmcp.io/openai/codex",
                "require_approval": "always",
            },
            on_approval_request=approve_tool,
        )
    ],
)
```

The callback can be synchronous or asynchronous and is invoked whenever the model needs approval data to keep running.

### Connector-backed hosted servers

Hosted MCP also supports OpenAI connectors. Instead of specifying a `server_url`, supply a `connector_id` and an access token. The
Responses API handles authentication and the hosted server exposes the connector's tools.

```python
import os

HostedMCPTool(
    tool_config={
        "type": "mcp",
        "server_label": "google_calendar",
        "connector_id": "connector_googlecalendar",
        "authorization": os.environ["GOOGLE_CALENDAR_AUTHORIZATION"],
        "require_approval": "never",
    }
)
```

Fully working hosted tool samples—including streaming, approvals, and connectors—live in
[`examples/hosted_mcp`](https://github.com/openai/openai-agents-python/tree/main/examples/hosted_mcp).

## 2. Streamable HTTP MCP servers

When you want to manage the network connection yourself, use
[`MCPServerStreamableHttp`][agents.mcp.server.MCPServerStreamableHttp]. Streamable HTTP servers are ideal when you control the
transport or want to run the server inside your own infrastructure while keeping latency low.

```python
import asyncio
import os

from agents import Agent, Runner
from agents.mcp import MCPServerStreamableHttp
from agents.model_settings import ModelSettings

async def main() -> None:
    token = os.environ["MCP_SERVER_TOKEN"]
    async with MCPServerStreamableHttp(
        name="Streamable HTTP Python Server",
        params={
            "url": "http://localhost:8000/mcp",
            "headers": {"Authorization": f"Bearer {token}"},
            "timeout": 10,
        },
        cache_tools_list=True,
        max_retry_attempts=3,
    ) as server:
        agent = Agent(
            name="Assistant",
            instructions="Use the MCP tools to answer the questions.",
            mcp_servers=[server],
            model_settings=ModelSettings(tool_choice="required"),
        )

        result = await Runner.run(agent, "Add 7 and 22.")
        print(result.final_output)

asyncio.run(main())
```

The constructor accepts additional options:

- `client_session_timeout_seconds` controls HTTP read timeouts.
- `use_structured_content` toggles whether `tool_result.structured_content` is preferred over textual output.
- `max_retry_attempts` and `retry_backoff_seconds_base` add automatic retries for `list_tools()` and `call_tool()`.
- `tool_filter` lets you expose only a subset of tools (see [Tool filtering](#tool-filtering)).
- `require_approval` enables human-in-the-loop approval policies on local MCP tools.
- `failure_error_function` customizes model-visible MCP tool failure messages; set it to `None` to raise errors instead.
- `tool_meta_resolver` injects per-call MCP `_meta` payloads before `call_tool()`.

### Approval policies for local MCP servers

`MCPServerStdio`, `MCPServerSse`, and `MCPServerStreamableHttp` all accept `require_approval`.

Supported forms:

- `"always"` or `"never"` for all tools.
- `True` / `False` (equivalent to always/never).
- A per-tool map, for example `{"delete_file": "always", "read_file": "never"}`.
- A grouped object:
  `{"always": {"tool_names": [...]}, "never": {"tool_names": [...]}}`.

```python
async with MCPServerStreamableHttp(
    name="Filesystem MCP",
    params={"url": "http://localhost:8000/mcp"},
    require_approval={"always": {"tool_names": ["delete_file"]}},
) as server:
    ...
```

For a full pause/resume flow, see [Human-in-the-loop](human_in_the_loop.md) and `examples/mcp/get_all_mcp_tools_example/main.py`.

### Per-call metadata with `tool_meta_resolver`

Use `tool_meta_resolver` when your MCP server expects request metadata in `_meta` (for example, tenant IDs or trace context). The example below assumes you pass a `dict` as `context` to `Runner.run(...)`.

```python
from agents.mcp import MCPServerStreamableHttp, MCPToolMetaContext


def resolve_meta(context: MCPToolMetaContext) -> dict[str, str] | None:
    run_context_data = context.run_context.context or {}
    tenant_id = run_context_data.get("tenant_id")
    if tenant_id is None:
        return None
    return {"tenant_id": str(tenant_id), "source": "agents-sdk"}


server = MCPServerStreamableHttp(
    name="Metadata-aware MCP",
    params={"url": "http://localhost:8000/mcp"},
    tool_meta_resolver=resolve_meta,
)
```

If your run context is a Pydantic model, dataclass, or custom class, read the tenant ID with attribute access instead.

### MCP tool outputs: text and images

When an MCP tool returns image content, the SDK maps it to image tool output entries automatically. Mixed text/image responses are forwarded as a list of output items, so agents can consume MCP image results the same way they consume image output from regular function tools.

## 3. HTTP with SSE MCP servers

!!! warning

    The MCP project has deprecated the Server-Sent Events transport. Prefer Streamable HTTP or stdio for new integrations and keep SSE only for legacy servers.

If the MCP server implements the HTTP with SSE transport, instantiate
[`MCPServerSse`][agents.mcp.server.MCPServerSse]. Apart from the transport, the API is identical to the Streamable HTTP server.

```python

from agents import Agent, Runner
from agents.model_settings import ModelSettings
from agents.mcp import MCPServerSse

workspace_id = "demo-workspace"

async with MCPServerSse(
    name="SSE Python Server",
    params={
        "url": "http://localhost:8000/sse",
        "headers": {"X-Workspace": workspace_id},
    },
    cache_tools_list=True,
) as server:
    agent = Agent(
        name="Assistant",
        mcp_servers=[server],
        model_settings=ModelSettings(tool_choice="required"),
    )
    result = await Runner.run(agent, "What's the weather in Tokyo?")
    print(result.final_output)
```

## 4. stdio MCP servers

For MCP servers that run as local subprocesses, use [`MCPServerStdio`][agents.mcp.server.MCPServerStdio]. The SDK spawns the
process, keeps the pipes open, and closes them automatically when the context manager exits. This option is helpful for quick
proofs of concept or when the server only exposes a command line entry point.

```python
from pathlib import Path
from agents import Agent, Runner
from agents.mcp import MCPServerStdio

current_dir = Path(__file__).parent
samples_dir = current_dir / "sample_files"

async with MCPServerStdio(
    name="Filesystem Server via npx",
    params={
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-filesystem", str(samples_dir)],
    },
) as server:
    agent = Agent(
        name="Assistant",
        instructions="Use the files in the sample directory to answer questions.",
        mcp_servers=[server],
    )
    result = await Runner.run(agent, "List the files available to you.")
    print(result.final_output)
```

## 5. MCP server manager

When you have multiple MCP servers, use `MCPServerManager` to connect them up front and expose the connected subset to your agents.
See the [MCPServerManager API reference](ref/mcp/manager.md) for constructor options and reconnect behavior.

```python
from agents import Agent, Runner
from agents.mcp import MCPServerManager, MCPServerStreamableHttp

servers = [
    MCPServerStreamableHttp(name="calendar", params={"url": "http://localhost:8000/mcp"}),
    MCPServerStreamableHttp(name="docs", params={"url": "http://localhost:8001/mcp"}),
]

async with MCPServerManager(servers) as manager:
    agent = Agent(
        name="Assistant",
        instructions="Use MCP tools when they help.",
        mcp_servers=manager.active_servers,
    )
    result = await Runner.run(agent, "Which MCP tools are available?")
    print(result.final_output)
```

Key behaviors:

- `active_servers` includes only successfully connected servers when `drop_failed_servers=True` (the default).
- Failures are tracked in `failed_servers` and `errors`.
- Set `strict=True` to raise on the first connection failure.
- Call `reconnect(failed_only=True)` to retry failed servers, or `reconnect(failed_only=False)` to restart all servers.
- Use `connect_timeout_seconds`, `cleanup_timeout_seconds`, and `connect_in_parallel` to tune lifecycle behavior.

## Common server capabilities

The sections below apply across MCP server transports (with the exact API surface depending on the server class).

## Tool filtering

Each MCP server supports tool filters so that you can expose only the functions that your agent needs. Filtering can happen at
construction time or dynamically per run.

### Static tool filtering

Use [`create_static_tool_filter`][agents.mcp.create_static_tool_filter] to configure simple allow/block lists:

```python
from pathlib import Path

from agents.mcp import MCPServerStdio, create_static_tool_filter

samples_dir = Path("/path/to/files")

filesystem_server = MCPServerStdio(
    params={
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-filesystem", str(samples_dir)],
    },
    tool_filter=create_static_tool_filter(allowed_tool_names=["read_file", "write_file"]),
)
```

When both `allowed_tool_names` and `blocked_tool_names` are supplied the SDK applies the allow-list first and then removes any
blocked tools from the remaining set.

### Dynamic tool filtering

For more elaborate logic pass a callable that receives a [`ToolFilterContext`][agents.mcp.ToolFilterContext]. The callable can be
synchronous or asynchronous and returns `True` when the tool should be exposed.

```python
from pathlib import Path

from agents.mcp import MCPServerStdio, ToolFilterContext

samples_dir = Path("/path/to/files")

async def context_aware_filter(context: ToolFilterContext, tool) -> bool:
    if context.agent.name == "Code Reviewer" and tool.name.startswith("danger_"):
        return False
    return True

async with MCPServerStdio(
    params={
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-filesystem", str(samples_dir)],
    },
    tool_filter=context_aware_filter,
) as server:
    ...
```

The filter context exposes the active `run_context`, the `agent` requesting the tools, and the `server_name`.

## Prompts

MCP servers can also provide prompts that dynamically generate agent instructions. Servers that support prompts expose two
methods:

- `list_prompts()` enumerates the available prompt templates.
- `get_prompt(name, arguments)` fetches a concrete prompt, optionally with parameters.

```python
from agents import Agent

prompt_result = await server.get_prompt(
    "generate_code_review_instructions",
    {"focus": "security vulnerabilities", "language": "python"},
)
instructions = prompt_result.messages[0].content.text

agent = Agent(
    name="Code Reviewer",
    instructions=instructions,
    mcp_servers=[server],
)
```

## Caching

Every agent run calls `list_tools()` on each MCP server. Remote servers can introduce noticeable latency, so all of the MCP
server classes expose a `cache_tools_list` option. Set it to `True` only if you are confident that the tool definitions do not
change frequently. To force a fresh list later, call `invalidate_tools_cache()` on the server instance.

## Tracing

[Tracing](./tracing.md) automatically captures MCP activity, including:

1. Calls to the MCP server to list tools.
2. MCP-related information on tool calls.

![MCP Tracing Screenshot](./assets/images/mcp-tracing.jpg)

## Further reading

- [Model Context Protocol](https://modelcontextprotocol.io/) – the specification and design guides.
- [examples/mcp](https://github.com/openai/openai-agents-python/tree/main/examples/mcp) – runnable stdio, SSE, and Streamable HTTP samples.
- [examples/hosted_mcp](https://github.com/openai/openai-agents-python/tree/main/examples/hosted_mcp) – complete hosted MCP demonstrations including approvals and connectors.

================
File: docs/multi_agent.md
================
# Agent orchestration

Orchestration refers to the flow of agents in your app. Which agents run, in what order, and how do they decide what happens next? There are two main ways to orchestrate agents:

1. Allowing the LLM to make decisions: this uses the intelligence of an LLM to plan, reason, and decide on what steps to take based on that.
2. Orchestrating via code: determining the flow of agents via your code.

You can mix and match these patterns. Each has their own tradeoffs, described below.

## Orchestrating via LLM

An agent is an LLM equipped with instructions, tools and handoffs. This means that given an open-ended task, the LLM can autonomously plan how it will tackle the task, using tools to take actions and acquire data, and using handoffs to delegate tasks to sub-agents. For example, a research agent could be equipped with tools like:

-   Web search to find information online
-   File search and retrieval to search through proprietary data and connections
-   Computer use to take actions on a computer
-   Code execution to do data analysis
-   Handoffs to specialized agents that are great at planning, report writing and more.

### Core SDK patterns

In the Python SDK, two orchestration patterns come up most often:

| Pattern | How it works | Best when |
| --- | --- | --- |
| Agents as tools | A manager agent keeps control of the conversation and calls specialist agents through `Agent.as_tool()`. | You want one agent to own the final answer, combine outputs from multiple specialists, or enforce shared guardrails in one place. |
| Handoffs | A triage agent routes the conversation to a specialist, and that specialist becomes the active agent for the rest of the turn. | You want the specialist to respond directly, keep prompts focused, or swap instructions without the manager narrating the result. |

Use **agents as tools** when a specialist should help with a bounded subtask but should not take over the user-facing conversation. Use **handoffs** when routing itself is part of the workflow and you want the chosen specialist to own the next part of the interaction.

You can also combine the two. A triage agent might hand off to a specialist, and that specialist can still call other agents as tools for narrow subtasks.

This pattern is great when the task is open-ended and you want to rely on the intelligence of an LLM. The most important tactics here are:

1. Invest in good prompts. Make it clear what tools are available, how to use them, and what parameters it must operate within.
2. Monitor your app and iterate on it. See where things go wrong, and iterate on your prompts.
3. Allow the agent to introspect and improve. For example, run it in a loop, and let it critique itself; or, provide error messages and let it improve.
4. Have specialized agents that excel in one task, rather than having a general purpose agent that is expected to be good at anything.
5. Invest in [evals](https://platform.openai.com/docs/guides/evals). This lets you train your agents to improve and get better at tasks.

If you want the core SDK primitives behind this style of orchestration, start with [tools](tools.md), [handoffs](handoffs.md), and [running agents](running_agents.md).

## Orchestrating via code

While orchestrating via LLM is powerful, orchestrating via code makes tasks more deterministic and predictable, in terms of speed, cost and performance. Common patterns here are:

-   Using [structured outputs](https://platform.openai.com/docs/guides/structured-outputs) to generate well formed data that you can inspect with your code. For example, you might ask an agent to classify the task into a few categories, and then pick the next agent based on the category.
-   Chaining multiple agents by transforming the output of one into the input of the next. You can decompose a task like writing a blog post into a series of steps - do research, write an outline, write the blog post, critique it, and then improve it.
-   Running the agent that performs the task in a `while` loop with an agent that evaluates and provides feedback, until the evaluator says the output passes certain criteria.
-   Running multiple agents in parallel, e.g. via Python primitives like `asyncio.gather`. This is useful for speed when you have multiple tasks that don't depend on each other.

We have a number of examples in [`examples/agent_patterns`](https://github.com/openai/openai-agents-python/tree/main/examples/agent_patterns).

## Related guides

-   [Agents](agents.md) for composition patterns and agent configuration.
-   [Tools](tools.md#agents-as-tools) for `Agent.as_tool()` and manager-style orchestration.
-   [Handoffs](handoffs.md) for delegation between specialist agents.
-   [Running agents](running_agents.md) for per-run orchestration controls and conversation state.
-   [Quickstart](quickstart.md) for a minimal end-to-end handoff example.

================
File: docs/quickstart.md
================
# Quickstart

## Create a project and virtual environment

You'll only need to do this once.

```bash
mkdir my_project
cd my_project
python -m venv .venv
```

### Activate the virtual environment

Do this every time you start a new terminal session.

```bash
source .venv/bin/activate
```

### Install the Agents SDK

```bash
pip install openai-agents # or `uv add openai-agents`, etc
```

### Set an OpenAI API key

If you don't have one, follow [these instructions](https://platform.openai.com/docs/quickstart#create-and-export-an-api-key) to create an OpenAI API key.

```bash
export OPENAI_API_KEY=sk-...
```

## Create your first agent

Agents are defined with instructions, a name, and optional configuration such as a specific model.

```python
from agents import Agent

agent = Agent(
    name="History Tutor",
    instructions="You answer history questions clearly and concisely.",
)
```

## Run your first agent

Use [`Runner`][agents.run.Runner] to execute the agent and get a [`RunResult`][agents.result.RunResult] back.

```python
import asyncio
from agents import Agent, Runner

agent = Agent(
    name="History Tutor",
    instructions="You answer history questions clearly and concisely.",
)

async def main():
    result = await Runner.run(agent, "When did the Roman Empire fall?")
    print(result.final_output)

if __name__ == "__main__":
    asyncio.run(main())
```

For a second turn, you can either pass `result.to_input_list()` back into `Runner.run(...)`, attach a [session](sessions/index.md), or reuse OpenAI server-managed state with `conversation_id` / `previous_response_id`. The [running agents](running_agents.md) guide compares these approaches.

Use this rule of thumb:

| If you want... | Start with... |
| --- | --- |
| Full manual control and provider-agnostic history | `result.to_input_list()` |
| The SDK to load and save history for you | [`session=...`](sessions/index.md) |
| OpenAI-managed server-side continuation | `previous_response_id` or `conversation_id` |

For the tradeoffs and exact behaviors, see [Running agents](running_agents.md#choose-a-memory-strategy).

## Give your agent tools

You can give an agent tools to look up information or perform actions.

```python
import asyncio
from agents import Agent, Runner, function_tool


@function_tool
def history_fun_fact() -> str:
    """Return a short history fact."""
    return "Sharks are older than trees."


agent = Agent(
    name="History Tutor",
    instructions="Answer history questions clearly. Use history_fun_fact when it helps.",
    tools=[history_fun_fact],
)


async def main():
    result = await Runner.run(
        agent,
        "Tell me something surprising about ancient life on Earth.",
    )
    print(result.final_output)


if __name__ == "__main__":
    asyncio.run(main())
```

## Add a few more agents

Before you choose a multi-agent pattern, decide who should own the final answer:

-   **Handoffs**: a specialist takes over the conversation for that part of the turn.
-   **Agents as tools**: an orchestrator stays in control and calls specialists as tools.

This quickstart continues with **handoffs** because it is the shortest first example. For the manager-style pattern, see [Agent orchestration](multi_agent.md) and [Tools: agents as tools](tools.md#agents-as-tools).

Additional agents can be defined in the same way. `handoff_description` gives the routing agent extra context about when to delegate.

```python
from agents import Agent

history_tutor_agent = Agent(
    name="History Tutor",
    handoff_description="Specialist agent for historical questions",
    instructions="You answer history questions clearly and concisely.",
)

math_tutor_agent = Agent(
    name="Math Tutor",
    handoff_description="Specialist agent for math questions",
    instructions="You explain math step by step and include worked examples.",
)
```

## Define your handoffs

On an agent, you can define an inventory of outgoing handoff options that it can choose from while solving the task.

```python
triage_agent = Agent(
    name="Triage Agent",
    instructions="Route each homework question to the right specialist.",
    handoffs=[history_tutor_agent, math_tutor_agent],
)
```

## Run the agent orchestration

The runner handles executing individual agents, any handoffs, and any tool calls.

```python
import asyncio
from agents import Runner


async def main():
    result = await Runner.run(
        triage_agent,
        "Who was the first president of the United States?",
    )
    print(result.final_output)
    print(f"Answered by: {result.last_agent.name}")


if __name__ == "__main__":
    asyncio.run(main())
```

## Reference examples

The repository includes full scripts for the same core patterns:

-   [`examples/basic/hello_world.py`](https://github.com/openai/openai-agents-python/tree/main/examples/basic/hello_world.py) for the first run.
-   [`examples/basic/tools.py`](https://github.com/openai/openai-agents-python/tree/main/examples/basic/tools.py) for function tools.
-   [`examples/agent_patterns/routing.py`](https://github.com/openai/openai-agents-python/tree/main/examples/agent_patterns/routing.py) for multi-agent routing.

## View your traces

To review what happened during your agent run, navigate to the [Trace viewer in the OpenAI Dashboard](https://platform.openai.com/traces) to view traces of your agent runs.

## Next steps

Learn how to build more complex agentic flows:

-   Learn about how to configure [Agents](agents.md).
-   Learn about [running agents](running_agents.md) and [sessions](sessions/index.md).
-   Learn about [tools](tools.md), [guardrails](guardrails.md) and [models](models/index.md).

================
File: docs/release.md
================
# Release process/changelog

The project follows a slightly modified version of semantic versioning using the form `0.Y.Z`. The leading `0` indicates the SDK is still evolving rapidly. Increment the components as follows:

## Minor (`Y`) versions

We will increase minor versions `Y` for **breaking changes** to any public interfaces that are not marked as beta. For example, going from `0.0.x` to `0.1.x` might include breaking changes.

If you don't want breaking changes, we recommend pinning to `0.0.x` versions in your project.

## Patch (`Z`) versions

We will increment `Z` for non-breaking changes:

-   Bug fixes
-   New features
-   Changes to private interfaces
-   Updates to beta features

## Breaking change changelog

### 0.10.0

This minor release does **not** introduce a breaking change, but it includes a significant new feature area for OpenAI Responses users: websocket transport support for the Responses API.

Highlights:

-   Added websocket transport support for OpenAI Responses models (opt-in; HTTP remains the default transport).
-   Added a `responses_websocket_session()` helper / `ResponsesWebSocketSession` for reusing a shared websocket-capable provider and `RunConfig` across multi-turn runs.
-   Added a new websocket streaming example (`examples/basic/stream_ws.py`) covering streaming, tools, approvals, and follow-up turns.

### 0.9.0

In this version, Python 3.9 is no longer supported, as this major version reached EOL three months ago. Please upgrade to a newer runtime version.

Additionally, the type hint for the value returned from the `Agent#as_tool()` method has been narrowed from `Tool` to `FunctionTool`. This change should not usually cause breaking issues, but if your code relies on the broader union type, you may need to make some adjustments on your side.

### 0.8.0

In this version, two runtime behavior changes may require migration work:

- Function tools wrapping **synchronous** Python callables now execute on worker threads via `asyncio.to_thread(...)` instead of running on the event loop thread. If your tool logic depends on thread-local state or thread-affine resources, migrate to an async tool implementation or make thread affinity explicit in your tool code.
- Local MCP tool failure handling is now configurable, and the default behavior can return model-visible error output instead of failing the whole run. If you rely on fail-fast semantics, set `mcp_config={"failure_error_function": None}`. Server-level `failure_error_function` values override the agent-level setting, so set `failure_error_function=None` on each local MCP server that has an explicit handler.

### 0.7.0

In this version, there were a few behavior changes that can affect existing applications:

- Nested handoff history is now **opt-in** (disabled by default). If you depended on the v0.6.x default nested behavior, explicitly set `RunConfig(nest_handoff_history=True)`.
- The default `reasoning.effort` for `gpt-5.1` / `gpt-5.2` changed to `"none"` (from the previous default `"low"` configured by SDK defaults). If your prompts or quality/cost profile relied on `"low"`, set it explicitly in `model_settings`.

### 0.6.0

In this version, the default handoff history is now packaged into a single assistant message instead of exposing the raw user/assistant turns, giving downstream agents a concise, predictable recap
- The existing single-message handoff transcript now by default starts with "For context, here is the conversation so far between the user and the previous agent:" before the `<CONVERSATION HISTORY>` block, so downstream agents get a clearly labeled recap

### 0.5.0

This version doesn’t introduce any visible breaking changes, but it includes new features and a few significant updates under the hood:

- Added support for `RealtimeRunner` to handle [SIP protocol connections](https://platform.openai.com/docs/guides/realtime-sip)
- Significantly revised the internal logic of `Runner#run_sync` for Python 3.14 compatibility

### 0.4.0

In this version, [openai](https://pypi.org/project/openai/) package v1.x versions are no longer supported. Please use openai v2.x along with this SDK.

### 0.3.0

In this version, the Realtime API support migrates to gpt-realtime model and its API interface (GA version).

### 0.2.0

In this version, a few places that used to take `Agent` as an arg, now take `AgentBase` as an arg instead. For example, the `list_tools()` call in MCP servers. This is a purely typing change, you will still receive `Agent` objects. To update, just fix type errors by replacing `Agent` with `AgentBase`.

### 0.1.0

In this version, [`MCPServer.list_tools()`][agents.mcp.server.MCPServer] has two new params: `run_context` and `agent`. You'll need to add these params to any classes that subclass `MCPServer`.

================
File: docs/repl.md
================
# REPL utility

The SDK provides `run_demo_loop` for quick, interactive testing of an agent's behavior directly in your terminal.


```python
import asyncio
from agents import Agent, run_demo_loop

async def main() -> None:
    agent = Agent(name="Assistant", instructions="You are a helpful assistant.")
    await run_demo_loop(agent)

if __name__ == "__main__":
    asyncio.run(main())
```

`run_demo_loop` prompts for user input in a loop, keeping the conversation history between turns. By default, it streams model output as it is produced. When you run the example above, run_demo_loop starts an interactive chat session. It continuously asks for your input, remembers the entire conversation history between turns (so your agent knows what's been discussed) and automatically streams the agent's responses to you in real-time as they are generated.

To end this chat session, simply type `quit` or `exit` (and press Enter) or use the `Ctrl-D` keyboard shortcut.

================
File: docs/results.md
================
# Results

When you call the `Runner.run` methods, you receive one of two result types:

-   [`RunResult`][agents.result.RunResult] from `Runner.run(...)` or `Runner.run_sync(...)`
-   [`RunResultStreaming`][agents.result.RunResultStreaming] from `Runner.run_streamed(...)`

Both inherit from [`RunResultBase`][agents.result.RunResultBase], which exposes the shared result surfaces such as `final_output`, `new_items`, `last_agent`, `raw_responses`, and `to_state()`.

`RunResultStreaming` adds streaming-specific controls such as [`stream_events()`][agents.result.RunResultStreaming.stream_events], [`current_agent`][agents.result.RunResultStreaming.current_agent], [`is_complete`][agents.result.RunResultStreaming.is_complete], and [`cancel(...)`][agents.result.RunResultStreaming.cancel].

## Choose the right result surface

Most applications only need a few result properties or helpers:

| If you need... | Use |
| --- | --- |
| The final answer to show the user | `final_output` |
| A replay-ready next-turn input list with the full local transcript | `to_input_list()` |
| Rich run items with agent, tool, handoff, and approval metadata | `new_items` |
| The agent that should usually handle the next user turn | `last_agent` |
| OpenAI Responses API chaining with `previous_response_id` | `last_response_id` |
| Pending approvals and a resumable snapshot | `interruptions` and `to_state()` |
| Metadata about the current nested `Agent.as_tool()` invocation | `agent_tool_invocation` |
| Raw model calls or guardrail diagnostics | `raw_responses` and the guardrail result arrays |

## Final output

The [`final_output`][agents.result.RunResultBase.final_output] property contains the final output of the last agent that ran. This is either:

-   a `str`, if the last agent did not have an `output_type` defined
-   an object of type `last_agent.output_type`, if the last agent had an output type defined
-   `None`, if the run stopped before a final output was produced, for example because it paused on an approval interruption

!!! note

    `final_output` is typed as `Any`. Handoffs can change which agent finishes the run, so the SDK cannot statically know the full set of possible output types.

In streaming mode, `final_output` stays `None` until the stream has finished processing. See [Streaming](streaming.md) for the event-by-event flow.

## Input, next-turn history, and new items

These surfaces answer different questions:

| Property or helper | What it contains | Best for |
| --- | --- | --- |
| [`input`][agents.result.RunResultBase.input] | The base input for this run segment. If a handoff input filter rewrote the history, this reflects the filtered input the run continued with. | Auditing what this run actually used as input |
| [`to_input_list()`][agents.result.RunResultBase.to_input_list] | A replay-ready next-turn input list built from `input` plus the converted `new_items` from this run. | Manual chat loops and client-managed conversation state |
| [`new_items`][agents.result.RunResultBase.new_items] | Rich [`RunItem`][agents.items.RunItem] wrappers with agent, tool, handoff, and approval metadata. | Logs, UIs, audits, and debugging |
| [`raw_responses`][agents.result.RunResultBase.raw_responses] | Raw [`ModelResponse`][agents.items.ModelResponse] objects from each model call in the run. | Provider-level diagnostics or raw response inspection |

In practice:

-   Use `to_input_list()` when your application manually carries the entire conversation transcript.
-   Use [`session=...`](sessions/index.md) when you want the SDK to load and save history for you.
-   If you are using OpenAI server-managed state with `conversation_id` or `previous_response_id`, usually pass only the new user input and reuse the stored ID instead of resending `to_input_list()`.

Unlike the JavaScript SDK, Python does not expose a separate `output` property for the model-shaped delta only. Use `new_items` when you need SDK metadata, or inspect `raw_responses` when you need the raw model payloads.

### New items

[`new_items`][agents.result.RunResultBase.new_items] gives you the richest view of what happened during the run. Common item types are:

-   [`MessageOutputItem`][agents.items.MessageOutputItem] for assistant messages
-   [`ReasoningItem`][agents.items.ReasoningItem] for reasoning items
-   [`ToolCallItem`][agents.items.ToolCallItem] and [`ToolCallOutputItem`][agents.items.ToolCallOutputItem] for tool calls and their results
-   [`ToolApprovalItem`][agents.items.ToolApprovalItem] for tool calls that paused for approval
-   [`HandoffCallItem`][agents.items.HandoffCallItem] and [`HandoffOutputItem`][agents.items.HandoffOutputItem] for handoff requests and completed transfers

Choose `new_items` over `to_input_list()` whenever you need agent associations, tool outputs, handoff boundaries, or approval boundaries.

## Continue or resume the conversation

### Next-turn agent

[`last_agent`][agents.result.RunResultBase.last_agent] contains the last agent that ran. This is often the best agent to reuse for the next user turn after handoffs.

In streaming mode, [`RunResultStreaming.current_agent`][agents.result.RunResultStreaming.current_agent] updates as the run progresses, so you can observe handoffs before the stream finishes.

### Interruptions and run state

If a tool needs approval, pending approvals are exposed in [`RunResult.interruptions`][agents.result.RunResult.interruptions] or [`RunResultStreaming.interruptions`][agents.result.RunResultStreaming.interruptions]. This can include approvals raised by direct tools, by tools reached after a handoff, or by nested [`Agent.as_tool()`][agents.agent.Agent.as_tool] runs.

Call [`to_state()`][agents.result.RunResult.to_state] to capture a resumable [`RunState`][agents.run_state.RunState], approve or reject the pending items, and then resume with `Runner.run(...)` or `Runner.run_streamed(...)`.

```python
from agents import Agent, Runner

agent = Agent(name="Assistant", instructions="Use tools when needed.")
result = await Runner.run(agent, "Delete temp files that are no longer needed.")

if result.interruptions:
    state = result.to_state()
    for interruption in result.interruptions:
        state.approve(interruption)
    result = await Runner.run(agent, state)
```

For streaming runs, finish consuming [`stream_events()`][agents.result.RunResultStreaming.stream_events] first, then inspect `result.interruptions` and resume from `result.to_state()`. For the full approval flow, see [Human-in-the-loop](human_in_the_loop.md).

### Server-managed continuation

[`last_response_id`][agents.result.RunResultBase.last_response_id] is the latest model response ID from the run. Pass it back as `previous_response_id` on the next turn when you want to continue an OpenAI Responses API chain.

If you already continue the conversation with `to_input_list()`, `session`, or `conversation_id`, you usually do not need `last_response_id`. If you need every model response from a multi-step run, inspect `raw_responses` instead.

## Agent-as-tool metadata

When a result comes from a nested [`Agent.as_tool()`][agents.agent.Agent.as_tool] run, [`agent_tool_invocation`][agents.result.RunResultBase.agent_tool_invocation] exposes immutable metadata about the outer tool call:

-   `tool_name`
-   `tool_call_id`
-   `tool_arguments`

For ordinary top-level runs, `agent_tool_invocation` is `None`.

This is especially useful inside `custom_output_extractor`, where you may need the outer tool name, call ID, or raw arguments while post-processing the nested result. See [Tools](tools.md) for the surrounding `Agent.as_tool()` patterns.

If you also need the parsed structured input for that nested run, read `context_wrapper.tool_input`. That is the field [`RunState`][agents.run_state.RunState] serializes generically for nested tool input, while `agent_tool_invocation` is the live result accessor for the current nested invocation.

## Streaming lifecycle and diagnostics

[`RunResultStreaming`][agents.result.RunResultStreaming] inherits the same result surfaces above, but adds streaming-specific controls:

-   [`stream_events()`][agents.result.RunResultStreaming.stream_events] to consume semantic stream events
-   [`current_agent`][agents.result.RunResultStreaming.current_agent] to track the active agent mid-run
-   [`is_complete`][agents.result.RunResultStreaming.is_complete] to see whether the streamed run has fully finished
-   [`cancel(...)`][agents.result.RunResultStreaming.cancel] to stop the run immediately or after the current turn

Keep consuming `stream_events()` until the async iterator finishes. A streaming run is not complete until that iterator ends, and summary properties such as `final_output`, `interruptions`, `raw_responses`, and session-persistence side effects may still be settling after the last visible token arrives.

If you call `cancel()`, continue consuming `stream_events()` so cancellation and cleanup can finish correctly.

Python does not expose a separate streamed `completed` promise or `error` property. Terminal streaming failures are surfaced by raising from `stream_events()`, and `is_complete` reflects whether the run has reached its terminal state.

### Raw responses

[`raw_responses`][agents.result.RunResultBase.raw_responses] contains the raw model responses collected during the run. Multi-step runs can produce more than one response, for example across handoffs or repeated model/tool/model cycles.

[`last_response_id`][agents.result.RunResultBase.last_response_id] is just the ID from the last entry in `raw_responses`.

### Guardrail results

Agent-level guardrails are exposed as [`input_guardrail_results`][agents.result.RunResultBase.input_guardrail_results] and [`output_guardrail_results`][agents.result.RunResultBase.output_guardrail_results].

Tool guardrails are exposed separately as [`tool_input_guardrail_results`][agents.result.RunResultBase.tool_input_guardrail_results] and [`tool_output_guardrail_results`][agents.result.RunResultBase.tool_output_guardrail_results].

These arrays accumulate across the run, so they are useful for logging decisions, storing extra guardrail metadata, or debugging why a run was blocked.

### Context and usage

[`context_wrapper`][agents.result.RunResultBase.context_wrapper] exposes your app context together with SDK-managed runtime metadata such as approvals, usage, and nested `tool_input`.

Usage is tracked on `context_wrapper.usage`. For streamed runs, the usage totals can lag until the stream's final chunks have been processed. See [Context management](context.md) for the full wrapper shape and persistence caveats.

================
File: docs/running_agents.md
================
# Running agents

You can run agents via the [`Runner`][agents.run.Runner] class. You have 3 options:

1. [`Runner.run()`][agents.run.Runner.run], which runs async and returns a [`RunResult`][agents.result.RunResult].
2. [`Runner.run_sync()`][agents.run.Runner.run_sync], which is a sync method and just runs `.run()` under the hood.
3. [`Runner.run_streamed()`][agents.run.Runner.run_streamed], which runs async and returns a [`RunResultStreaming`][agents.result.RunResultStreaming]. It calls the LLM in streaming mode, and streams those events to you as they are received.

```python
from agents import Agent, Runner

async def main():
    agent = Agent(name="Assistant", instructions="You are a helpful assistant")

    result = await Runner.run(agent, "Write a haiku about recursion in programming.")
    print(result.final_output)
    # Code within the code,
    # Functions calling themselves,
    # Infinite loop's dance
```

Read more in the [results guide](results.md).

## Runner lifecycle and configuration

### The agent loop

When you use the run method in `Runner`, you pass in a starting agent and input. The input can be:

-   a string (treated as a user message),
-   a list of input items in the OpenAI Responses API format, or
-   a [`RunState`][agents.run_state.RunState] when resuming an interrupted run.

The runner then runs a loop:

1. We call the LLM for the current agent, with the current input.
2. The LLM produces its output.
    1. If the LLM returns a `final_output`, the loop ends and we return the result.
    2. If the LLM does a handoff, we update the current agent and input, and re-run the loop.
    3. If the LLM produces tool calls, we run those tool calls, append the results, and re-run the loop.
3. If we exceed the `max_turns` passed, we raise a [`MaxTurnsExceeded`][agents.exceptions.MaxTurnsExceeded] exception.

!!! note

    The rule for whether the LLM output is considered as a "final output" is that it produces text output with the desired type, and there are no tool calls.

### Streaming

Streaming allows you to additionally receive streaming events as the LLM runs. Once the stream is done, the [`RunResultStreaming`][agents.result.RunResultStreaming] will contain the complete information about the run, including all the new outputs produced. You can call `.stream_events()` for the streaming events. Read more in the [streaming guide](streaming.md).

#### Responses WebSocket transport (optional helper)

If you enable the OpenAI Responses websocket transport, you can keep using the normal `Runner` APIs. The websocket session helper is recommended for connection reuse, but it is not required.

This is the Responses API over websocket transport, not the [Realtime API](realtime/guide.md).

For transport-selection rules and caveats around concrete model objects or custom providers, see [Models](models/index.md#responses-websocket-transport).

##### Pattern 1: No session helper (works)

Use this when you just want websocket transport and do not need the SDK to manage a shared provider/session for you.

```python
import asyncio

from agents import Agent, Runner, set_default_openai_responses_transport


async def main():
    set_default_openai_responses_transport("websocket")

    agent = Agent(name="Assistant", instructions="Be concise.")
    result = Runner.run_streamed(agent, "Summarize recursion in one sentence.")

    async for event in result.stream_events():
        if event.type == "raw_response_event":
            continue
        print(event.type)


asyncio.run(main())
```

This pattern is fine for single runs. If you call `Runner.run()` / `Runner.run_streamed()` repeatedly, each run may reconnect unless you manually reuse the same `RunConfig` / provider instance.

##### Pattern 2: Use `responses_websocket_session()` (recommended for multi-turn reuse)

Use [`responses_websocket_session()`][agents.responses_websocket_session] when you want a shared websocket-capable provider and `RunConfig` across multiple runs (including nested agent-as-tool calls that inherit the same `run_config`).

```python
import asyncio

from agents import Agent, responses_websocket_session


async def main():
    agent = Agent(name="Assistant", instructions="Be concise.")

    async with responses_websocket_session() as ws:
        first = ws.run_streamed(agent, "Say hello in one short sentence.")
        async for _event in first.stream_events():
            pass

        second = ws.run_streamed(
            agent,
            "Now say goodbye.",
            previous_response_id=first.last_response_id,
        )
        async for _event in second.stream_events():
            pass


asyncio.run(main())
```

Finish consuming streamed results before the context exits. Exiting the context while a websocket request is still in flight may force-close the shared connection.

### Run config

The `run_config` parameter lets you configure some global settings for the agent run:

#### Common run config categories

Use `RunConfig` to override behavior for a single run without changing each agent definition.

##### Model, provider, and session defaults

-   [`model`][agents.run.RunConfig.model]: Allows setting a global LLM model to use, irrespective of what `model` each Agent has.
-   [`model_provider`][agents.run.RunConfig.model_provider]: A model provider for looking up model names, which defaults to OpenAI.
-   [`model_settings`][agents.run.RunConfig.model_settings]: Overrides agent-specific settings. For example, you can set a global `temperature` or `top_p`.
-   [`session_settings`][agents.run.RunConfig.session_settings]: Overrides session-level defaults (for example, `SessionSettings(limit=...)`) when retrieving history during a run.
-   [`session_input_callback`][agents.run.RunConfig.session_input_callback]: Customize how new user input is merged with session history before each turn when using Sessions. The callback can be sync or async.

##### Guardrails, handoffs, and model input shaping

-   [`input_guardrails`][agents.run.RunConfig.input_guardrails], [`output_guardrails`][agents.run.RunConfig.output_guardrails]: A list of input or output guardrails to include on all runs.
-   [`handoff_input_filter`][agents.run.RunConfig.handoff_input_filter]: A global input filter to apply to all handoffs, if the handoff doesn't already have one. The input filter allows you to edit the inputs that are sent to the new agent. See the documentation in [`Handoff.input_filter`][agents.handoffs.Handoff.input_filter] for more details.
-   [`nest_handoff_history`][agents.run.RunConfig.nest_handoff_history]: Opt-in beta that collapses the prior transcript into a single assistant message before invoking the next agent. This is disabled by default while we stabilize nested handoffs; set to `True` to enable or leave `False` to pass through the raw transcript. All [Runner methods][agents.run.Runner] automatically create a `RunConfig` when you do not pass one, so the quickstarts and examples keep the default off, and any explicit [`Handoff.input_filter`][agents.handoffs.Handoff.input_filter] callbacks continue to override it. Individual handoffs can override this setting via [`Handoff.nest_handoff_history`][agents.handoffs.Handoff.nest_handoff_history].
-   [`handoff_history_mapper`][agents.run.RunConfig.handoff_history_mapper]: Optional callable that receives the normalized transcript (history + handoff items) whenever you opt in to `nest_handoff_history`. It must return the exact list of input items to forward to the next agent, allowing you to replace the built-in summary without writing a full handoff filter.
-   [`call_model_input_filter`][agents.run.RunConfig.call_model_input_filter]: Hook to edit the fully prepared model input (instructions and input items) immediately before the model call, e.g., to trim history or inject a system prompt.
-   [`reasoning_item_id_policy`][agents.run.RunConfig.reasoning_item_id_policy]: Control whether reasoning item IDs are preserved or omitted when the runner converts prior outputs into next-turn model input.

##### Tracing and observability

-   [`tracing_disabled`][agents.run.RunConfig.tracing_disabled]: Allows you to disable [tracing](tracing.md) for the entire run.
-   [`tracing`][agents.run.RunConfig.tracing]: Pass a [`TracingConfig`][agents.tracing.TracingConfig] to override exporters, processors, or tracing metadata for this run.
-   [`trace_include_sensitive_data`][agents.run.RunConfig.trace_include_sensitive_data]: Configures whether traces will include potentially sensitive data, such as LLM and tool call inputs/outputs.
-   [`workflow_name`][agents.run.RunConfig.workflow_name], [`trace_id`][agents.run.RunConfig.trace_id], [`group_id`][agents.run.RunConfig.group_id]: Sets the tracing workflow name, trace ID and trace group ID for the run. We recommend at least setting `workflow_name`. The group ID is an optional field that lets you link traces across multiple runs.
-   [`trace_metadata`][agents.run.RunConfig.trace_metadata]: Metadata to include on all traces.

##### Tool approval and tool error behavior

-   [`tool_error_formatter`][agents.run.RunConfig.tool_error_formatter]: Customize the model-visible message when a tool call is rejected during approval flows.

Nested handoffs are available as an opt-in beta. Enable the collapsed-transcript behavior by passing `RunConfig(nest_handoff_history=True)` or set `handoff(..., nest_handoff_history=True)` to turn it on for a specific handoff. If you prefer to keep the raw transcript (the default), leave the flag unset or provide a `handoff_input_filter` (or `handoff_history_mapper`) that forwards the conversation exactly as you need. To change the wrapper text used in the generated summary without writing a custom mapper, call [`set_conversation_history_wrappers`][agents.handoffs.set_conversation_history_wrappers] (and [`reset_conversation_history_wrappers`][agents.handoffs.reset_conversation_history_wrappers] to restore the defaults).

#### Run config details

##### `tool_error_formatter`

Use `tool_error_formatter` to customize the message that is returned to the model when a tool call is rejected in an approval flow.

The formatter receives [`ToolErrorFormatterArgs`][agents.run_config.ToolErrorFormatterArgs] with:

-   `kind`: The error category. Today this is `"approval_rejected"`.
-   `tool_type`: The tool runtime (`"function"`, `"computer"`, `"shell"`, or `"apply_patch"`).
-   `tool_name`: The tool name.
-   `call_id`: The tool call ID.
-   `default_message`: The SDK's default model-visible message.
-   `run_context`: The active run context wrapper.

Return a string to replace the message, or `None` to use the SDK default.

```python
from agents import Agent, RunConfig, Runner, ToolErrorFormatterArgs


def format_rejection(args: ToolErrorFormatterArgs[None]) -> str | None:
    if args.kind == "approval_rejected":
        return (
            f"Tool call '{args.tool_name}' was rejected by a human reviewer. "
            "Ask for confirmation or propose a safer alternative."
        )
    return None


agent = Agent(name="Assistant")
result = Runner.run_sync(
    agent,
    "Please delete the production database.",
    run_config=RunConfig(tool_error_formatter=format_rejection),
)
```

##### `reasoning_item_id_policy`

`reasoning_item_id_policy` controls how reasoning items are converted into next-turn model input when the runner carries history forward (for example, when using `RunResult.to_input_list()` or session-backed runs).

-   `None` or `"preserve"` (default): Keep reasoning item IDs.
-   `"omit"`: Strip reasoning item IDs from the generated next-turn input.

Use `"omit"` primarily as an opt-in mitigation for a class of Responses API 400 errors where a reasoning item is sent with an `id` but without the required following item (for example, `Item 'rs_...' of type 'reasoning' was provided without its required following item.`).

This can happen in multi-turn agent runs when the SDK constructs follow-up input from prior outputs (including session persistence, server-managed conversation deltas, streamed/non-streamed follow-up turns, and resume paths) and a reasoning item ID is preserved but the provider requires that ID to remain paired with its corresponding following item.

Setting `reasoning_item_id_policy="omit"` keeps the reasoning content but strips the reasoning item `id`, which avoids triggering that API invariant in SDK-generated follow-up inputs.

Scope notes:

-   This only changes reasoning items generated/forwarded by the SDK when it builds follow-up input.
-   It does not rewrite user-supplied initial input items.
-   `call_model_input_filter` can still intentionally reintroduce reasoning IDs after this policy is applied.

## State and conversation management

### Choose a memory strategy

There are four common ways to carry state into the next turn:

| Strategy | Where state lives | Best for | What you pass on the next turn |
| --- | --- | --- | --- |
| `result.to_input_list()` | Your app memory | Small chat loops, full manual control, any provider | The list from `result.to_input_list()` plus the next user message |
| `session` | Your storage plus the SDK | Persistent chat state, resumable runs, custom stores | The same `session` instance or another instance pointed at the same store |
| `conversation_id` | OpenAI Conversations API | A named server-side conversation you want to share across workers or services | The same `conversation_id` plus only the new user turn |
| `previous_response_id` | OpenAI Responses API | Lightweight server-managed continuation without creating a conversation resource | `result.last_response_id` plus only the new user turn |

`result.to_input_list()` and `session` are client-managed. `conversation_id` and `previous_response_id` are OpenAI-managed and only apply when you are using the OpenAI Responses API. In most applications, pick one persistence strategy per conversation. Mixing client-managed history with OpenAI-managed state can duplicate context unless you are deliberately reconciling both layers.

!!! note

    Session persistence cannot be combined with server-managed conversation settings
    (`conversation_id`, `previous_response_id`, or `auto_previous_response_id`) in the
    same run. Choose one approach per call.

### Conversations/chat threads

Calling any of the run methods can result in one or more agents running (and hence one or more LLM calls), but it represents a single logical turn in a chat conversation. For example:

1. User turn: user enter text
2. Runner run: first agent calls LLM, runs tools, does a handoff to a second agent, second agent runs more tools, and then produces an output.

At the end of the agent run, you can choose what to show to the user. For example, you might show the user every new item generated by the agents, or just the final output. Either way, the user might then ask a followup question, in which case you can call the run method again.

#### Manual conversation management

You can manually manage conversation history using the [`RunResultBase.to_input_list()`][agents.result.RunResultBase.to_input_list] method to get the inputs for the next turn:

```python
async def main():
    agent = Agent(name="Assistant", instructions="Reply very concisely.")

    thread_id = "thread_123"  # Example thread ID
    with trace(workflow_name="Conversation", group_id=thread_id):
        # First turn
        result = await Runner.run(agent, "What city is the Golden Gate Bridge in?")
        print(result.final_output)
        # San Francisco

        # Second turn
        new_input = result.to_input_list() + [{"role": "user", "content": "What state is it in?"}]
        result = await Runner.run(agent, new_input)
        print(result.final_output)
        # California
```

#### Automatic conversation management with sessions

For a simpler approach, you can use [Sessions](sessions/index.md) to automatically handle conversation history without manually calling `.to_input_list()`:

```python
from agents import Agent, Runner, SQLiteSession

async def main():
    agent = Agent(name="Assistant", instructions="Reply very concisely.")

    # Create session instance
    session = SQLiteSession("conversation_123")

    thread_id = "thread_123"  # Example thread ID
    with trace(workflow_name="Conversation", group_id=thread_id):
        # First turn
        result = await Runner.run(agent, "What city is the Golden Gate Bridge in?", session=session)
        print(result.final_output)
        # San Francisco

        # Second turn - agent automatically remembers previous context
        result = await Runner.run(agent, "What state is it in?", session=session)
        print(result.final_output)
        # California
```

Sessions automatically:

-   Retrieves conversation history before each run
-   Stores new messages after each run
-   Maintains separate conversations for different session IDs

See the [Sessions documentation](sessions/index.md) for more details.


#### Server-managed conversations

You can also let the OpenAI conversation state feature manage conversation state on the server side, instead of handling it locally with `to_input_list()` or `Sessions`. This allows you to preserve conversation history without manually resending all past messages. With either server-managed approach below, pass only the new turn's input on each request and reuse the saved ID. See the [OpenAI Conversation state guide](https://platform.openai.com/docs/guides/conversation-state?api-mode=responses) for more details.

OpenAI provides two ways to track state across turns:

##### 1. Using `conversation_id`

You first create a conversation using the OpenAI Conversations API and then reuse its ID for every subsequent call:

```python
from agents import Agent, Runner
from openai import AsyncOpenAI

client = AsyncOpenAI()

async def main():
    agent = Agent(name="Assistant", instructions="Reply very concisely.")

    # Create a server-managed conversation
    conversation = await client.conversations.create()
    conv_id = conversation.id

    while True:
        user_input = input("You: ")
        result = await Runner.run(agent, user_input, conversation_id=conv_id)
        print(f"Assistant: {result.final_output}")
```

##### 2. Using `previous_response_id`

Another option is **response chaining**, where each turn links explicitly to the response ID from the previous turn.

```python
from agents import Agent, Runner

async def main():
    agent = Agent(name="Assistant", instructions="Reply very concisely.")

    previous_response_id = None

    while True:
        user_input = input("You: ")

        # Setting auto_previous_response_id=True enables response chaining automatically
        # for the first turn, even when there's no actual previous response ID yet.
        result = await Runner.run(
            agent,
            user_input,
            previous_response_id=previous_response_id,
            auto_previous_response_id=True,
        )
        previous_response_id = result.last_response_id
        print(f"Assistant: {result.final_output}")
```

If a run pauses for approval and you resume from a [`RunState`][agents.run_state.RunState], the
SDK keeps the saved `conversation_id` / `previous_response_id` / `auto_previous_response_id`
settings so the resumed turn continues in the same server-managed conversation.

`conversation_id` and `previous_response_id` are mutually exclusive. Use `conversation_id` when you want a named conversation resource that can be shared across systems. Use `previous_response_id` when you want the lightest Responses API continuation primitive from one turn to the next.

!!! note

    The SDK automatically retries `conversation_locked` errors with backoff. In server-managed
    conversation runs, it rewinds the internal conversation-tracker input before retrying so the
    same prepared items can be resent cleanly.

    In local session-based runs (which cannot be combined with `conversation_id`,
    `previous_response_id`, or `auto_previous_response_id`), the SDK also performs a best-effort
    rollback of recently persisted input items to reduce duplicate history entries after a retry.

## Hooks and customization

### Call model input filter

Use `call_model_input_filter` to edit the model input right before the model call. The hook receives the current agent, context, and the combined input items (including session history when present) and returns a new `ModelInputData`.

The return value must be a [`ModelInputData`][agents.run.ModelInputData] object. Its `input` field is required and must be a list of input items. Returning any other shape raises a `UserError`.

```python
from agents import Agent, Runner, RunConfig
from agents.run import CallModelData, ModelInputData

def drop_old_messages(data: CallModelData[None]) -> ModelInputData:
    # Keep only the last 5 items and preserve existing instructions.
    trimmed = data.model_data.input[-5:]
    return ModelInputData(input=trimmed, instructions=data.model_data.instructions)

agent = Agent(name="Assistant", instructions="Answer concisely.")
result = Runner.run_sync(
    agent,
    "Explain quines",
    run_config=RunConfig(call_model_input_filter=drop_old_messages),
)
```

The runner passes a copy of the prepared input list to the hook, so you can trim, replace, or reorder it without mutating the caller's original list in place.

If you are using a session, `call_model_input_filter` runs after session history has already been loaded and merged with the current turn. Use [`session_input_callback`][agents.run.RunConfig.session_input_callback] when you want to customize that earlier merge step itself.

If you are using OpenAI server-managed conversation state with `conversation_id`, `previous_response_id`, or `auto_previous_response_id`, the hook runs on the prepared payload for the next Responses API call. That payload may already represent only the new-turn delta rather than a full replay of earlier history. Only the items you return are marked as sent for that server-managed continuation.

Set the hook per run via `run_config` to redact sensitive data, trim long histories, or inject additional system guidance.

## Errors and recovery

### Error handlers

All `Runner` entry points accept `error_handlers`, a dict keyed by error kind. Today, the supported key is `"max_turns"`. Use it when you want to return a controlled final output instead of raising `MaxTurnsExceeded`.

```python
from agents import (
    Agent,
    RunErrorHandlerInput,
    RunErrorHandlerResult,
    Runner,
)

agent = Agent(name="Assistant", instructions="Be concise.")


def on_max_turns(_data: RunErrorHandlerInput[None]) -> RunErrorHandlerResult:
    return RunErrorHandlerResult(
        final_output="I couldn't finish within the turn limit. Please narrow the request.",
        include_in_history=False,
    )


result = Runner.run_sync(
    agent,
    "Analyze this long transcript",
    max_turns=3,
    error_handlers={"max_turns": on_max_turns},
)
print(result.final_output)
```

Set `include_in_history=False` when you do not want the fallback output appended to conversation history.

## Durable execution integrations and human-in-the-loop

For tool approval pause/resume patterns, start with the dedicated [Human-in-the-loop guide](human_in_the_loop.md).
The integrations below are for durable orchestration when runs may span long waits, retries, or process restarts.

### Temporal

You can use the Agents SDK [Temporal](https://temporal.io/) integration to run durable, long-running workflows, including human-in-the-loop tasks. View a demo of Temporal and the Agents SDK working in action to complete long-running tasks [in this video](https://www.youtube.com/watch?v=fFBZqzT4DD8), and [view docs here](https://github.com/temporalio/sdk-python/tree/main/temporalio/contrib/openai_agents). 

### Restate

You can use the Agents SDK [Restate](https://restate.dev/) integration for lightweight, durable agents, including human approval, handoffs, and session management. The integration requires Restate's single-binary runtime as a dependency, and supports running agents as processes/containers or serverless functions.
Read the [overview](https://www.restate.dev/blog/durable-orchestration-for-ai-agents-with-restate-and-openai-sdk) or view the [docs](https://docs.restate.dev/ai) for more details.

### DBOS

You can use the Agents SDK [DBOS](https://dbos.dev/) integration to run reliable agents that preserves progress across failures and restarts. It supports long-running agents, human-in-the-loop workflows, and handoffs. It supports both sync and async methods. The integration requires only a SQLite or Postgres database. View the integration [repo](https://github.com/dbos-inc/dbos-openai-agents) and the [docs](https://docs.dbos.dev/integrations/openai-agents) for more details.

## Exceptions

The SDK raises exceptions in certain cases. The full list is in [`agents.exceptions`][]. As an overview:

-   [`AgentsException`][agents.exceptions.AgentsException]: This is the base class for all exceptions raised within the SDK. It serves as a generic type from which all other specific exceptions are derived.
-   [`MaxTurnsExceeded`][agents.exceptions.MaxTurnsExceeded]: This exception is raised when the agent's run exceeds the `max_turns` limit passed to the `Runner.run`, `Runner.run_sync`, or `Runner.run_streamed` methods. It indicates that the agent could not complete its task within the specified number of interaction turns.
-   [`ModelBehaviorError`][agents.exceptions.ModelBehaviorError]: This exception occurs when the underlying model (LLM) produces unexpected or invalid outputs. This can include:
    -   Malformed JSON: When the model provides a malformed JSON structure for tool calls or in its direct output, especially if a specific `output_type` is defined.
    -   Unexpected tool-related failures: When the model fails to use tools in an expected manner
-   [`ToolTimeoutError`][agents.exceptions.ToolTimeoutError]: This exception is raised when a function tool call exceeds its configured timeout and the tool uses `timeout_behavior="raise_exception"`.
-   [`UserError`][agents.exceptions.UserError]: This exception is raised when you (the person writing code using the SDK) make an error while using the SDK. This typically results from incorrect code implementation, invalid configuration, or misuse of the SDK's API.
-   [`InputGuardrailTripwireTriggered`][agents.exceptions.InputGuardrailTripwireTriggered], [`OutputGuardrailTripwireTriggered`][agents.exceptions.OutputGuardrailTripwireTriggered]: This exception is raised when the conditions of an input guardrail or output guardrail are met, respectively. Input guardrails check incoming messages before processing, while output guardrails check the agent's final response before delivery.

================
File: docs/streaming.md
================
# Streaming

Streaming lets you subscribe to updates of the agent run as it proceeds. This can be useful for showing the end-user progress updates and partial responses.

To stream, you can call [`Runner.run_streamed()`][agents.run.Runner.run_streamed], which will give you a [`RunResultStreaming`][agents.result.RunResultStreaming]. Calling `result.stream_events()` gives you an async stream of [`StreamEvent`][agents.stream_events.StreamEvent] objects, which are described below.

Keep consuming `result.stream_events()` until the async iterator finishes. A streaming run is not complete until the iterator ends, and post-processing such as session persistence, approval bookkeeping, or history compaction can finish after the last visible token arrives. When the loop exits, `result.is_complete` reflects the final run state.

## Raw response events

[`RawResponsesStreamEvent`][agents.stream_events.RawResponsesStreamEvent] are raw events passed directly from the LLM. They are in OpenAI Responses API format, which means each event has a type (like `response.created`, `response.output_text.delta`, etc) and data. These events are useful if you want to stream response messages to the user as soon as they are generated.

For example, this will output the text generated by the LLM token-by-token.

```python
import asyncio
from openai.types.responses import ResponseTextDeltaEvent
from agents import Agent, Runner

async def main():
    agent = Agent(
        name="Joker",
        instructions="You are a helpful assistant.",
    )

    result = Runner.run_streamed(agent, input="Please tell me 5 jokes.")
    async for event in result.stream_events():
        if event.type == "raw_response_event" and isinstance(event.data, ResponseTextDeltaEvent):
            print(event.data.delta, end="", flush=True)


if __name__ == "__main__":
    asyncio.run(main())
```

## Streaming and approvals

Streaming is compatible with runs that pause for tool approval. If a tool requires approval, `result.stream_events()` finishes and pending approvals are exposed in [`RunResultStreaming.interruptions`][agents.result.RunResultStreaming.interruptions]. Convert the result to a [`RunState`][agents.run_state.RunState] with `result.to_state()`, approve or reject the interruption, and then resume with `Runner.run_streamed(...)`.

```python
result = Runner.run_streamed(agent, "Delete temporary files if they are no longer needed.")
async for _event in result.stream_events():
    pass

if result.interruptions:
    state = result.to_state()
    for interruption in result.interruptions:
        state.approve(interruption)
    result = Runner.run_streamed(agent, state)
    async for _event in result.stream_events():
        pass
```

For a full pause/resume walkthrough, see the [human-in-the-loop guide](human_in_the_loop.md).

## Run item events and agent events

[`RunItemStreamEvent`][agents.stream_events.RunItemStreamEvent]s are higher level events. They inform you when an item has been fully generated. This allows you to push progress updates at the level of "message generated", "tool ran", etc, instead of each token. Similarly, [`AgentUpdatedStreamEvent`][agents.stream_events.AgentUpdatedStreamEvent] gives you updates when the current agent changes (e.g. as the result of a handoff).

### Run item event names

`RunItemStreamEvent.name` uses a fixed set of semantic event names:

-   `message_output_created`
-   `handoff_requested`
-   `handoff_occured`
-   `tool_called`
-   `tool_output`
-   `reasoning_item_created`
-   `mcp_approval_requested`
-   `mcp_approval_response`
-   `mcp_list_tools`

`handoff_occured` is intentionally misspelled for backward compatibility.

For example, this will ignore raw events and stream updates to the user.

```python
import asyncio
import random
from agents import Agent, ItemHelpers, Runner, function_tool

@function_tool
def how_many_jokes() -> int:
    return random.randint(1, 10)


async def main():
    agent = Agent(
        name="Joker",
        instructions="First call the `how_many_jokes` tool, then tell that many jokes.",
        tools=[how_many_jokes],
    )

    result = Runner.run_streamed(
        agent,
        input="Hello",
    )
    print("=== Run starting ===")

    async for event in result.stream_events():
        # We'll ignore the raw responses event deltas
        if event.type == "raw_response_event":
            continue
        # When the agent updates, print that
        elif event.type == "agent_updated_stream_event":
            print(f"Agent updated: {event.new_agent.name}")
            continue
        # When items are generated, print them
        elif event.type == "run_item_stream_event":
            if event.item.type == "tool_call_item":
                print("-- Tool was called")
            elif event.item.type == "tool_call_output_item":
                print(f"-- Tool output: {event.item.output}")
            elif event.item.type == "message_output_item":
                print(f"-- Message output:\n {ItemHelpers.text_message_output(event.item)}")
            else:
                pass  # Ignore other event types

    print("=== Run complete ===")


if __name__ == "__main__":
    asyncio.run(main())
```

================
File: docs/tools.md
================
# Tools

Tools let agents take actions: things like fetching data, running code, calling external APIs, and even using a computer. The SDK supports five categories:

-   Hosted OpenAI tools: run alongside the model on OpenAI servers.
-   Local/runtime execution tools: `ComputerTool` and `ApplyPatchTool` always run in your environment, while `ShellTool` can run locally or in a hosted container.
-   Function calling: wrap any Python function as a tool.
-   Agents as tools: expose an agent as a callable tool without a full handoff.
-   Experimental: Codex tool: run workspace-scoped Codex tasks from a tool call.

## Choosing a tool type

Use this page as a catalog, then jump to the section that matches the runtime you control.

| If you want to... | Start here |
| --- | --- |
| Use OpenAI-managed tools (web search, file search, code interpreter, hosted MCP, image generation) | [Hosted tools](#hosted-tools) |
| Run tools in your own process or environment | [Local runtime tools](#local-runtime-tools) |
| Wrap Python functions as tools | [Function tools](#function-tools) |
| Let one agent call another without a handoff | [Agents as tools](#agents-as-tools) |
| Run workspace-scoped Codex tasks from an agent | [Experimental: Codex tool](#experimental-codex-tool) |

## Hosted tools

OpenAI offers a few built-in tools when using the [`OpenAIResponsesModel`][agents.models.openai_responses.OpenAIResponsesModel]:

-   The [`WebSearchTool`][agents.tool.WebSearchTool] lets an agent search the web.
-   The [`FileSearchTool`][agents.tool.FileSearchTool] allows retrieving information from your OpenAI Vector Stores.
-   The [`CodeInterpreterTool`][agents.tool.CodeInterpreterTool] lets the LLM execute code in a sandboxed environment.
-   The [`HostedMCPTool`][agents.tool.HostedMCPTool] exposes a remote MCP server's tools to the model.
-   The [`ImageGenerationTool`][agents.tool.ImageGenerationTool] generates images from a prompt.

Advanced hosted search options:

-   `FileSearchTool` supports `filters`, `ranking_options`, and `include_search_results` in addition to `vector_store_ids` and `max_num_results`.
-   `WebSearchTool` supports `filters`, `user_location`, and `search_context_size`.

```python
from agents import Agent, FileSearchTool, Runner, WebSearchTool

agent = Agent(
    name="Assistant",
    tools=[
        WebSearchTool(),
        FileSearchTool(
            max_num_results=3,
            vector_store_ids=["VECTOR_STORE_ID"],
        ),
    ],
)

async def main():
    result = await Runner.run(agent, "Which coffee shop should I go to, taking into account my preferences and the weather today in SF?")
    print(result.final_output)
```

### Hosted container shell + skills

`ShellTool` also supports OpenAI-hosted container execution. Use this mode when you want the model to run shell commands in a managed container instead of your local runtime.

```python
from agents import Agent, Runner, ShellTool, ShellToolSkillReference

csv_skill: ShellToolSkillReference = {
    "type": "skill_reference",
    "skill_id": "skill_698bbe879adc81918725cbc69dcae7960bc5613dadaed377",
    "version": "1",
}

agent = Agent(
    name="Container shell agent",
    model="gpt-5.2",
    instructions="Use the mounted skill when helpful.",
    tools=[
        ShellTool(
            environment={
                "type": "container_auto",
                "network_policy": {"type": "disabled"},
                "skills": [csv_skill],
            }
        )
    ],
)

result = await Runner.run(
    agent,
    "Use the configured skill to analyze CSV files in /mnt/data and summarize totals by region.",
)
print(result.final_output)
```

To reuse an existing container in later runs, set `environment={"type": "container_reference", "container_id": "cntr_..."}`.

What to know:

-   Hosted shell is available through the Responses API shell tool.
-   `container_auto` provisions a container for the request; `container_reference` reuses an existing one.
-   `container_auto` can also include `file_ids` and `memory_limit`.
-   `environment.skills` accepts skill references and inline skill bundles.
-   With hosted environments, do not set `executor`, `needs_approval`, or `on_approval` on `ShellTool`.
-   `network_policy` supports `disabled` and `allowlist` modes.
-   In allowlist mode, `network_policy.domain_secrets` can inject domain-scoped secrets by name.
-   See `examples/tools/container_shell_skill_reference.py` and `examples/tools/container_shell_inline_skill.py` for complete examples.
-   OpenAI platform guides: [Shell](https://platform.openai.com/docs/guides/tools-shell) and [Skills](https://platform.openai.com/docs/guides/tools-skills).

## Local runtime tools

Local runtime tools execute outside the model response itself. The model still decides when to call them, but your application or configured execution environment performs the actual work.

`ComputerTool` and `ApplyPatchTool` always require local implementations that you provide. `ShellTool` spans both modes: use the hosted-container configuration above when you want managed execution, or the local runtime configuration below when you want commands to run in your own process.

Local runtime tools require you to supply implementations:

-   [`ComputerTool`][agents.tool.ComputerTool]: implement the [`Computer`][agents.computer.Computer] or [`AsyncComputer`][agents.computer.AsyncComputer] interface to enable GUI/browser automation.
-   [`ShellTool`][agents.tool.ShellTool]: the latest shell tool for both local execution and hosted container execution.
-   [`LocalShellTool`][agents.tool.LocalShellTool]: legacy local-shell integration.
-   [`ApplyPatchTool`][agents.tool.ApplyPatchTool]: implement [`ApplyPatchEditor`][agents.editor.ApplyPatchEditor] to apply diffs locally.
-   Local shell skills are available with `ShellTool(environment={"type": "local", "skills": [...]})`.

```python
from agents import Agent, ApplyPatchTool, ShellTool
from agents.computer import AsyncComputer
from agents.editor import ApplyPatchResult, ApplyPatchOperation, ApplyPatchEditor


class NoopComputer(AsyncComputer):
    environment = "browser"
    dimensions = (1024, 768)
    async def screenshot(self): return ""
    async def click(self, x, y, button): ...
    async def double_click(self, x, y): ...
    async def scroll(self, x, y, scroll_x, scroll_y): ...
    async def type(self, text): ...
    async def wait(self): ...
    async def move(self, x, y): ...
    async def keypress(self, keys): ...
    async def drag(self, path): ...


class NoopEditor(ApplyPatchEditor):
    async def create_file(self, op: ApplyPatchOperation): return ApplyPatchResult(status="completed")
    async def update_file(self, op: ApplyPatchOperation): return ApplyPatchResult(status="completed")
    async def delete_file(self, op: ApplyPatchOperation): return ApplyPatchResult(status="completed")


async def run_shell(request):
    return "shell output"


agent = Agent(
    name="Local tools agent",
    tools=[
        ShellTool(executor=run_shell),
        ApplyPatchTool(editor=NoopEditor()),
        # ComputerTool expects a Computer/AsyncComputer implementation; omitted here for brevity.
    ],
)
```

## Function tools

You can use any Python function as a tool. The Agents SDK will setup the tool automatically:

-   The name of the tool will be the name of the Python function (or you can provide a name)
-   Tool description will be taken from the docstring of the function (or you can provide a description)
-   The schema for the function inputs is automatically created from the function's arguments
-   Descriptions for each input are taken from the docstring of the function, unless disabled

We use Python's `inspect` module to extract the function signature, along with [`griffe`](https://mkdocstrings.github.io/griffe/) to parse docstrings and `pydantic` for schema creation.

```python
import json

from typing_extensions import TypedDict, Any

from agents import Agent, FunctionTool, RunContextWrapper, function_tool


class Location(TypedDict):
    lat: float
    long: float

@function_tool  # (1)!
async def fetch_weather(location: Location) -> str:
    # (2)!
    """Fetch the weather for a given location.

    Args:
        location: The location to fetch the weather for.
    """
    # In real life, we'd fetch the weather from a weather API
    return "sunny"


@function_tool(name_override="fetch_data")  # (3)!
def read_file(ctx: RunContextWrapper[Any], path: str, directory: str | None = None) -> str:
    """Read the contents of a file.

    Args:
        path: The path to the file to read.
        directory: The directory to read the file from.
    """
    # In real life, we'd read the file from the file system
    return "<file contents>"


agent = Agent(
    name="Assistant",
    tools=[fetch_weather, read_file],  # (4)!
)

for tool in agent.tools:
    if isinstance(tool, FunctionTool):
        print(tool.name)
        print(tool.description)
        print(json.dumps(tool.params_json_schema, indent=2))
        print()

```

1.  You can use any Python types as arguments to your functions, and the function can be sync or async.
2.  Docstrings, if present, are used to capture descriptions and argument descriptions
3.  Functions can optionally take the `context` (must be the first argument). You can also set overrides, like the name of the tool, description, which docstring style to use, etc.
4.  You can pass the decorated functions to the list of tools.

??? note "Expand to see output"

    ```
    fetch_weather
    Fetch the weather for a given location.
    {
    "$defs": {
      "Location": {
        "properties": {
          "lat": {
            "title": "Lat",
            "type": "number"
          },
          "long": {
            "title": "Long",
            "type": "number"
          }
        },
        "required": [
          "lat",
          "long"
        ],
        "title": "Location",
        "type": "object"
      }
    },
    "properties": {
      "location": {
        "$ref": "#/$defs/Location",
        "description": "The location to fetch the weather for."
      }
    },
    "required": [
      "location"
    ],
    "title": "fetch_weather_args",
    "type": "object"
    }

    fetch_data
    Read the contents of a file.
    {
    "properties": {
      "path": {
        "description": "The path to the file to read.",
        "title": "Path",
        "type": "string"
      },
      "directory": {
        "anyOf": [
          {
            "type": "string"
          },
          {
            "type": "null"
          }
        ],
        "default": null,
        "description": "The directory to read the file from.",
        "title": "Directory"
      }
    },
    "required": [
      "path"
    ],
    "title": "fetch_data_args",
    "type": "object"
    }
    ```

### Returning images or files from function tools

In addition to returning text outputs, you can return one or many images or files as the output of a function tool. To do so, you can return any of:

-   Images: [`ToolOutputImage`][agents.tool.ToolOutputImage] (or the TypedDict version, [`ToolOutputImageDict`][agents.tool.ToolOutputImageDict])
-   Files: [`ToolOutputFileContent`][agents.tool.ToolOutputFileContent] (or the TypedDict version, [`ToolOutputFileContentDict`][agents.tool.ToolOutputFileContentDict])
-   Text: either a string or stringable objects, or [`ToolOutputText`][agents.tool.ToolOutputText] (or the TypedDict version, [`ToolOutputTextDict`][agents.tool.ToolOutputTextDict])

### Custom function tools

Sometimes, you don't want to use a Python function as a tool. You can directly create a [`FunctionTool`][agents.tool.FunctionTool] if you prefer. You'll need to provide:

-   `name`
-   `description`
-   `params_json_schema`, which is the JSON schema for the arguments
-   `on_invoke_tool`, which is an async function that receives a [`ToolContext`][agents.tool_context.ToolContext] and the arguments as a JSON string, and returns tool output (for example, text, structured tool output objects, or a list of outputs).

```python
from typing import Any

from pydantic import BaseModel

from agents import RunContextWrapper, FunctionTool



def do_some_work(data: str) -> str:
    return "done"


class FunctionArgs(BaseModel):
    username: str
    age: int


async def run_function(ctx: RunContextWrapper[Any], args: str) -> str:
    parsed = FunctionArgs.model_validate_json(args)
    return do_some_work(data=f"{parsed.username} is {parsed.age} years old")


tool = FunctionTool(
    name="process_user",
    description="Processes extracted user data",
    params_json_schema=FunctionArgs.model_json_schema(),
    on_invoke_tool=run_function,
)
```

### Automatic argument and docstring parsing

As mentioned before, we automatically parse the function signature to extract the schema for the tool, and we parse the docstring to extract descriptions for the tool and for individual arguments. Some notes on that:

1. The signature parsing is done via the `inspect` module. We use type annotations to understand the types for the arguments, and dynamically build a Pydantic model to represent the overall schema. It supports most types, including Python primitives, Pydantic models, TypedDicts, and more.
2. We use `griffe` to parse docstrings. Supported docstring formats are `google`, `sphinx` and `numpy`. We attempt to automatically detect the docstring format, but this is best-effort and you can explicitly set it when calling `function_tool`. You can also disable docstring parsing by setting `use_docstring_info` to `False`.

The code for the schema extraction lives in [`agents.function_schema`][].

### Constraining and describing arguments with Pydantic Field

You can use Pydantic's [`Field`](https://docs.pydantic.dev/latest/concepts/fields/) to add constraints (e.g. min/max for numbers, length or pattern for strings) and descriptions to tool arguments. As in Pydantic, both forms are supported: default-based (`arg: int = Field(..., ge=1)`) and `Annotated` (`arg: Annotated[int, Field(..., ge=1)]`). The generated JSON schema and validation include these constraints.

```python
from typing import Annotated
from pydantic import Field
from agents import function_tool

# Default-based form
@function_tool
def score_a(score: int = Field(..., ge=0, le=100, description="Score from 0 to 100")) -> str:
    return f"Score recorded: {score}"

# Annotated form
@function_tool
def score_b(score: Annotated[int, Field(..., ge=0, le=100, description="Score from 0 to 100")]) -> str:
    return f"Score recorded: {score}"
```

### Function tool timeouts

You can set per-call timeouts for async function tools with `@function_tool(timeout=...)`.

```python
import asyncio
from agents import Agent, Runner, function_tool


@function_tool(timeout=2.0)
async def slow_lookup(query: str) -> str:
    await asyncio.sleep(10)
    return f"Result for {query}"


agent = Agent(
    name="Timeout demo",
    instructions="Use tools when helpful.",
    tools=[slow_lookup],
)
```

When a timeout is reached, the default behavior is `timeout_behavior="error_as_result"`, which sends a model-visible timeout message (for example, `Tool 'slow_lookup' timed out after 2 seconds.`).

You can control timeout handling:

-   `timeout_behavior="error_as_result"` (default): return a timeout message to the model so it can recover.
-   `timeout_behavior="raise_exception"`: raise [`ToolTimeoutError`][agents.exceptions.ToolTimeoutError] and fail the run.
-   `timeout_error_function=...`: customize the timeout message when using `error_as_result`.

```python
import asyncio
from agents import Agent, Runner, ToolTimeoutError, function_tool


@function_tool(timeout=1.5, timeout_behavior="raise_exception")
async def slow_tool() -> str:
    await asyncio.sleep(5)
    return "done"


agent = Agent(name="Timeout hard-fail", tools=[slow_tool])

try:
    await Runner.run(agent, "Run the tool")
except ToolTimeoutError as e:
    print(f"{e.tool_name} timed out in {e.timeout_seconds} seconds")
```

!!! note

    Timeout configuration is supported only for async `@function_tool` handlers.

### Handling errors in function tools

When you create a function tool via `@function_tool`, you can pass a `failure_error_function`. This is a function that provides an error response to the LLM in case the tool call crashes.

-   By default (i.e. if you don't pass anything), it runs a `default_tool_error_function` which tells the LLM an error occurred.
-   If you pass your own error function, it runs that instead, and sends the response to the LLM.
-   If you explicitly pass `None`, then any tool call errors will be re-raised for you to handle. This could be a `ModelBehaviorError` if the model produced invalid JSON, or a `UserError` if your code crashed, etc.

```python
from agents import function_tool, RunContextWrapper
from typing import Any

def my_custom_error_function(context: RunContextWrapper[Any], error: Exception) -> str:
    """A custom function to provide a user-friendly error message."""
    print(f"A tool call failed with the following error: {error}")
    return "An internal server error occurred. Please try again later."

@function_tool(failure_error_function=my_custom_error_function)
def get_user_profile(user_id: str) -> str:
    """Fetches a user profile from a mock API.
     This function demonstrates a 'flaky' or failing API call.
    """
    if user_id == "user_123":
        return "User profile for user_123 successfully retrieved."
    else:
        raise ValueError(f"Could not retrieve profile for user_id: {user_id}. API returned an error.")

```

If you are manually creating a `FunctionTool` object, then you must handle errors inside the `on_invoke_tool` function.

## Agents as tools

In some workflows, you may want a central agent to orchestrate a network of specialized agents, instead of handing off control. You can do this by modeling agents as tools.

```python
from agents import Agent, Runner
import asyncio

spanish_agent = Agent(
    name="Spanish agent",
    instructions="You translate the user's message to Spanish",
)

french_agent = Agent(
    name="French agent",
    instructions="You translate the user's message to French",
)

orchestrator_agent = Agent(
    name="orchestrator_agent",
    instructions=(
        "You are a translation agent. You use the tools given to you to translate."
        "If asked for multiple translations, you call the relevant tools."
    ),
    tools=[
        spanish_agent.as_tool(
            tool_name="translate_to_spanish",
            tool_description="Translate the user's message to Spanish",
        ),
        french_agent.as_tool(
            tool_name="translate_to_french",
            tool_description="Translate the user's message to French",
        ),
    ],
)

async def main():
    result = await Runner.run(orchestrator_agent, input="Say 'Hello, how are you?' in Spanish.")
    print(result.final_output)
```

### Customizing tool-agents

The `agent.as_tool` function is a convenience method to make it easy to turn an agent into a tool. It supports common runtime options such as `max_turns`, `run_config`, `hooks`, `previous_response_id`, `conversation_id`, `session`, and `needs_approval`. It also supports structured input with `parameters`, `input_builder`, and `include_input_schema`. For advanced orchestration (for example, conditional retries, fallback behavior, or chaining multiple agent calls), use `Runner.run` directly in your tool implementation:

```python
@function_tool
async def run_my_agent() -> str:
    """A tool that runs the agent with custom configs"""

    agent = Agent(name="My agent", instructions="...")

    result = await Runner.run(
        agent,
        input="...",
        max_turns=5,
        run_config=...
    )

    return str(result.final_output)
```

### Structured input for tool-agents

By default, `Agent.as_tool()` expects a single string input (`{"input": "..."}`), but you can expose a structured schema by passing `parameters` (a Pydantic model or dataclass type).

Additional options:

- `include_input_schema=True` includes the full JSON Schema in the generated nested input.
- `input_builder=...` lets you fully customize how structured tool arguments become nested agent input.
- `RunContextWrapper.tool_input` contains the parsed structured payload inside the nested run context.

```python
from pydantic import BaseModel, Field


class TranslationInput(BaseModel):
    text: str = Field(description="Text to translate.")
    source: str = Field(description="Source language.")
    target: str = Field(description="Target language.")


translator_tool = translator_agent.as_tool(
    tool_name="translate_text",
    tool_description="Translate text between languages.",
    parameters=TranslationInput,
    include_input_schema=True,
)
```

See `examples/agent_patterns/agents_as_tools_structured.py` for a complete runnable example.

### Approval gates for tool-agents

`Agent.as_tool(..., needs_approval=...)` uses the same approval flow as `function_tool`. If approval is required, the run pauses and pending items appear in `result.interruptions`; then use `result.to_state()` and resume after calling `state.approve(...)` or `state.reject(...)`. See the [Human-in-the-loop guide](human_in_the_loop.md) for the full pause/resume pattern.

### Custom output extraction

In certain cases, you might want to modify the output of the tool-agents before returning it to the central agent. This may be useful if you want to:

-   Extract a specific piece of information (e.g., a JSON payload) from the sub-agent's chat history.
-   Convert or reformat the agent’s final answer (e.g., transform Markdown into plain text or CSV).
-   Validate the output or provide a fallback value when the agent’s response is missing or malformed.

You can do this by supplying the `custom_output_extractor` argument to the `as_tool` method:

```python
async def extract_json_payload(run_result: RunResult) -> str:
    # Scan the agent’s outputs in reverse order until we find a JSON-like message from a tool call.
    for item in reversed(run_result.new_items):
        if isinstance(item, ToolCallOutputItem) and item.output.strip().startswith("{"):
            return item.output.strip()
    # Fallback to an empty JSON object if nothing was found
    return "{}"


json_tool = data_agent.as_tool(
    tool_name="get_data_json",
    tool_description="Run the data agent and return only its JSON payload",
    custom_output_extractor=extract_json_payload,
)
```

Inside a custom extractor, the nested [`RunResult`][agents.result.RunResult] also exposes
[`agent_tool_invocation`][agents.result.RunResultBase.agent_tool_invocation], which is useful when
you need the outer tool name, call ID, or raw arguments while post-processing the nested result.
See the [Results guide](results.md#agent-as-tool-metadata).

### Streaming nested agent runs

Pass an `on_stream` callback to `as_tool` to listen to streaming events emitted by the nested agent while still returning its final output once the stream completes.

```python
from agents import AgentToolStreamEvent


async def handle_stream(event: AgentToolStreamEvent) -> None:
    # Inspect the underlying StreamEvent along with agent metadata.
    print(f"[stream] {event['agent'].name} :: {event['event'].type}")


billing_agent_tool = billing_agent.as_tool(
    tool_name="billing_helper",
    tool_description="Answer billing questions.",
    on_stream=handle_stream,  # Can be sync or async.
)
```

What to expect:

- Event types mirror `StreamEvent["type"]`: `raw_response_event`, `run_item_stream_event`, `agent_updated_stream_event`.
- Providing `on_stream` automatically runs the nested agent in streaming mode and drains the stream before returning the final output.
- The handler may be synchronous or asynchronous; each event is delivered in order as it arrives.
- `tool_call` is present when the tool is invoked via a model tool call; direct calls may leave it `None`.
- See `examples/agent_patterns/agents_as_tools_streaming.py` for a complete runnable sample.

### Conditional tool enabling

You can conditionally enable or disable agent tools at runtime using the `is_enabled` parameter. This allows you to dynamically filter which tools are available to the LLM based on context, user preferences, or runtime conditions.

```python
import asyncio
from agents import Agent, AgentBase, Runner, RunContextWrapper
from pydantic import BaseModel

class LanguageContext(BaseModel):
    language_preference: str = "french_spanish"

def french_enabled(ctx: RunContextWrapper[LanguageContext], agent: AgentBase) -> bool:
    """Enable French for French+Spanish preference."""
    return ctx.context.language_preference == "french_spanish"

# Create specialized agents
spanish_agent = Agent(
    name="spanish_agent",
    instructions="You respond in Spanish. Always reply to the user's question in Spanish.",
)

french_agent = Agent(
    name="french_agent",
    instructions="You respond in French. Always reply to the user's question in French.",
)

# Create orchestrator with conditional tools
orchestrator = Agent(
    name="orchestrator",
    instructions=(
        "You are a multilingual assistant. You use the tools given to you to respond to users. "
        "You must call ALL available tools to provide responses in different languages. "
        "You never respond in languages yourself, you always use the provided tools."
    ),
    tools=[
        spanish_agent.as_tool(
            tool_name="respond_spanish",
            tool_description="Respond to the user's question in Spanish",
            is_enabled=True,  # Always enabled
        ),
        french_agent.as_tool(
            tool_name="respond_french",
            tool_description="Respond to the user's question in French",
            is_enabled=french_enabled,
        ),
    ],
)

async def main():
    context = RunContextWrapper(LanguageContext(language_preference="french_spanish"))
    result = await Runner.run(orchestrator, "How are you?", context=context.context)
    print(result.final_output)

asyncio.run(main())
```

The `is_enabled` parameter accepts:

-   **Boolean values**: `True` (always enabled) or `False` (always disabled)
-   **Callable functions**: Functions that take `(context, agent)` and return a boolean
-   **Async functions**: Async functions for complex conditional logic

Disabled tools are completely hidden from the LLM at runtime, making this useful for:

-   Feature gating based on user permissions
-   Environment-specific tool availability (dev vs prod)
-   A/B testing different tool configurations
-   Dynamic tool filtering based on runtime state

## Experimental: Codex tool

The `codex_tool` wraps the Codex CLI so an agent can run workspace-scoped tasks (shell, file edits, MCP tools) during a tool call. This surface is experimental and may change.

Use it when you want the main agent to delegate a bounded workspace task to Codex without leaving the current run. By default, the tool name is `codex`. If you set a custom name, it must be `codex` or start with `codex_`. When an agent includes multiple Codex tools, each must use a unique name.

```python
from agents import Agent
from agents.extensions.experimental.codex import ThreadOptions, TurnOptions, codex_tool

agent = Agent(
    name="Codex Agent",
    instructions="Use the codex tool to inspect the workspace and answer the question.",
    tools=[
        codex_tool(
            sandbox_mode="workspace-write",
            working_directory="/path/to/repo",
            default_thread_options=ThreadOptions(
                model="gpt-5.2-codex",
                model_reasoning_effort="low",
                network_access_enabled=True,
                web_search_mode="disabled",
                approval_policy="never",
            ),
            default_turn_options=TurnOptions(
                idle_timeout_seconds=60,
            ),
            persist_session=True,
        )
    ],
)
```

Start with these option groups:

-   Execution surface: `sandbox_mode` and `working_directory` define where Codex can operate. Pair them together, and set `skip_git_repo_check=True` when the working directory is not inside a Git repository.
-   Thread defaults: `default_thread_options=ThreadOptions(...)` configures the model, reasoning effort, approval policy, additional directories, network access, and web search mode. Prefer `web_search_mode` over the legacy `web_search_enabled`.
-   Turn defaults: `default_turn_options=TurnOptions(...)` configures per-turn behavior such as `idle_timeout_seconds` and the optional cancellation `signal`.
-   Tool I/O: tool calls must include at least one `inputs` item with `{ "type": "text", "text": ... }` or `{ "type": "local_image", "path": ... }`. `output_schema` lets you require structured Codex responses.

Thread reuse and persistence are separate controls:

-   `persist_session=True` reuses one Codex thread for repeated calls to the same tool instance.
-   `use_run_context_thread_id=True` stores and reuses the thread ID in run context across runs that share the same mutable context object.
-   Thread ID precedence is: per-call `thread_id`, then run-context thread ID (if enabled), then the configured `thread_id` option.
-   The default run-context key is `codex_thread_id` for `name="codex"` and `codex_thread_id_<suffix>` for `name="codex_<suffix>"`. Override it with `run_context_thread_id_key`.

Runtime configuration:

-   Auth: set `CODEX_API_KEY` (preferred) or `OPENAI_API_KEY`, or pass `codex_options={"api_key": "..."}`.
-   Runtime: `codex_options.base_url` overrides the CLI base URL.
-   Binary resolution: set `codex_options.codex_path_override` (or `CODEX_PATH`) to pin the CLI path. Otherwise the SDK resolves `codex` from `PATH`, then falls back to the bundled vendor binary.
-   Environment: `codex_options.env` fully controls the subprocess environment. When it is provided, the subprocess does not inherit `os.environ`.
-   Stream limits: `codex_options.codex_subprocess_stream_limit_bytes` (or `OPENAI_AGENTS_CODEX_SUBPROCESS_STREAM_LIMIT_BYTES`) controls stdout/stderr reader limits. Valid range is `65536` to `67108864`; default is `8388608`.
-   Streaming: `on_stream` receives thread/turn lifecycle events and item events (`reasoning`, `command_execution`, `mcp_tool_call`, `file_change`, `web_search`, `todo_list`, and `error` item updates).
-   Outputs: results include `response`, `usage`, and `thread_id`; usage is added to `RunContextWrapper.usage`.

Reference:

-   [Codex tool API reference](ref/extensions/experimental/codex/codex_tool.md)
-   [ThreadOptions reference](ref/extensions/experimental/codex/thread_options.md)
-   [TurnOptions reference](ref/extensions/experimental/codex/turn_options.md)
-   See `examples/tools/codex.py` and `examples/tools/codex_same_thread.py` for complete runnable samples.

================
File: docs/tracing.md
================
# Tracing

The Agents SDK includes built-in tracing, collecting a comprehensive record of events during an agent run: LLM generations, tool calls, handoffs, guardrails, and even custom events that occur. Using the [Traces dashboard](https://platform.openai.com/traces), you can debug, visualize, and monitor your workflows during development and in production.

!!!note

    Tracing is enabled by default. You can disable it in three common ways:

    1. You can globally disable tracing by setting the env var `OPENAI_AGENTS_DISABLE_TRACING=1`
    2. You can globally disable tracing in code with [`set_tracing_disabled(True)`][agents.set_tracing_disabled]
    3. You can disable tracing for a single run by setting [`agents.run.RunConfig.tracing_disabled`][] to `True`

***For organizations operating under a Zero Data Retention (ZDR) policy using OpenAI's APIs, tracing is unavailable.***

## Traces and spans

-   **Traces** represent a single end-to-end operation of a "workflow". They're composed of Spans. Traces have the following properties:
    -   `workflow_name`: This is the logical workflow or app. For example "Code generation" or "Customer service".
    -   `trace_id`: A unique ID for the trace. Automatically generated if you don't pass one. Must have the format `trace_<32_alphanumeric>`.
    -   `group_id`: Optional group ID, to link multiple traces from the same conversation. For example, you might use a chat thread ID.
    -   `disabled`: If True, the trace will not be recorded.
    -   `metadata`: Optional metadata for the trace.
-   **Spans** represent operations that have a start and end time. Spans have:
    -   `started_at` and `ended_at` timestamps.
    -   `trace_id`, to represent the trace they belong to
    -   `parent_id`, which points to the parent Span of this Span (if any)
    -   `span_data`, which is information about the Span. For example, `AgentSpanData` contains information about the Agent, `GenerationSpanData` contains information about the LLM generation, etc.

## Default tracing

By default, the SDK traces the following:

-   The entire `Runner.{run, run_sync, run_streamed}()` is wrapped in a `trace()`.
-   Each time an agent runs, it is wrapped in `agent_span()`
-   LLM generations are wrapped in `generation_span()`
-   Function tool calls are each wrapped in `function_span()`
-   Guardrails are wrapped in `guardrail_span()`
-   Handoffs are wrapped in `handoff_span()`
-   Audio inputs (speech-to-text) are wrapped in a `transcription_span()`
-   Audio outputs (text-to-speech) are wrapped in a `speech_span()`
-   Related audio spans may be parented under a `speech_group_span()`

By default, the trace is named "Agent workflow". You can set this name if you use `trace`, or you can configure the name and other properties with the [`RunConfig`][agents.run.RunConfig].

In addition, you can set up [custom trace processors](#custom-tracing-processors) to push traces to other destinations (as a replacement, or secondary destination).

## Higher level traces

Sometimes, you might want multiple calls to `run()` to be part of a single trace. You can do this by wrapping the entire code in a `trace()`.

```python
from agents import Agent, Runner, trace

async def main():
    agent = Agent(name="Joke generator", instructions="Tell funny jokes.")

    with trace("Joke workflow"): # (1)!
        first_result = await Runner.run(agent, "Tell me a joke")
        second_result = await Runner.run(agent, f"Rate this joke: {first_result.final_output}")
        print(f"Joke: {first_result.final_output}")
        print(f"Rating: {second_result.final_output}")
```

1. Because the two calls to `Runner.run` are wrapped in a `with trace()`, the individual runs will be part of the overall trace rather than creating two traces.

## Creating traces

You can use the [`trace()`][agents.tracing.trace] function to create a trace. Traces need to be started and finished. You have two options to do so:

1. **Recommended**: use the trace as a context manager, i.e. `with trace(...) as my_trace`. This will automatically start and end the trace at the right time.
2. You can also manually call [`trace.start()`][agents.tracing.Trace.start] and [`trace.finish()`][agents.tracing.Trace.finish].

The current trace is tracked via a Python [`contextvar`](https://docs.python.org/3/library/contextvars.html). This means that it works with concurrency automatically. If you manually start/end a trace, you'll need to pass `mark_as_current` and `reset_current` to `start()`/`finish()` to update the current trace.

## Creating spans

You can use the various [`*_span()`][agents.tracing.create] methods to create a span. In general, you don't need to manually create spans. A [`custom_span()`][agents.tracing.custom_span] function is available for tracking custom span information.

Spans are automatically part of the current trace, and are nested under the nearest current span, which is tracked via a Python [`contextvar`](https://docs.python.org/3/library/contextvars.html).

## Sensitive data

Certain spans may capture potentially sensitive data.

The `generation_span()` stores the inputs/outputs of the LLM generation, and `function_span()` stores the inputs/outputs of function calls. These may contain sensitive data, so you can disable capturing that data via [`RunConfig.trace_include_sensitive_data`][agents.run.RunConfig.trace_include_sensitive_data].

Similarly, Audio spans include base64-encoded PCM data for input and output audio by default. You can disable capturing this audio data by configuring [`VoicePipelineConfig.trace_include_sensitive_audio_data`][agents.voice.pipeline_config.VoicePipelineConfig.trace_include_sensitive_audio_data].

By default, `trace_include_sensitive_data` is `True`. You can set the default without code by exporting the `OPENAI_AGENTS_TRACE_INCLUDE_SENSITIVE_DATA` environment variable to `true/1` or `false/0` before running your app.

## Custom tracing processors

The high level architecture for tracing is:

-   At initialization, we create a global [`TraceProvider`][agents.tracing.setup.TraceProvider], which is responsible for creating traces.
-   We configure the `TraceProvider` with a [`BatchTraceProcessor`][agents.tracing.processors.BatchTraceProcessor] that sends traces/spans in batches to a [`BackendSpanExporter`][agents.tracing.processors.BackendSpanExporter], which exports the spans and traces to the OpenAI backend in batches.

To customize this default setup, to send traces to alternative or additional backends or modifying exporter behavior, you have two options:

1. [`add_trace_processor()`][agents.tracing.add_trace_processor] lets you add an **additional** trace processor that will receive traces and spans as they are ready. This lets you do your own processing in addition to sending traces to OpenAI's backend.
2. [`set_trace_processors()`][agents.tracing.set_trace_processors] lets you **replace** the default processors with your own trace processors. This means traces will not be sent to the OpenAI backend unless you include a `TracingProcessor` that does so.


## Tracing with non-OpenAI models

You can use an OpenAI API key with non-OpenAI Models to enable free tracing in the OpenAI Traces dashboard without needing to disable tracing.

```python
import os
from agents import set_tracing_export_api_key, Agent, Runner
from agents.extensions.models.litellm_model import LitellmModel

tracing_api_key = os.environ["OPENAI_API_KEY"]
set_tracing_export_api_key(tracing_api_key)

model = LitellmModel(
    model="your-model-name",
    api_key="your-api-key",
)

agent = Agent(
    name="Assistant",
    model=model,
)
```

If you only need a different tracing key for a single run, pass it via `RunConfig` instead of changing the global exporter.

```python
from agents import Runner, RunConfig

await Runner.run(
    agent,
    input="Hello",
    run_config=RunConfig(tracing={"api_key": "sk-tracing-123"}),
)
```

## Additional notes
- View free traces at Openai Traces dashboard.


## Ecosystem integrations

The following community and vendor integrations support the OpenAI Agents SDK tracing surface.

### External tracing processors list

-   [Weights & Biases](https://weave-docs.wandb.ai/guides/integrations/openai_agents)
-   [Arize-Phoenix](https://docs.arize.com/phoenix/tracing/integrations-tracing/openai-agents-sdk)
-   [Future AGI](https://docs.futureagi.com/future-agi/products/observability/auto-instrumentation/openai_agents)
-   [MLflow (self-hosted/OSS)](https://mlflow.org/docs/latest/tracing/integrations/openai-agent)
-   [MLflow (Databricks hosted)](https://docs.databricks.com/aws/en/mlflow/mlflow-tracing#-automatic-tracing)
-   [Braintrust](https://braintrust.dev/docs/guides/traces/integrations#openai-agents-sdk)
-   [Pydantic Logfire](https://logfire.pydantic.dev/docs/integrations/llms/openai/#openai-agents)
-   [AgentOps](https://docs.agentops.ai/v1/integrations/agentssdk)
-   [Scorecard](https://docs.scorecard.io/docs/documentation/features/tracing#openai-agents-sdk-integration)
-   [Keywords AI](https://docs.keywordsai.co/integration/development-frameworks/openai-agent)
-   [LangSmith](https://docs.smith.langchain.com/observability/how_to_guides/trace_with_openai_agents_sdk)
-   [Maxim AI](https://www.getmaxim.ai/docs/observe/integrations/openai-agents-sdk)
-   [Comet Opik](https://www.comet.com/docs/opik/tracing/integrations/openai_agents)
-   [Langfuse](https://langfuse.com/docs/integrations/openaiagentssdk/openai-agents)
-   [Langtrace](https://docs.langtrace.ai/supported-integrations/llm-frameworks/openai-agents-sdk)
-   [Okahu-Monocle](https://github.com/monocle2ai/monocle)
-   [Galileo](https://v2docs.galileo.ai/integrations/openai-agent-integration#openai-agent-integration)
-   [Portkey AI](https://portkey.ai/docs/integrations/agents/openai-agents)
-   [LangDB AI](https://docs.langdb.ai/getting-started/working-with-agent-frameworks/working-with-openai-agents-sdk)
-   [Agenta](https://docs.agenta.ai/observability/integrations/openai-agents)
-   [PostHog](https://posthog.com/docs/llm-analytics/installation/openai-agents)
-   [Traccia](https://traccia.ai/docs/integrations/openai-agents)

================
File: docs/usage.md
================
# Usage

The Agents SDK automatically tracks token usage for every run. You can access it from the run context and use it to monitor costs, enforce limits, or record analytics.

## What is tracked

- **requests**: number of LLM API calls made
- **input_tokens**: total input tokens sent
- **output_tokens**: total output tokens received
- **total_tokens**: input + output
- **request_usage_entries**: list of per-request usage breakdowns
- **details**:
  - `input_tokens_details.cached_tokens`
  - `output_tokens_details.reasoning_tokens`

## Accessing usage from a run

After `Runner.run(...)`, access usage via `result.context_wrapper.usage`.

```python
result = await Runner.run(agent, "What's the weather in Tokyo?")
usage = result.context_wrapper.usage

print("Requests:", usage.requests)
print("Input tokens:", usage.input_tokens)
print("Output tokens:", usage.output_tokens)
print("Total tokens:", usage.total_tokens)
```

Usage is aggregated across all model calls during the run (including tool calls and handoffs).

### Enabling usage with LiteLLM models

LiteLLM providers do not report usage metrics by default. When you are using [`LitellmModel`](models/litellm.md), pass `ModelSettings(include_usage=True)` to your agent so that LiteLLM responses populate `result.context_wrapper.usage`.

```python
from agents import Agent, ModelSettings, Runner
from agents.extensions.models.litellm_model import LitellmModel

agent = Agent(
    name="Assistant",
    model=LitellmModel(model="your/model", api_key="..."),
    model_settings=ModelSettings(include_usage=True),
)

result = await Runner.run(agent, "What's the weather in Tokyo?")
print(result.context_wrapper.usage.total_tokens)
```

## Per-request usage tracking

The SDK automatically tracks usage for each API request in `request_usage_entries`, useful for detailed cost calculation and monitoring context window consumption.

```python
result = await Runner.run(agent, "What's the weather in Tokyo?")

for i, request in enumerate(result.context_wrapper.usage.request_usage_entries):
    print(f"Request {i + 1}: {request.input_tokens} in, {request.output_tokens} out")
```

## Accessing usage with sessions

When you use a `Session` (e.g., `SQLiteSession`), each call to `Runner.run(...)` returns usage for that specific run. Sessions maintain conversation history for context, but each run's usage is independent.

```python
session = SQLiteSession("my_conversation")

first = await Runner.run(agent, "Hi!", session=session)
print(first.context_wrapper.usage.total_tokens)  # Usage for first run

second = await Runner.run(agent, "Can you elaborate?", session=session)
print(second.context_wrapper.usage.total_tokens)  # Usage for second run
```

Note that while sessions preserve conversation context between runs, the usage metrics returned by each `Runner.run()` call represent only that particular execution. In sessions, previous messages may be re-fed as input to each run, which affects the input token count in consequent turns.

## Using usage in hooks

If you're using `RunHooks`, the `context` object passed to each hook contains `usage`. This lets you log usage at key lifecycle moments.

```python
class MyHooks(RunHooks):
    async def on_agent_end(self, context: RunContextWrapper, agent: Agent, output: Any) -> None:
        u = context.usage
        print(f"{agent.name} → {u.requests} requests, {u.total_tokens} total tokens")
```

## API reference

For detailed API documentation, see:

-   [`Usage`][agents.usage.Usage] - Usage tracking data structure
-   [`RequestUsage`][agents.usage.RequestUsage] - Per-request usage details
-   [`RunContextWrapper`][agents.run.RunContextWrapper] - Access usage from run context
-   [`RunHooks`][agents.run.RunHooks] - Hook into usage tracking lifecycle

================
File: docs/visualization.md
================
# Agent visualization

Agent visualization allows you to generate a structured graphical representation of agents and their relationships using **Graphviz**. This is useful for understanding how agents, tools, and handoffs interact within an application.

## Installation

Install the optional `viz` dependency group:

```bash
pip install "openai-agents[viz]"
```

## Generating a graph

You can generate an agent visualization using the `draw_graph` function. This function creates a directed graph where:

- **Agents** are represented as yellow boxes.
- **MCP servers** are represented as grey boxes.
- **Tools** are represented as green ellipses.
- **Handoffs** are directed edges from one agent to another.

### Example usage

```python
import os

from agents import Agent, function_tool
from agents.mcp.server import MCPServerStdio
from agents.extensions.visualization import draw_graph

@function_tool
def get_weather(city: str) -> str:
    return f"The weather in {city} is sunny."

spanish_agent = Agent(
    name="Spanish agent",
    instructions="You only speak Spanish.",
)

english_agent = Agent(
    name="English agent",
    instructions="You only speak English",
)

current_dir = os.path.dirname(os.path.abspath(__file__))
samples_dir = os.path.join(current_dir, "sample_files")
mcp_server = MCPServerStdio(
    name="Filesystem Server, via npx",
    params={
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-filesystem", samples_dir],
    },
)

triage_agent = Agent(
    name="Triage agent",
    instructions="Handoff to the appropriate agent based on the language of the request.",
    handoffs=[spanish_agent, english_agent],
    tools=[get_weather],
    mcp_servers=[mcp_server],
)

draw_graph(triage_agent)
```

![Agent Graph](./assets/images/graph.png)

This generates a graph that visually represents the structure of the **triage agent** and its connections to sub-agents and tools.


## Understanding the visualization

The generated graph includes:

- A **start node** (`__start__`) indicating the entry point.
- Agents represented as **rectangles** with yellow fill.
- Tools represented as **ellipses** with green fill.
- MCP servers represented as **rectangles** with grey fill.
- Directed edges indicating interactions:
  - **Solid arrows** for agent-to-agent handoffs.
  - **Dotted arrows** for tool invocations.
  - **Dashed arrows** for MCP server invocations.
- An **end node** (`__end__`) indicating where execution terminates.

**Note:** MCP servers are rendered in recent versions of the
`agents` package (verified in **v0.2.8**). If you don’t see MCP boxes
in your visualization, upgrade to the latest release.

## Customizing the graph

### Showing the graph
By default, `draw_graph` displays the graph inline. To show the graph in a separate window, write the following:

```python
draw_graph(triage_agent).view()
```

### Saving the graph
By default, `draw_graph` displays the graph inline. To save it as a file, specify a filename:

```python
draw_graph(triage_agent, filename="agent_graph")
```

This will generate `agent_graph.png` in the working directory.




================================================================
End of Codebase
================================================================
