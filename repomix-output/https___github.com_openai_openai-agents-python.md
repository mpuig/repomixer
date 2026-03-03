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

-   **권장**: [`OpenAIResponsesModel`][agents.models.openai_responses.OpenAIResponsesModel] — 새로운 [Responses API](https://platform.openai.com/docs/api-reference/responses)를 사용해 OpenAI API 를 호출합니다
-   [`OpenAIChatCompletionsModel`][agents.models.openai_chatcompletions.OpenAIChatCompletionsModel] — [Chat Completions API](https://platform.openai.com/docs/api-reference/chat)를 사용해 OpenAI API 를 호출합니다

## 모델 설정 선택

설정에 따라 다음 순서로 이 페이지를 활용하세요:

| 목표 | 시작 위치 |
| --- | --- |
| SDK 기본값으로 OpenAI 호스팅 모델 사용 | [OpenAI 모델](#openai-models) |
| websocket 전송으로 OpenAI Responses API 사용 | [Responses WebSocket 전송](#responses-websocket-transport) |
| OpenAI 이외 제공자 사용 | [비 OpenAI 모델](#non-openai-models) |
| 하나의 워크플로에서 모델/제공자 혼합 | [고급 모델 선택 및 혼합](#advanced-model-selection-and-mixing) 및 [제공자 간 모델 혼합](#mixing-models-across-providers) |
| 제공자 호환성 문제 디버깅 | [비 OpenAI 제공자 문제 해결](#troubleshooting-non-openai-providers) |

## OpenAI 모델

`Agent` 를 초기화할 때 모델을 지정하지 않으면 기본 모델이 사용됩니다. 현재 기본값은 호환성과 낮은 지연 시간을 위해 [`gpt-4.1`](https://platform.openai.com/docs/models/gpt-4.1)입니다. 접근 권한이 있다면, 명시적인 `model_settings` 를 유지하면서 더 높은 품질을 위해 에이전트를 [`gpt-5.2`](https://platform.openai.com/docs/models/gpt-5.2)로 설정하는 것을 권장합니다.

[`gpt-5.2`](https://platform.openai.com/docs/models/gpt-5.2) 같은 다른 모델로 전환하려면 에이전트를 구성하는 두 가지 방법이 있습니다.

### 기본 모델

첫째, 사용자 지정 모델을 설정하지 않은 모든 에이전트에서 특정 모델을 일관되게 사용하려면, 에이전트를 실행하기 전에 `OPENAI_DEFAULT_MODEL` 환경 변수를 설정하세요.

```bash
export OPENAI_DEFAULT_MODEL=gpt-5.2
python3 my_awesome_agent.py
```

둘째, `RunConfig` 를 통해 실행(run) 단위 기본 모델을 설정할 수 있습니다. 에이전트에 모델을 설정하지 않으면 이 실행의 모델이 사용됩니다.

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

이 방식으로 [`gpt-5.2`](https://platform.openai.com/docs/models/gpt-5.2) 같은 GPT-5.x 모델을 사용하면 SDK 가 기본 `ModelSettings` 를 적용합니다. 대부분의 사용 사례에서 가장 잘 작동하는 값으로 설정됩니다. 기본 모델의 reasoning effort 를 조정하려면 사용자 지정 `ModelSettings` 를 전달하세요:

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

더 낮은 지연 시간을 위해 `gpt-5.2` 에서 `reasoning.effort="none"` 사용을 권장합니다. gpt-4.1 계열( mini 및 nano 변형 포함)도 인터랙티브 에이전트 앱 구축에 여전히 좋은 선택입니다.

#### 비 GPT-5 모델

사용자 지정 `model_settings` 없이 비 GPT-5 모델 이름을 전달하면 SDK 는 모든 모델과 호환되는 일반 `ModelSettings` 로 되돌아갑니다.

### Responses WebSocket 전송

기본적으로 OpenAI Responses API 요청은 HTTP 전송을 사용합니다. OpenAI 기반 모델을 사용할 때 websocket 전송을 활성화할 수 있습니다.

```python
from agents import set_default_openai_responses_transport

set_default_openai_responses_transport("websocket")
```

이는 기본 OpenAI 제공자에서 확인되는 OpenAI Responses 모델(예: `"gpt-5.2"` 같은 문자열 모델 이름 포함)에 영향을 줍니다.

전송 방식 선택은 SDK 가 모델 이름을 모델 인스턴스로 해석할 때 이루어집니다. 구체적인 [`Model`][agents.models.interface.Model] 객체를 전달하면 해당 전송은 이미 고정됩니다: [`OpenAIResponsesWSModel`][agents.models.openai_responses.OpenAIResponsesWSModel]은 websocket, [`OpenAIResponsesModel`][agents.models.openai_responses.OpenAIResponsesModel]은 HTTP, [`OpenAIChatCompletionsModel`][agents.models.openai_chatcompletions.OpenAIChatCompletionsModel]은 Chat Completions 를 사용합니다. `RunConfig(model_provider=...)` 를 전달하면 전역 기본값 대신 해당 제공자가 전송 선택을 제어합니다.

제공자별 또는 실행별로 websocket 전송을 구성할 수도 있습니다:

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

접두사 기반 모델 라우팅이 필요하다면(예: 하나의 실행에서 `openai/...` 와 `litellm/...` 모델 이름을 혼합), [`MultiProvider`][agents.MultiProvider]를 사용하고 대신 `openai_use_responses_websocket=True` 를 설정하세요.

사용자 지정 OpenAI 호환 엔드포인트 또는 프록시를 사용하는 경우 websocket 전송에도 호환되는 websocket `/responses` 엔드포인트가 필요합니다. 이러한 설정에서는 `websocket_base_url` 을 명시적으로 설정해야 할 수 있습니다.

참고:

-   이것은 websocket 전송을 사용하는 Responses API 이며, [Realtime API](../realtime/guide.md)가 아닙니다. Chat Completions 또는 Responses websocket `/responses` 엔드포인트를 지원하지 않는 비 OpenAI 제공자에는 적용되지 않습니다
-   환경에 아직 없다면 `websockets` 패키지를 설치하세요
-   websocket 전송을 활성화한 뒤 [`Runner.run_streamed()`][agents.run.Runner.run_streamed]를 바로 사용할 수 있습니다. 동일한 websocket 연결을 여러 턴(중첩된 agent-as-tool 호출 포함)에서 재사용하고 싶다면 [`responses_websocket_session()`][agents.responses_websocket_session] 헬퍼를 권장합니다. [에이전트 실행](../running_agents.md) 가이드와 [`examples/basic/stream_ws.py`](https://github.com/openai/openai-agents-python/tree/main/examples/basic/stream_ws.py)를 참고하세요

## 비 OpenAI 모델

대부분의 다른 비 OpenAI 모델은 [LiteLLM 통합](./litellm.md)을 통해 사용할 수 있습니다. 먼저 litellm 의존성 그룹을 설치하세요:

```bash
pip install "openai-agents[litellm]"
```

그다음 `litellm/` 접두사를 사용해 [지원 모델](https://docs.litellm.ai/docs/providers) 중 아무 모델이나 사용할 수 있습니다:

```python
claude_agent = Agent(model="litellm/anthropic/claude-3-5-sonnet-20240620", ...)
gemini_agent = Agent(model="litellm/gemini/gemini-2.5-flash-preview-04-17", ...)
```

### 비 OpenAI 모델을 사용하는 다른 방법

다음 3가지 추가 방식으로 다른 LLM 제공자를 통합할 수 있습니다(코드 예제는 [여기](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/)):

1. [`set_default_openai_client`][agents.set_default_openai_client]는 `AsyncOpenAI` 인스턴스를 LLM 클라이언트로 전역 사용하려는 경우에 유용합니다. LLM 제공자가 OpenAI 호환 API 엔드포인트를 제공하고 `base_url` 및 `api_key` 를 설정할 수 있는 경우를 위한 방식입니다. 구성 가능한 예시는 [examples/model_providers/custom_example_global.py](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/custom_example_global.py)를 참고하세요
2. [`ModelProvider`][agents.models.interface.ModelProvider]는 `Runner.run` 수준에서 사용합니다. 이를 통해 "이 실행의 모든 에이전트에 사용자 지정 모델 제공자를 사용"하도록 지정할 수 있습니다. 구성 가능한 예시는 [examples/model_providers/custom_example_provider.py](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/custom_example_provider.py)를 참고하세요
3. [`Agent.model`][agents.agent.Agent.model]을 사용하면 특정 Agent 인스턴스에 모델을 지정할 수 있습니다. 이를 통해 에이전트별로 서로 다른 제공자를 조합할 수 있습니다. 구성 가능한 예시는 [examples/model_providers/custom_example_agent.py](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/custom_example_agent.py)를 참고하세요. 사용 가능한 대부분의 모델을 쉽게 사용하는 방법은 [LiteLLM 통합](./litellm.md)입니다

`platform.openai.com` 의 API 키가 없는 경우에는 `set_tracing_disabled()` 로 트레이싱을 비활성화하거나, [다른 트레이싱 프로세서](../tracing.md)를 설정하는 것을 권장합니다.

!!! note

    이 예시들에서는 대부분의 LLM 제공자가 아직 Responses API 를 지원하지 않기 때문에 Chat Completions API/model 을 사용합니다. LLM 제공자가 이를 지원한다면 Responses 사용을 권장합니다

## 고급 모델 선택 및 혼합

하나의 워크플로 안에서 에이전트별로 서로 다른 모델을 사용하고 싶을 수 있습니다. 예를 들어 분류에는 더 작고 빠른 모델을, 복잡한 작업에는 더 크고 성능이 높은 모델을 사용할 수 있습니다. [`Agent`][agents.Agent]를 구성할 때 다음 중 하나로 특정 모델을 선택할 수 있습니다:

1. 모델 이름 전달
2. 임의의 모델 이름 + 해당 이름을 Model 인스턴스로 매핑할 수 있는 [`ModelProvider`][agents.models.interface.ModelProvider] 전달
3. [`Model`][agents.models.interface.Model] 구현을 직접 제공

!!!note

    SDK 는 [`OpenAIResponsesModel`][agents.models.openai_responses.OpenAIResponsesModel] 과 [`OpenAIChatCompletionsModel`][agents.models.openai_chatcompletions.OpenAIChatCompletionsModel] 형태를 모두 지원하지만, 두 형태는 지원 기능과 도구 집합이 다르므로 워크플로별로 하나의 모델 형태만 사용하는 것을 권장합니다. 워크플로에서 모델 형태 혼합이 필요하다면, 사용하는 모든 기능이 두 형태 모두에서 사용 가능한지 확인하세요

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

에이전트에 사용할 모델을 더 세부적으로 구성하려면 temperature 같은 선택적 모델 구성 매개변수를 제공하는 [`ModelSettings`][agents.models.interface.ModelSettings]를 전달할 수 있습니다.

```python
from agents import Agent, ModelSettings

english_agent = Agent(
    name="English agent",
    instructions="You only speak English",
    model="gpt-4.1",
    model_settings=ModelSettings(temperature=0.1),
)
```

또한 OpenAI Responses API 를 사용할 때 [추가 선택 매개변수](https://platform.openai.com/docs/api-reference/responses/create)가 몇 가지 더 있습니다(예: `user`, `service_tier` 등). 이것들이 최상위 레벨에 없다면 `extra_args` 로 전달할 수 있습니다.

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

## 비 OpenAI 제공자 문제 해결

### 트레이싱 클라이언트 오류 401

트레이싱 관련 오류가 발생한다면, 이는 트레이스가 OpenAI 서버로 업로드되는데 OpenAI API 키가 없기 때문입니다. 해결 방법은 세 가지입니다:

1. 트레이싱을 완전히 비활성화: [`set_tracing_disabled(True)`][agents.set_tracing_disabled]
2. 트레이싱용 OpenAI 키 설정: [`set_tracing_export_api_key(...)`][agents.set_tracing_export_api_key]. 이 API 키는 트레이스 업로드에만 사용되며 [platform.openai.com](https://platform.openai.com/)에서 발급된 키여야 합니다
3. 비 OpenAI 트레이스 프로세서 사용. [트레이싱 문서](../tracing.md#custom-tracing-processors)를 참고하세요

### Responses API 지원

SDK 는 기본적으로 Responses API 를 사용하지만, 대부분의 다른 LLM 제공자는 아직 이를 지원하지 않습니다. 그 결과 404 또는 유사한 문제가 발생할 수 있습니다. 해결 방법은 두 가지입니다:

1. [`set_default_openai_api("chat_completions")`][agents.set_default_openai_api] 호출. 환경 변수로 `OPENAI_API_KEY` 및 `OPENAI_BASE_URL` 을 설정하는 경우에 동작합니다
2. [`OpenAIChatCompletionsModel`][agents.models.openai_chatcompletions.OpenAIChatCompletionsModel] 사용. 예시는 [여기](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/)에 있습니다

### structured outputs 지원

일부 모델 제공자는 [structured outputs](https://platform.openai.com/docs/guides/structured-outputs)를 지원하지 않습니다. 이 경우 때때로 다음과 같은 오류가 발생합니다:

```

BadRequestError: Error code: 400 - {'error': {'message': "'response_format.type' : value is not one of the allowed values ['text','json_object']", 'type': 'invalid_request_error'}}

```

이는 일부 모델 제공자의 한계입니다. JSON 출력은 지원하지만 출력에 사용할 `json_schema` 지정은 허용하지 않습니다. 현재 이 문제를 해결 중이지만, JSON schema 출력을 지원하는 제공자를 사용하는 것을 권장합니다. 그렇지 않으면 잘못된 JSON 때문에 앱이 자주 중단될 수 있습니다.

## 제공자 간 모델 혼합

모델 제공자 간 기능 차이를 인지하지 않으면 오류가 발생할 수 있습니다. 예를 들어 OpenAI 는 structured outputs, 멀티모달 입력, 호스팅 파일 검색 및 웹 검색을 지원하지만 많은 다른 제공자는 이러한 기능을 지원하지 않습니다. 다음 제한 사항에 유의하세요:

-   지원하지 않는 제공자에 지원되지 않는 `tools` 를 보내지 마세요
-   텍스트 전용 모델을 호출하기 전에 멀티모달 입력을 필터링하세요
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

이 가이드는 OpenAI Agents SDK의 실시간 기능을 사용해 음성 지원 AI 에이전트를 구축하는 방법을 심층적으로 다룹니다.

!!! warning "베타 기능"
실시간 에이전트는 베타입니다. 구현을 개선하는 과정에서 일부 호환성이 깨지는 변경이 발생할 수 있습니다.

## 개요

실시간 에이전트는 오디오와 텍스트 입력을 실시간으로 처리하고 실시간 오디오로 응답하는 대화 흐름을 지원합니다. OpenAI의 Realtime API와 지속적인 연결을 유지하여 지연이 낮은 자연스러운 음성 대화를 가능하게 하고, 인터럽션(중단 처리)도 우아하게 처리할 수 있습니다.

## 아키텍처

### 핵심 구성 요소

실시간 시스템은 다음과 같은 주요 구성 요소로 이루어집니다:

-   **RealtimeAgent**: instructions, tools, handoffs로 구성된 에이전트
-   **RealtimeRunner**: 구성을 관리합니다. `runner.run()`을 호출해 세션을 얻을 수 있습니다
-   **RealtimeSession**: 단일 상호작용 세션입니다. 일반적으로 사용자가 대화를 시작할 때마다 하나를 만들고, 대화가 끝날 때까지 유지합니다
-   **RealtimeModel**: 기본 모델 인터페이스(일반적으로 OpenAI의 WebSocket 구현)

### 세션 흐름

일반적인 실시간 세션은 다음 흐름을 따릅니다:

1. instructions, tools, handoffs로 **RealtimeAgent(들)를 생성**합니다
2. 에이전트와 구성 옵션으로 **RealtimeRunner를 설정**합니다
3. `await runner.run()`을 사용해 **세션을 시작**하면 RealtimeSession이 반환됩니다
4. `send_audio()` 또는 `send_message()`를 사용해 세션에 **오디오 또는 텍스트 메시지를 전송**합니다
5. 세션을 순회(iterating)하여 **이벤트를 수신**합니다. 이벤트에는 오디오 출력, 트랜스크립트, 도구 호출, 핸드오프, 오류가 포함됩니다
6. 사용자가 에이전트 위로 말할 때 **인터럽션(중단 처리)을 처리**하며, 이때 현재 오디오 생성이 자동으로 중지됩니다

세션은 대화 기록을 유지하고 실시간 모델과의 지속적인 연결을 관리합니다.

## 에이전트 구성

RealtimeAgent는 일반 Agent 클래스와 유사하게 동작하지만 몇 가지 핵심 차이가 있습니다. 전체 API 세부 사항은 [`RealtimeAgent`][agents.realtime.agent.RealtimeAgent] API 레퍼런스를 참고하세요.

일반 에이전트와의 주요 차이점:

-   모델 선택은 에이전트 레벨이 아니라 세션 레벨에서 구성합니다
-   structured outputs를 지원하지 않습니다(`outputType` 미지원)
-   음성은 에이전트별로 구성할 수 있지만, 첫 번째 에이전트가 말한 뒤에는 변경할 수 없습니다
-   tools, handoffs, instructions 같은 다른 기능은 동일하게 동작합니다

## 세션 구성

### 모델 설정

세션 구성으로 기본 실시간 모델 동작을 제어할 수 있습니다. 모델 이름(예: `gpt-realtime`), 음성 선택(alloy, echo, fable, onyx, nova, shimmer), 지원 모달리티(text 및/또는 audio)를 구성할 수 있습니다. 오디오 형식은 입력과 출력 모두에 설정할 수 있으며 기본값은 PCM16입니다.

### 오디오 구성

오디오 설정은 세션이 음성 입력과 출력을 처리하는 방식을 제어합니다. Whisper 같은 모델을 사용해 입력 오디오 트랜스크립션을 구성하고, 언어 선호를 설정하며, 도메인 특화 용어의 정확도를 높이기 위한 트랜스크립션 프롬프트를 제공할 수 있습니다. 턴 감지 설정은 에이전트가 언제 응답을 시작하고 중지해야 하는지를 제어하며, 음성 활동 감지 임계값, 무음 지속 시간, 감지된 음성 주변의 패딩 같은 옵션이 있습니다.

`RealtimeRunner(config=...)`에서 설정할 수 있는 추가 구성 옵션은 다음과 같습니다:

-   `model_settings.output_modalities`로 출력을 text 및/또는 audio로 제한
-   `model_settings.input_audio_noise_reduction`로 근거리/원거리 오디오에 대한 노이즈 감소를 조정
-   `guardrails_settings.debounce_text_length`로 출력 가드레일 실행 빈도를 제어
-   `async_tool_calls`로 함수 도구를 동시 실행
-   `tool_error_formatter`로 모델에 표시되는 도구 오류 메시지를 커스터마이즈

전체 타입 구성은 [`RealtimeRunConfig`][agents.realtime.config.RealtimeRunConfig] 및 [`RealtimeSessionModelSettings`][agents.realtime.config.RealtimeSessionModelSettings]를 참고하세요.

## 도구와 함수

### 도구 추가

일반 에이전트와 마찬가지로, 실시간 에이전트는 대화 중 실행되는 함수 도구를 지원합니다:

```python
from agents import function_tool

@function_tool
def get_weather(city: str) -> str:
    """Get current weather for a city."""
    # Your weather API logic here
    return f"The weather in {city} is sunny, 72°F"

@function_tool
def book_appointment(date: str, time: str, service: str) -> str:
    """Book an appointment."""
    # Your booking logic here
    return f"Appointment booked for {service} on {date} at {time}"

agent = RealtimeAgent(
    name="Assistant",
    instructions="You can help with weather and appointments.",
    tools=[get_weather, book_appointment],
)
```

## 핸드오프

### 핸드오프 생성

핸드오프를 사용하면 전문화된 에이전트 간에 대화를 전달할 수 있습니다.

```python
from agents.realtime import realtime_handoff

# Specialized agents
billing_agent = RealtimeAgent(
    name="Billing Support",
    instructions="You specialize in billing and payment issues.",
)

technical_agent = RealtimeAgent(
    name="Technical Support",
    instructions="You handle technical troubleshooting.",
)

# Main agent with handoffs
main_agent = RealtimeAgent(
    name="Customer Service",
    instructions="You are the main customer service agent. Hand off to specialists when needed.",
    handoffs=[
        realtime_handoff(billing_agent, tool_description="Transfer to billing support"),
        realtime_handoff(technical_agent, tool_description="Transfer to technical support"),
    ]
)
```

## 런타임 동작 및 세션 처리

### 이벤트 처리

세션은 세션 객체를 순회(iterating)하여 수신할 수 있는 이벤트를 스트리밍합니다. 이벤트에는 오디오 출력 청크, 트랜스크립션 결과, 도구 실행 시작/종료, 에이전트 핸드오프, 오류가 포함됩니다. 처리해야 할 주요 이벤트는 다음과 같습니다:

-   **audio**: 에이전트 응답의 원시 오디오 데이터
-   **audio_end**: 에이전트 발화 종료
-   **audio_interrupted**: 사용자가 에이전트를 인터럽션(중단 처리)함
-   **tool_start/tool_end**: 도구 실행 라이프사이클
-   **handoff**: 에이전트 핸드오프 발생
-   **error**: 처리 중 오류 발생

전체 이벤트 세부 사항은 [`RealtimeSessionEvent`][agents.realtime.events.RealtimeSessionEvent]를 참고하세요.

### 가드레일

실시간 에이전트에서는 출력 가드레일만 지원됩니다. 이러한 가드레일은 실시간 생성 중 성능 문제를 피하기 위해 디바운스 처리되어 주기적으로(매 단어마다가 아니라) 실행됩니다. 기본 디바운스 길이는 100자이지만 구성할 수 있습니다.

가드레일은 `RealtimeAgent`에 직접 부착하거나 세션의 `run_config`를 통해 제공할 수 있습니다. 두 소스의 가드레일은 함께 실행됩니다.

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

가드레일이 트리거되면 `guardrail_tripped` 이벤트가 생성되며 에이전트의 현재 응답을 인터럽션(중단 처리)할 수 있습니다. 디바운스 동작은 안전성과 실시간 성능 요구 사항 사이의 균형을 맞추는 데 도움이 됩니다. 텍스트 에이전트와 달리, 실시간 에이전트는 가드레일이 트리거되더라도 Exception을 발생시키지 **않습니다**.

### 오디오 처리

[`session.send_audio(audio_bytes)`][agents.realtime.session.RealtimeSession.send_audio]를 사용해 세션에 오디오를 전송하거나, [`session.send_message()`][agents.realtime.session.RealtimeSession.send_message]를 사용해 텍스트를 전송하세요.

오디오 출력의 경우 `audio` 이벤트를 수신하고 선호하는 오디오 라이브러리로 오디오 데이터를 재생하세요. 사용자가 에이전트를 인터럽션(중단 처리)할 때 즉시 재생을 멈추고 대기 중인 오디오를 비우기 위해 `audio_interrupted` 이벤트도 반드시 수신해야 합니다.

## 고급 통합 및 로우 레벨 접근

### SIP 통합

[Realtime Calls API](https://platform.openai.com/docs/guides/realtime-sip)로 들어오는 전화 통화에 실시간 에이전트를 연결할 수 있습니다. SDK는 SIP로 미디어를 협상하면서 동일한 에이전트 흐름을 재사용하는 [`OpenAIRealtimeSIPModel`][agents.realtime.openai_realtime.OpenAIRealtimeSIPModel]을 제공합니다.

사용하려면 모델 인스턴스를 runner에 전달하고, 세션 시작 시 SIP `call_id`를 제공하세요. call ID는 수신 전화를 알리는 웹훅에서 전달됩니다.

```python
from agents.realtime import RealtimeAgent, RealtimeRunner
from agents.realtime.openai_realtime import OpenAIRealtimeSIPModel

runner = RealtimeRunner(
    starting_agent=agent,
    model=OpenAIRealtimeSIPModel(),
)

async with await runner.run(
    model_config={
        "call_id": call_id_from_webhook,
        "initial_model_settings": {
            "turn_detection": {"type": "semantic_vad", "interrupt_response": True},
        },
    },
) as session:
    async for event in session:
        ...
```

발신자가 전화를 끊으면 SIP 세션이 종료되고 실시간 연결도 자동으로 닫힙니다. 전체 텔레포니 예제는 [`examples/realtime/twilio_sip`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/twilio_sip)를 참고하세요.

### 모델 직접 접근

기본 모델에 접근해 커스텀 리스너를 추가하거나 고급 작업을 수행할 수 있습니다:

```python
# Add a custom listener to the model
session.model.add_listener(my_custom_listener)
```

이를 통해 연결에 대한 더 로우 레벨 제어가 필요한 고급 사용 사례를 위해 [`RealtimeModel`][agents.realtime.model.RealtimeModel] 인터페이스에 직접 접근할 수 있습니다.

### 예제 및 추가 읽을거리

완전히 동작하는 예제는 UI 구성 요소 포함/미포함 데모가 있는 [examples/realtime directory](https://github.com/openai/openai-agents-python/tree/main/examples/realtime)를 확인하세요.

### Azure OpenAI 엔드포인트 형식

Azure OpenAI에 연결할 때는 GA Realtime 엔드포인트 형식을 사용하고 `model_config`의 헤더로 자격 증명을 전달하세요:

```python
model_config = {
    "url": "wss://<your-resource>.openai.azure.com/openai/v1/realtime?model=<deployment-name>",
    "headers": {"api-key": "<your-azure-api-key>"},
}
```

토큰 기반 인증의 경우 `headers`에 `{"authorization": f"Bearer {token}"}`를 사용하세요.

================
File: docs/ko/realtime/quickstart.md
================
---
search:
  exclude: true
---
# 빠른 시작

실시간 에이전트를 사용하면 OpenAI의 Realtime API로 AI 에이전트와 음성 대화를 할 수 있습니다. 이 가이드는 첫 번째 실시간 음성 에이전트를 만드는 과정을 안내합니다.

!!! warning "베타 기능"
실시간 에이전트는 베타입니다. 구현을 개선하는 과정에서 일부 변경 사항이 호환성을 깨뜨릴 수 있습니다.

## 사전 요구 사항

-   Python 3.10 이상
-   OpenAI API 키
-   OpenAI Agents SDK에 대한 기본적인 이해

## 설치

아직 설치하지 않았다면 OpenAI Agents SDK를 설치하세요:

```bash
pip install openai-agents
```

## 첫 실시간 에이전트 만들기

### 1. 필요한 구성 요소 가져오기

```python
import asyncio
from agents.realtime import RealtimeAgent, RealtimeRunner
```

### 2. 실시간 에이전트 만들기

```python
agent = RealtimeAgent(
    name="Assistant",
    instructions="You are a helpful voice assistant. Keep your responses conversational and friendly.",
)
```

### 3. 러너 설정하기

```python
runner = RealtimeRunner(
    starting_agent=agent,
    config={
        "model_settings": {
            "model_name": "gpt-realtime",
            "voice": "ash",
            "modalities": ["audio"],
            "input_audio_format": "pcm16",
            "output_audio_format": "pcm16",
            "input_audio_transcription": {"model": "gpt-4o-mini-transcribe"},
            "turn_detection": {"type": "semantic_vad", "interrupt_response": True},
        }
    }
)
```

### 4. 세션 시작하기

```python
# Start the session
session = await runner.run()

async with session:
    print("Session started! The agent will stream audio responses in real-time.")
    # Process events
    async for event in session:
        try:
            if event.type == "agent_start":
                print(f"Agent started: {event.agent.name}")
            elif event.type == "agent_end":
                print(f"Agent ended: {event.agent.name}")
            elif event.type == "handoff":
                print(f"Handoff from {event.from_agent.name} to {event.to_agent.name}")
            elif event.type == "tool_start":
                print(f"Tool started: {event.tool.name}")
            elif event.type == "tool_end":
                print(f"Tool ended: {event.tool.name}; output: {event.output}")
            elif event.type == "audio_end":
                print("Audio ended")
            elif event.type == "audio":
                # Enqueue audio for callback-based playback with metadata
                # Non-blocking put; queue is unbounded, so drops won’t occur.
                pass
            elif event.type == "audio_interrupted":
                print("Audio interrupted")
                # Begin graceful fade + flush in the audio callback and rebuild jitter buffer.
            elif event.type == "error":
                print(f"Error: {event.error}")
            elif event.type == "history_updated":
                pass  # Skip these frequent events
            elif event.type == "history_added":
                pass  # Skip these frequent events
            elif event.type == "raw_model_event":
                print(f"Raw model event: {_truncate_str(str(event.data), 200)}")
            else:
                print(f"Unknown event type: {event.type}")
        except Exception as e:
            print(f"Error processing event: {_truncate_str(str(e), 200)}")

def _truncate_str(s: str, max_length: int) -> str:
    if len(s) > max_length:
        return s[:max_length] + "..."
    return s
```

## 전체 예제(동일한 흐름을 한 파일로)

동일한 빠른 시작 흐름을 단일 스크립트로 다시 작성한 것입니다.

```python
import asyncio
from agents.realtime import RealtimeAgent, RealtimeRunner

async def main():
    # Create the agent
    agent = RealtimeAgent(
        name="Assistant",
        instructions="You are a helpful voice assistant. Keep responses brief and conversational.",
    )
    # Set up the runner with configuration
    runner = RealtimeRunner(
        starting_agent=agent,
        config={
            "model_settings": {
                "model_name": "gpt-realtime",
                "voice": "ash",
                "modalities": ["audio"],
                "input_audio_format": "pcm16",
                "output_audio_format": "pcm16",
                "input_audio_transcription": {"model": "gpt-4o-mini-transcribe"},
                "turn_detection": {"type": "semantic_vad", "interrupt_response": True},
            }
        },
    )
    # Start the session
    session = await runner.run()

    async with session:
        print("Session started! The agent will stream audio responses in real-time.")
        # Process events
        async for event in session:
            try:
                if event.type == "agent_start":
                    print(f"Agent started: {event.agent.name}")
                elif event.type == "agent_end":
                    print(f"Agent ended: {event.agent.name}")
                elif event.type == "handoff":
                    print(f"Handoff from {event.from_agent.name} to {event.to_agent.name}")
                elif event.type == "tool_start":
                    print(f"Tool started: {event.tool.name}")
                elif event.type == "tool_end":
                    print(f"Tool ended: {event.tool.name}; output: {event.output}")
                elif event.type == "audio_end":
                    print("Audio ended")
                elif event.type == "audio":
                    # Enqueue audio for callback-based playback with metadata
                    # Non-blocking put; queue is unbounded, so drops won’t occur.
                    pass
                elif event.type == "audio_interrupted":
                    print("Audio interrupted")
                    # Begin graceful fade + flush in the audio callback and rebuild jitter buffer.
                elif event.type == "error":
                    print(f"Error: {event.error}")
                elif event.type == "history_updated":
                    pass  # Skip these frequent events
                elif event.type == "history_added":
                    pass  # Skip these frequent events
                elif event.type == "raw_model_event":
                    print(f"Raw model event: {_truncate_str(str(event.data), 200)}")
                else:
                    print(f"Unknown event type: {event.type}")
            except Exception as e:
                print(f"Error processing event: {_truncate_str(str(e), 200)}")

def _truncate_str(s: str, max_length: int) -> str:
    if len(s) > max_length:
        return s[:max_length] + "..."
    return s

if __name__ == "__main__":
    # Run the session
    asyncio.run(main())
```

## 구성 및 배포 참고 사항

기본 세션이 실행된 뒤 아래 옵션을 사용하세요.

### 모델 설정

-   `model_name`: 사용 가능한 실시간 모델에서 선택(예: `gpt-realtime`)
-   `voice`: 음성 선택(`alloy`, `echo`, `fable`, `onyx`, `nova`, `shimmer`)
-   `modalities`: 텍스트 또는 오디오 활성화(`["text"]` 또는 `["audio"]`)
-   `output_modalities`: 출력이 텍스트 및/또는 오디오로만 나오도록 선택적으로 제한(`["text"]`, `["audio"]`, 또는 둘 다)

### 오디오 설정

-   `input_audio_format`: 입력 오디오 형식(`pcm16`, `g711_ulaw`, `g711_alaw`)
-   `output_audio_format`: 출력 오디오 형식
-   `input_audio_transcription`: 전사 구성
-   `input_audio_noise_reduction`: 입력 노이즈 감소 구성(`near_field` 또는 `far_field`)

### 턴 감지

-   `type`: 감지 방식(`server_vad`, `semantic_vad`)
-   `threshold`: 음성 활동 임계값(0.0-1.0)
-   `silence_duration_ms`: 턴 종료를 감지하기 위한 무음 지속 시간
-   `prefix_padding_ms`: 발화 전 오디오 패딩

### 실행 설정

-   `async_tool_calls`: 함수 도구를 비동기로 실행할지 여부(기본값 `True`)
-   `guardrails_settings.debounce_text_length`: 출력 가드레일을 실행하기 전에 누적되어야 하는 전사 최소 크기(기본값 `100`)
-   `tool_error_formatter`: 모델에 보이는 도구 오류 메시지를 커스터마이즈하는 콜백

전체 스키마는 [`RealtimeRunConfig`][agents.realtime.config.RealtimeRunConfig] 및 [`RealtimeSessionModelSettings`][agents.realtime.config.RealtimeSessionModelSettings]의 API 레퍼런스를 참고하세요.

### 인증

환경에 OpenAI API 키가 설정되어 있는지 확인하세요:

```bash
export OPENAI_API_KEY="your-api-key-here"
```

또는 세션을 만들 때 직접 전달하세요:

```python
session = await runner.run(model_config={"api_key": "your-api-key"})
```

### Azure OpenAI 엔드포인트 형식

OpenAI의 기본 엔드포인트 대신 Azure OpenAI에 연결하는 경우, GA Realtime URL을 `model_config["url"]`에 전달하고 인증 헤더를 명시적으로 설정하세요.

```python
session = await runner.run(
    model_config={
        "url": "wss://<your-resource>.openai.azure.com/openai/v1/realtime?model=<deployment-name>",
        "headers": {"api-key": "<your-azure-api-key>"},
    }
)
```

bearer 토큰도 사용할 수 있습니다:

```python
session = await runner.run(
    model_config={
        "url": "wss://<your-resource>.openai.azure.com/openai/v1/realtime?model=<deployment-name>",
        "headers": {"authorization": f"Bearer {token}"},
    }
)
```

실시간 에이전트에서는 레거시 베타 경로(`/openai/realtime?api-version=...`) 사용을 피하세요. SDK는 GA Realtime 인터페이스를 기대합니다.

## 다음 단계

-   [실시간 에이전트 더 알아보기](guide.md)
-   [examples/realtime](https://github.com/openai/openai-agents-python/tree/main/examples/realtime) 폴더의 동작하는 예제 확인하기
-   에이전트에 도구 추가하기
-   에이전트 간 핸드오프 구현하기
-   안전을 위한 가드레일 설정하기

================
File: docs/ko/sessions/advanced_sqlite_session.md
================
---
search:
  exclude: true
---
# 고급 SQLite 세션

`AdvancedSQLiteSession`은 기본 `SQLiteSession`을 확장한 버전으로, 대화 분기, 상세 사용량 분석, 구조화된 대화 쿼리 등 고급 대화 관리 기능을 제공합니다.

## 기능

- **대화 분기**: 임의의 사용자 메시지에서 대체 대화 경로 생성
- **사용량 추적**: 전체 JSON 분해와 함께 턴별 상세 토큰 사용량 분석
- **구조화된 쿼리**: 턴별 대화 조회, 도구 사용 통계 등 제공
- **분기 관리**: 독립적인 분기 전환 및 관리
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
- `db_path` (str | Path): SQLite 데이터베이스 파일 경로. 인메모리 저장을 위해 기본값은 `:memory:`
- `create_tables` (bool): 고급 테이블을 자동 생성할지 여부. 기본값은 `False`
- `logger` (logging.Logger | None): 세션에 사용할 커스텀 로거. 기본값은 모듈 로거

## 사용량 추적

AdvancedSQLiteSession은 대화 턴별 토큰 사용량 데이터를 저장하여 상세 사용량 분석을 제공합니다. **이는 각 에이전트 실행 후 `store_run_usage` 메서드를 호출하는 것에 전적으로 의존합니다.**

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

### 사용량 통계 가져오기

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

## 대화 분기

AdvancedSQLiteSession의 핵심 기능 중 하나는 임의의 사용자 메시지에서 대화 분기를 생성하여 대체 대화 경로를 탐색할 수 있는 능력입니다.

### 분기 생성

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

### 분기 관리

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

### 분기 워크플로 예시

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

AdvancedSQLiteSession은 대화 구조와 콘텐츠를 분석하기 위한 여러 메서드를 제공합니다.

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

세션은 다음을 포함하여 메시지 구조를 자동으로 추적합니다:

- 메시지 유형(user, assistant, tool_call 등)
- 도구 호출의 도구 이름
- 턴 번호와 시퀀스 번호
- 분기 연관
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

## 전체 sample code

모든 기능을 포괄적으로 보여주는 [complete example](https://github.com/openai/openai-agents-python/tree/main/examples/memory/advanced_sqlite_session_example.py)을 확인하세요.

## API 레퍼런스

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

`EncryptedSession`은 모든 세션 구현에 투명한 암호화를 제공하여 대화 데이터를 보호하고, 오래된 항목을 자동으로 만료 처리합니다.

## 기능

- **투명한 암호화**: 어떤 세션이든 Fernet 암호화로 감쌈
- **세션별 키**: 각 세션마다 고유 암호화를 위해 HKDF 키 파생 사용
- **자동 만료**: TTL이 만료되면 오래된 항목을 조용히 건너뜀
- **대체 가능**: 기존 세션 구현과 그대로 호환

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

암호화 키는 Fernet 키이거나 임의의 문자열일 수 있습니다:

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

### TTL (Time To Live)

암호화된 항목이 유효한 기간을 설정합니다:

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

## 다양한 세션 타입과의 사용

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

    `EncryptedSession`을 `AdvancedSQLiteSession` 같은 고급 세션 구현과 함께 사용할 때에는 다음을 유의하세요:

    - 메시지 콘텐츠가 암호화되므로 `find_turns_by_content()` 같은 메서드는 효과적으로 동작하지 않음
    - 콘텐츠 기반 검색은 암호화된 데이터에서 수행되므로 효과가 제한됨



## 키 파생

EncryptedSession은 HKDF (HMAC 기반 키 파생 함수)를 사용하여 세션마다 고유한 암호화 키를 파생합니다:

- **마스터 키**: 사용자가 제공한 암호화 키
- **세션 솔트**: 세션 ID
- **정보 문자열**: `"agents.session-store.hkdf.v1"`
- **출력**: 32바이트 Fernet 키

이는 다음을 보장합니다:
- 각 세션은 고유한 암호화 키를 가짐
- 마스터 키 없이는 키를 파생할 수 없음
- 서로 다른 세션 간에는 세션 데이터를 복호화할 수 없음

## 자동 만료

항목이 TTL을 초과하면 조회 시 자동으로 건너뜁니다:

```python
# Items older than TTL are silently ignored
items = await session.get_items()  # Only returns non-expired items

# Expired items don't affect session behavior
result = await Runner.run(agent, "Continue conversation", session=session)
```

## API 레퍼런스

- [`EncryptedSession`][agents.extensions.memory.encrypt_session.EncryptedSession] - 메인 클래스
- [`Session`][agents.memory.session.Session] - 기본 세션 프로토콜

================
File: docs/ko/sessions/index.md
================
---
search:
  exclude: true
---
# 세션

Agents SDK는 여러 에이전트 실행 전반에서 대화 기록을 자동으로 유지하는 내장 세션 메모리를 제공하므로, 턴 사이에 `.to_input_list()`를 수동으로 처리할 필요가 없습니다

세션은 특정 세션의 대화 기록을 저장하여, 명시적인 수동 메모리 관리 없이도 에이전트가 컨텍스트를 유지할 수 있게 합니다. 이는 에이전트가 이전 상호작용을 기억해야 하는 채팅 애플리케이션이나 멀티턴 대화를 구축할 때 특히 유용합니다

SDK가 클라이언트 측 메모리를 대신 관리하도록 하려면 세션을 사용하세요. 이미 `conversation_id` 또는 `previous_response_id`로 OpenAI 서버 관리 상태를 사용 중이라면, 일반적으로 동일한 대화에 대해 세션도 함께 사용할 필요는 없습니다

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

## 동일한 세션으로 중단된 실행 재개

실행이 승인 때문에 일시 중지되면, 동일한 세션 인스턴스(또는 동일한 백킹 스토리지를 가리키는 다른 세션 인스턴스)로 재개하여 재개된 턴이 동일한 저장 대화 기록을 이어가도록 하세요

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

1. **각 실행 전**: 러너가 세션의 대화 기록을 자동으로 조회하고 입력 항목 앞에 추가합니다
2. **각 실행 후**: 실행 중 생성된 모든 새 항목(사용자 입력, 어시스턴트 응답, 도구 호출 등)이 세션에 자동 저장됩니다
3. **컨텍스트 보존**: 동일한 세션으로 이어지는 각 실행은 전체 대화 기록을 포함하므로, 에이전트가 컨텍스트를 유지할 수 있습니다

이로써 `.to_input_list()`를 수동으로 호출하고 실행 간 대화 상태를 관리할 필요가 없어집니다

## 기록과 새 입력의 병합 방식 제어

세션을 전달하면, 러너는 일반적으로 다음과 같이 모델 입력을 준비합니다:

1. 세션 기록(`session.get_items(...)`에서 조회)
2. 새 턴 입력

모델 호출 전에 이 병합 단계를 사용자 지정하려면 [`RunConfig.session_input_callback`][agents.run.RunConfig.session_input_callback]을 사용하세요. 콜백은 두 개의 리스트를 받습니다:

-   `history`: 조회된 세션 기록(이미 입력 항목 형식으로 정규화됨)
-   `new_input`: 현재 턴의 새 입력 항목

모델로 보낼 최종 입력 항목 리스트를 반환하세요

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

세션이 항목을 저장하는 방식을 바꾸지 않고도 사용자 지정 가지치기, 재정렬 또는 기록의 선택적 포함이 필요할 때 유용합니다

## 조회 기록 제한

각 실행 전에 가져올 기록량을 제어하려면 [`SessionSettings`][agents.memory.SessionSettings]를 사용하세요

-   `SessionSettings(limit=None)` (기본값): 사용 가능한 모든 세션 항목 조회
-   `SessionSettings(limit=N)`: 가장 최근 `N`개 항목만 조회

[`RunConfig.session_settings`][agents.run.RunConfig.session_settings]를 통해 실행별로 적용할 수 있습니다:

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

세션 구현이 기본 세션 설정을 제공하는 경우, `RunConfig.session_settings`는 해당 실행에서 `None`이 아닌 값을 우선 적용합니다. 이는 긴 대화에서 세션의 기본 동작은 유지하면서 조회 크기만 제한하고 싶을 때 유용합니다

## 메모리 작업

### 기본 작업

세션은 대화 기록 관리를 위한 여러 작업을 지원합니다:

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

### 수정 시 pop_item 사용

`pop_item` 메서드는 대화의 마지막 항목을 되돌리거나 수정하려는 경우 특히 유용합니다:

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

SDK는 다양한 사용 사례를 위한 여러 세션 구현을 제공합니다:

### 내장 세션 구현 선택

아래의 상세 예제를 보기 전에 이 표를 사용해 시작점을 선택하세요

| Session type | Best for | Notes |
| --- | --- | --- |
| `SQLiteSession` | 로컬 개발 및 간단한 앱 | 내장형, 경량, 파일 기반 또는 인메모리 |
| `AsyncSQLiteSession` | `aiosqlite`를 사용하는 비동기 SQLite | 비동기 드라이버를 지원하는 확장 백엔드 |
| `RedisSession` | 워커/서비스 간 공유 메모리 | 저지연 분산 배포에 적합 |
| `SQLAlchemySession` | 기존 데이터베이스가 있는 프로덕션 앱 | SQLAlchemy가 지원하는 데이터베이스에서 작동 |
| `OpenAIConversationsSession` | OpenAI의 서버 관리 스토리지 | OpenAI Conversations API 기반 기록 |
| `OpenAIResponsesCompactionSession` | 자동 압축이 필요한 긴 대화 | 다른 세션 백엔드를 감싸는 래퍼 |
| `AdvancedSQLiteSession` | 브랜칭/분석 기능이 추가된 SQLite | 기능이 더 많음, 전용 페이지 참조 |
| `EncryptedSession` | 다른 세션 위에 암호화 + TTL | 래퍼, 먼저 하위 백엔드 선택 필요 |

일부 구현에는 추가 세부 정보가 있는 전용 페이지가 있으며, 해당 하위 섹션에 인라인 링크되어 있습니다

### OpenAI Conversations API 세션

`OpenAIConversationsSession`을 통해 [OpenAI's Conversations API](https://platform.openai.com/docs/api-reference/conversations)를 사용하세요

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

### OpenAI Responses 압축 세션

Responses API(`responses.compact`)로 저장된 대화 기록을 압축하려면 `OpenAIResponsesCompactionSession`을 사용하세요. 이는 하위 세션을 감싸며, `should_trigger_compaction`에 따라 각 턴 후 자동으로 압축할 수 있습니다. `OpenAIConversationsSession`을 이로 감싸지 마세요. 두 기능은 서로 다른 방식으로 기록을 관리합니다

#### 일반적인 사용법(자동 압축)

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

기본적으로 자동 압축은 후보 임계값에 도달하면 각 턴 후 실행됩니다

`compaction_mode="previous_response_id"`는 이미 Responses API 응답 ID로 턴을 연결하고 있을 때 가장 잘 작동합니다. `compaction_mode="input"`은 대신 현재 세션 항목에서 압축 요청을 재구성하며, 응답 체인을 사용할 수 없거나 세션 내용을 단일 진실 소스로 사용하려는 경우 유용합니다. 기본값 `"auto"`는 사용 가능한 가장 안전한 옵션을 선택합니다

#### 자동 압축은 스트리밍을 블로킹할 수 있음

압축은 세션 기록을 지우고 다시 작성하므로, SDK는 실행 완료로 간주하기 전에 압축이 끝날 때까지 기다립니다. 스트리밍 모드에서는 압축 작업이 무거운 경우 마지막 출력 토큰 이후에도 `run.stream_events()`가 몇 초 동안 열린 상태로 유지될 수 있습니다

저지연 스트리밍이나 빠른 턴 전환이 필요하다면 자동 압축을 비활성화하고 턴 사이(또는 유휴 시간)에 직접 `run_compaction()`을 호출하세요. 자체 기준에 따라 압축 강제 시점을 결정할 수 있습니다

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

SQLite를 사용하는 기본 경량 세션 구현입니다:

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

### Async SQLite 세션

`aiosqlite` 기반의 SQLite 영속성이 필요하면 `AsyncSQLiteSession`을 사용하세요

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

여러 워커나 서비스 간 공유 세션 메모리가 필요하면 `RedisSession`을 사용하세요

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

SQLAlchemy가 지원하는 모든 데이터베이스를 사용하는 프로덕션 준비 세션입니다:

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

자세한 문서는 [SQLAlchemy Sessions](sqlalchemy_session.md)를 참조하세요



### 고급 SQLite 세션

대화 브랜칭, 사용량 분석, 구조화된 쿼리를 지원하는 확장 SQLite 세션입니다:

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

자세한 문서는 [Advanced SQLite Sessions](advanced_sqlite_session.md)를 참조하세요

### 암호화 세션

모든 세션 구현에 대한 투명한 암호화 래퍼입니다:

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

자세한 문서는 [Encrypted Sessions](encrypted_session.md)를 참조하세요

### 기타 세션 유형

몇 가지 내장 옵션이 더 있습니다. `examples/memory/` 및 `extensions/memory/` 아래의 소스 코드를 참조하세요

## 운영 패턴

### 세션 ID 네이밍

대화를 정리하는 데 도움이 되는 의미 있는 세션 ID를 사용하세요:

-   사용자 기반: `"user_12345"`
-   스레드 기반: `"thread_abc123"`
-   컨텍스트 기반: `"support_ticket_456"`

### 메모리 영속성

-   임시 대화에는 인메모리 SQLite(`SQLiteSession("session_id")`) 사용
-   영구 대화에는 파일 기반 SQLite(`SQLiteSession("session_id", "path/to/db.sqlite")`) 사용
-   `aiosqlite` 기반 구현이 필요하면 async SQLite(`AsyncSQLiteSession("session_id", db_path="...")`) 사용
-   공유 저지연 세션 메모리에는 Redis 기반 세션(`RedisSession.from_url("session_id", url="redis://...")`) 사용
-   SQLAlchemy가 지원하는 기존 데이터베이스가 있는 프로덕션 시스템에는 SQLAlchemy 기반 세션(`SQLAlchemySession("session_id", engine=engine, create_tables=True)`) 사용
-   기본 제공 텔레메트리, 트레이싱, 데이터 격리를 갖춘 30개 이상 데이터베이스 백엔드를 지원하는 프로덕션 클라우드 네이티브 배포에는 Dapr 상태 저장소 세션(`DaprSession.from_address("session_id", state_store_name="statestore", dapr_address="localhost:50001")`) 사용
-   기록을 OpenAI Conversations API에 저장하려면 OpenAI 호스팅 스토리지(`OpenAIConversationsSession()`) 사용
-   모든 세션을 투명한 암호화 및 TTL 기반 만료로 감싸려면 암호화 세션(`EncryptedSession(session_id, underlying_session, encryption_key)`) 사용
-   더 고급 사용 사례를 위해 다른 프로덕션 시스템(예: Django)용 사용자 지정 세션 백엔드 구현 고려

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

다음은 세션 메모리 동작을 보여주는 전체 예제입니다:

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

## 사용자 지정 세션 구현

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
| [openai-django-sessions](https://pypi.org/project/openai-django-sessions/) | Django가 지원하는 모든 데이터베이스(PostgreSQL, MySQL, SQLite 등)를 위한 Django ORM 기반 세션 |

세션 구현을 만드셨다면, 여기에 추가할 수 있도록 문서 PR을 자유롭게 제출해 주세요!

## API 참조

자세한 API 문서는 다음을 참조하세요:

-   [`Session`][agents.memory.session.Session] - 프로토콜 인터페이스
-   [`OpenAIConversationsSession`][agents.memory.OpenAIConversationsSession] - OpenAI Conversations API 구현
-   [`OpenAIResponsesCompactionSession`][agents.memory.openai_responses_compaction_session.OpenAIResponsesCompactionSession] - Responses API 압축 래퍼
-   [`SQLiteSession`][agents.memory.sqlite_session.SQLiteSession] - 기본 SQLite 구현
-   [`AsyncSQLiteSession`][agents.extensions.memory.async_sqlite_session.AsyncSQLiteSession] - `aiosqlite` 기반 비동기 SQLite 구현
-   [`RedisSession`][agents.extensions.memory.redis_session.RedisSession] - Redis 기반 세션 구현
-   [`SQLAlchemySession`][agents.extensions.memory.sqlalchemy_session.SQLAlchemySession] - SQLAlchemy 기반 구현
-   [`DaprSession`][agents.extensions.memory.dapr_session.DaprSession] - Dapr 상태 저장소 구현
-   [`AdvancedSQLiteSession`][agents.extensions.memory.advanced_sqlite_session.AdvancedSQLiteSession] - 브랜칭 및 분석 기능이 있는 확장 SQLite
-   [`EncryptedSession`][agents.extensions.memory.encrypt_session.EncryptedSession] - 모든 세션용 암호화 래퍼

================
File: docs/ko/sessions/sqlalchemy_session.md
================
---
search:
  exclude: true
---
# SQLAlchemy 세션

`SQLAlchemySession`은 SQLAlchemy를 사용해 프로덕션급 세션 구현을 제공하며, 세션 저장소로 SQLAlchemy가 지원하는 모든 데이터베이스(PostgreSQL, MySQL, SQLite 등)를 사용할 수 있습니다.

## 설치

SQLAlchemy 세션에는 `sqlalchemy` extra가 필요합니다:

```bash
pip install openai-agents[sqlalchemy]
```

## 빠른 시작

### 데이터베이스 URL 사용

가장 간단한 시작 방법:

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


## API 레퍼런스

- [`SQLAlchemySession`][agents.extensions.memory.sqlalchemy_session.SQLAlchemySession] - 주요 클래스
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

에이전트는 앱의 핵심 구성 요소입니다. 에이전트는 instructions와 tools로 구성된 대규모 언어 모델(LLM)입니다

## 기본 구성

에이전트에서 가장 일반적으로 구성하는 속성은 다음과 같습니다:

-   `name`: 에이전트를 식별하는 필수 문자열
-   `instructions`: developer message 또는 시스템 프롬프트라고도 합니다
-   `model`: 사용할 LLM, 그리고 temperature, top_p 등과 같은 모델 튜닝 매개변수를 구성하기 위한 선택적 `model_settings`
-   `prompt`: OpenAI의 Responses API를 사용할 때 id(및 변수)로 프롬프트 템플릿을 참조합니다
-   `tools`: 에이전트가 작업을 수행하기 위해 사용할 수 있는 도구
-   `mcp_servers`: 에이전트에 도구를 제공하는 MCP 서버. [MCP 가이드](mcp.md)를 참고하세요
-   `reset_tool_choice`: 도구 호출 이후 `tool_choice`를 재설정할지 여부(기본값: `True`). 도구 사용 루프를 방지합니다. [도구 사용 강제](#forcing-tool-use)를 참고하세요

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

`prompt`를 설정하면 OpenAI 플랫폼에서 생성한 프롬프트 템플릿을 참조할 수 있습니다. 이는 Responses API를 사용하는 OpenAI 모델에서 동작합니다

사용하려면 다음을 진행하세요:

1. https://platform.openai.com/playground/prompts 로 이동합니다
2. 새 프롬프트 변수 `poem_style`를 생성합니다
3. 다음 내용으로 시스템 프롬프트를 생성합니다:

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

에이전트는 `context` 타입에 대해 범용적입니다. 컨텍스트는 의존성 주입 도구입니다: 사용자가 생성하여 `Runner.run()`에 전달하는 객체이며, 모든 에이전트, 도구, 핸드오프 등에 전달됩니다. 또한 에이전트 실행을 위한 의존성과 상태를 담는 저장소 역할을 합니다. 컨텍스트로는 어떤 Python 객체든 제공할 수 있습니다

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

기본적으로 에이전트는 일반 텍스트(즉, `str`) 출력을 생성합니다. 에이전트가 특정 출력 타입을 생성하도록 하려면 `output_type` 매개변수를 사용할 수 있습니다. 일반적인 선택지는 [Pydantic](https://docs.pydantic.dev/) 객체이며, Pydantic의 [TypeAdapter](https://docs.pydantic.dev/latest/api/type_adapter/)로 감쌀 수 있는 모든 타입을 지원합니다 - dataclass, list, TypedDict 등

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

    `output_type`을 전달하면, 일반 일반 텍스트 응답 대신 [structured outputs](https://platform.openai.com/docs/guides/structured-outputs)을 사용하도록 모델에 지시합니다

## 멀티 에이전트 시스템 설계 패턴

멀티 에이전트 시스템을 설계하는 방법은 다양하지만, 일반적으로 폭넓게 적용 가능한 두 가지 패턴이 자주 사용됩니다:

1. 매니저(Agents as tools): 중앙 매니저/오케스트레이터가 전문화된 하위 에이전트를 도구로 호출하고 대화 제어권을 유지합니다
2. 핸드오프: 동등한 에이전트들이 전문화된 에이전트에게 제어권을 넘기고, 해당 에이전트가 대화를 이어받습니다. 이는 분산형 방식입니다

자세한 내용은 [에이전트 구축 실전 가이드](https://cdn.openai.com/business-guides-and-resources/a-practical-guide-to-building-agents.pdf)를 참고하세요

### 매니저(Agents as tools)

`customer_facing_agent`는 모든 사용자 상호작용을 처리하고, 도구로 노출된 전문화된 하위 에이전트를 호출합니다. 자세한 내용은 [tools](tools.md#agents-as-tools) 문서를 참고하세요

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

핸드오프는 에이전트가 위임할 수 있는 하위 에이전트입니다. 핸드오프가 발생하면 위임된 에이전트가 대화 기록을 전달받고 대화를 이어받습니다. 이 패턴은 단일 작업에 뛰어난 모듈식 전문 에이전트를 가능하게 합니다. 자세한 내용은 [handoffs](handoffs.md) 문서를 참고하세요

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

대부분의 경우 에이전트를 생성할 때 instructions를 제공할 수 있습니다. 하지만 함수로 동적 instructions를 제공할 수도 있습니다. 함수는 에이전트와 컨텍스트를 입력받아 프롬프트를 반환해야 합니다. 일반 함수와 `async` 함수 모두 허용됩니다

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

## 생명주기 이벤트(hooks)

때로는 에이전트의 생명주기를 관찰하고 싶을 수 있습니다. 예를 들어 이벤트 로깅, 데이터 사전 로드, 특정 이벤트 발생 시 사용량 기록 등을 할 수 있습니다

hook 범위는 두 가지입니다:

-   [`RunHooks`][agents.lifecycle.RunHooks]는 다른 에이전트로의 핸드오프를 포함해 전체 `Runner.run(...)` 호출을 관찰합니다
-   [`AgentHooks`][agents.lifecycle.AgentHooks]는 `agent.hooks`를 통해 특정 에이전트 인스턴스에 연결됩니다

콜백 컨텍스트도 이벤트에 따라 달라집니다:

-   에이전트 시작/종료 hook은 [`AgentHookContext`][agents.run_context.AgentHookContext]를 받으며, 이는 원래 컨텍스트를 래핑하고 공유 실행 사용량 상태를 포함합니다
-   LLM, 도구, 핸드오프 hook은 [`RunContextWrapper`][agents.run_context.RunContextWrapper]를 받습니다

일반적인 hook 시점:

-   `on_agent_start` / `on_agent_end`: 특정 에이전트가 최종 출력을 생성하기 시작하거나 마칠 때
-   `on_llm_start` / `on_llm_end`: 각 모델 호출의 직전/직후
-   `on_tool_start` / `on_tool_end`: 각 로컬 도구 호출의 전후
-   `on_handoff`: 제어권이 한 에이전트에서 다른 에이전트로 이동할 때

전체 워크플로에 대한 단일 관찰자가 필요하면 `RunHooks`를, 특정 에이전트에 사용자 지정 부수 효과가 필요하면 `AgentHooks`를 사용하세요

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

전체 콜백 표면은 [Lifecycle API 레퍼런스](ref/lifecycle.md)를 참고하세요

## 가드레일

가드레일을 사용하면 에이전트가 실행되는 동안 사용자 입력에 대한 검사/검증을 병렬로 실행하고, 에이전트 출력이 생성된 후에도 검사할 수 있습니다. 예를 들어 사용자 입력과 에이전트 출력의 관련성을 검사할 수 있습니다. 자세한 내용은 [guardrails](guardrails.md) 문서를 참고하세요

## 에이전트 복제/복사

에이전트에서 `clone()` 메서드를 사용하면 Agent를 복제하고, 원하는 속성을 선택적으로 변경할 수 있습니다

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

1. `auto`: 도구 사용 여부를 LLM이 결정할 수 있습니다
2. `required`: LLM이 도구를 반드시 사용해야 합니다(어떤 도구를 사용할지는 지능적으로 결정할 수 있습니다)
3. `none`: LLM이 도구를 사용하지 않아야 합니다
4. 예: `my_tool` 같은 특정 문자열 설정: LLM이 해당 특정 도구를 사용해야 합니다

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

`Agent` 구성의 `tool_use_behavior` 매개변수는 도구 출력이 처리되는 방식을 제어합니다:

- `"run_llm_again"`: 기본값입니다. 도구를 실행하고, LLM이 결과를 처리해 최종 응답을 생성합니다
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

- `StopAtTools(stop_at_tool_names=[...])`: 지정된 도구 중 하나가 호출되면 중단하고, 해당 출력을 최종 응답으로 사용합니다

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

- `ToolsToFinalOutputFunction`: 도구 결과를 처리하고 LLM으로 계속 진행할지 중단할지를 결정하는 사용자 지정 함수입니다

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

    무한 루프를 방지하기 위해 프레임워크는 도구 호출 후 `tool_choice`를 자동으로 "auto"로 재설정합니다. 이 동작은 [`agent.reset_tool_choice`][agents.agent.Agent.reset_tool_choice]로 구성할 수 있습니다. 무한 루프는 도구 결과가 LLM으로 전송되고, `tool_choice` 때문에 LLM이 다시 도구 호출을 생성하는 과정이 무한 반복되기 때문에 발생합니다

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

컨텍스트는 의미가 중첩된 용어입니다. 관심을 가질 수 있는 컨텍스트는 크게 두 가지 범주가 있습니다:

1. 코드에서 로컬로 사용할 수 있는 컨텍스트: 도구 함수 실행 시, `on_handoff` 같은 콜백 중, 라이프사이클 훅 등에서 필요할 수 있는 데이터와 의존성입니다
2. LLM에서 사용할 수 있는 컨텍스트: 응답을 생성할 때 LLM이 보게 되는 데이터입니다

## 로컬 컨텍스트

이는 [`RunContextWrapper`][agents.run_context.RunContextWrapper] 클래스와 그 안의 [`context`][agents.run_context.RunContextWrapper.context] 프로퍼티로 표현됩니다. 동작 방식은 다음과 같습니다:

1. 원하는 어떤 파이썬 객체든 생성합니다. 흔한 패턴은 dataclass 또는 Pydantic 객체를 사용하는 것입니다
2. 해당 객체를 다양한 run 메서드(예: `Runner.run(..., context=whatever)`)에 전달합니다
3. 모든 도구 호출, 라이프사이클 훅 등에는 래퍼 객체 `RunContextWrapper[T]`가 전달되며, 여기서 `T`는 `wrapper.context`로 접근할 수 있는 컨텍스트 객체의 타입을 나타냅니다

가장 **중요한** 점: 특정 에이전트 run에 대해, 해당 run에서 사용되는 모든 에이전트, 도구 함수, 라이프사이클 등은 동일한 컨텍스트 _타입_을 사용해야 합니다

컨텍스트는 다음과 같은 용도로 사용할 수 있습니다:

- 실행에 대한 컨텍스트 데이터(예: 사용자 이름/uid 또는 사용자에 대한 기타 정보)
- 의존성(예: 로거 객체, 데이터 페처 등)
- 헬퍼 함수

!!! danger "Note"

    컨텍스트 객체는 **LLM에 전송되지 않습니다**. 이는 순수하게 로컬 객체로, 읽고/쓰고/메서드를 호출할 수 있습니다

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

1. 이것이 컨텍스트 객체입니다. 여기서는 dataclass를 사용했지만 어떤 타입이든 사용할 수 있습니다
2. 이것은 도구입니다. `RunContextWrapper[UserInfo]`를 받는 것을 볼 수 있습니다. 도구 구현은 컨텍스트에서 값을 읽습니다
3. 타입체커가 오류를 잡을 수 있도록(예: 다른 컨텍스트 타입을 받는 도구를 전달하려고 할 때) 에이전트에 제네릭 `UserInfo`를 표시합니다
4. 컨텍스트는 `run` 함수에 전달됩니다
5. 에이전트는 도구를 올바르게 호출하고 나이를 얻습니다

---

### 고급: `ToolContext`

일부 경우에는 실행 중인 도구에 대한 추가 메타데이터(예: 이름, 호출 ID, 원문 인자 문자열)에 접근하고 싶을 수 있습니다.  
이를 위해 `RunContextWrapper`를 확장한 [`ToolContext`][agents.tool_context.ToolContext] 클래스를 사용할 수 있습니다.

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

`ToolContext`는 `RunContextWrapper`와 동일한 `.context` 프로퍼티를 제공하며,  
여기에 더해 현재 도구 호출에 특화된 추가 필드를 제공합니다:

- `tool_name` – 호출되는 도구의 이름  
- `tool_call_id` – 이 도구 호출을 위한 고유 식별자  
- `tool_arguments` – 도구에 전달된 원문 인자 문자열  

실행 중 도구 수준의 메타데이터가 필요할 때 `ToolContext`를 사용하세요.  
에이전트와 도구 간 일반적인 컨텍스트 공유에는 `RunContextWrapper`만으로도 충분합니다.

---

## 에이전트/LLM 컨텍스트

LLM이 호출될 때, LLM이 볼 수 있는 데이터는 대화 히스토리에서 온 것 **뿐**입니다. 즉, 새로운 데이터를 LLM에서 사용할 수 있게 만들고 싶다면, 해당 데이터가 그 히스토리에 포함되도록 하는 방식으로 해야 합니다. 이를 위한 몇 가지 방법이 있습니다:

1. Agent `instructions`에 추가할 수 있습니다. 이는 "system prompt" 또는 "developer message"라고도 합니다. 시스템 프롬프트는 정적인 문자열일 수도 있고, 컨텍스트를 받아 문자열을 출력하는 동적 함수일 수도 있습니다. 이는 항상 유용한 정보(예: 사용자 이름 또는 현재 날짜)에 대한 일반적인 전술입니다
2. `Runner.run` 함수를 호출할 때 `input`에 추가합니다. 이는 `instructions` 전술과 유사하지만, [chain of command](https://cdn.openai.com/spec/model-spec-2024-05-08.html#follow-the-chain-of-command)에서 더 낮은 수준의 메시지를 둘 수 있습니다
3. 함수 도구를 통해 노출합니다. 이는 _온디맨드_ 컨텍스트에 유용합니다. LLM이 언제 어떤 데이터가 필요한지 결정하고, 해당 데이터를 가져오기 위해 도구를 호출할 수 있습니다
4. retrieval 또는 웹 검색을 사용합니다. 이는 파일이나 데이터베이스에서 관련 데이터를 가져오거나(retrieval), 웹에서 가져올 수 있는(웹 검색) 특수 도구입니다. 이는 응답을 관련 컨텍스트 데이터에 "그라운딩"하는 데 유용합니다

================
File: docs/ko/examples.md
================
---
search:
  exclude: true
---
# 예제

[repo](https://github.com/openai/openai-agents-python/tree/main/examples)의 examples 섹션에서 SDK의 다양한 sample 구현을 확인하세요. examples는 여러 카테고리로 구성되어 있으며, 서로 다른 패턴과 기능을 보여줍니다.

## 카테고리

-   **[agent_patterns](https://github.com/openai/openai-agents-python/tree/main/examples/agent_patterns):**
    이 카테고리의 예제는 다음과 같은 일반적인 에이전트 설계 패턴을 보여줍니다

    -   결정적 워크플로
    -   Agents as tools
    -   병렬 에이전트 실행
    -   조건부 도구 사용
    -   입력/출력 가드레일
    -   판정자로서의 LLM
    -   라우팅
    -   스트리밍 가드레일

-   **[basic](https://github.com/openai/openai-agents-python/tree/main/examples/basic):**
    이 예제들은 다음과 같은 SDK의 기초 기능을 보여줍니다

    -   Hello World 예제(기본 모델, GPT-5, open-weight 모델)
    -   에이전트 라이프사이클 관리
    -   동적 시스템 프롬프트
    -   스트리밍 출력(텍스트, 항목, 함수 호출 인자)
    -   turns 전반에 걸쳐 공유 세션 헬퍼를 사용하는 Responses websocket 전송(`examples/basic/stream_ws.py`)
    -   프롬프트 템플릿
    -   파일 처리(로컬 및 원격, 이미지 및 PDF)
    -   사용량 추적
    -   엄격하지 않은 출력 타입
    -   이전 response ID 사용

-   **[customer_service](https://github.com/openai/openai-agents-python/tree/main/examples/customer_service):**
    항공사를 위한 고객 서비스 시스템 예제입니다.

-   **[financial_research_agent](https://github.com/openai/openai-agents-python/tree/main/examples/financial_research_agent):**
    금융 데이터 분석을 위한 에이전트와 도구로 구성된 structured 리서치 워크플로를 보여주는 금융 리서치 에이전트입니다.

-   **[handoffs](https://github.com/openai/openai-agents-python/tree/main/examples/handoffs):**
    메시지 필터링을 사용한 에이전트 핸드오프의 실용적인 예제를 확인하세요.

-   **[hosted_mcp](https://github.com/openai/openai-agents-python/tree/main/examples/hosted_mcp):**
    hosted MCP(Model context protocol) 커넥터와 승인(approval)을 사용하는 방법을 보여주는 예제입니다.

-   **[mcp](https://github.com/openai/openai-agents-python/tree/main/examples/mcp):**
    다음을 포함하여 MCP(Model context protocol)로 에이전트를 만드는 방법을 알아보세요

    -   파일시스템 예제
    -   Git 예제
    -   MCP 프롬프트 서버 예제
    -   SSE(Server-Sent Events) 예제
    -   스트리밍 가능한 HTTP 예제

-   **[memory](https://github.com/openai/openai-agents-python/tree/main/examples/memory):**
    다음을 포함해 에이전트의 다양한 메모리 구현 예제입니다

    -   SQLite 세션 스토리지
    -   고급 SQLite 세션 스토리지
    -   Redis 세션 스토리지
    -   SQLAlchemy 세션 스토리지
    -   암호화된 세션 스토리지
    -   OpenAI 세션 스토리지

-   **[model_providers](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers):**
    커스텀 프로바이더와 LiteLLM 통합을 포함해, SDK에서 OpenAI가 아닌 모델을 사용하는 방법을 살펴보세요.

-   **[realtime](https://github.com/openai/openai-agents-python/tree/main/examples/realtime):**
    다음을 포함해 SDK로 실시간 경험을 만드는 방법을 보여주는 예제입니다

    -   웹 애플리케이션
    -   커맨드라인 인터페이스
    -   Twilio 통합
    -   Twilio SIP 통합

-   **[reasoning_content](https://github.com/openai/openai-agents-python/tree/main/examples/reasoning_content):**
    reasoning content와 structured outputs를 다루는 방법을 보여주는 예제입니다.

-   **[research_bot](https://github.com/openai/openai-agents-python/tree/main/examples/research_bot):**
    복잡한 멀티 에이전트 리서치 워크플로를 보여주는 간단한 딥 리서치 클론입니다.

-   **[tools](https://github.com/openai/openai-agents-python/tree/main/examples/tools):**
    다음과 같은 OpenAI 호스트하는 도구와 실험적 Codex 도구를 구현하는 방법을 알아보세요

    -   웹 검색 및 필터가 있는 웹 검색
    -   파일 검색
    -   Code Interpreter
    -   인라인 스킬을 사용하는 호스티드 컨테이너 셸(`examples/tools/container_shell_inline_skill.py`)
    -   스킬 레퍼런스를 사용하는 호스티드 컨테이너 셸(`examples/tools/container_shell_skill_reference.py`)
    -   컴퓨터 사용
    -   이미지 생성
    -   실험적 Codex 도구 워크플로(`examples/tools/codex.py`)
    -   실험적 Codex same-thread 워크플로(`examples/tools/codex_same_thread.py`)

-   **[voice](https://github.com/openai/openai-agents-python/tree/main/examples/voice):**
    스트리밍 음성 예제를 포함해, TTS 및 STT 모델을 사용하는 음성 에이전트 예제를 확인하세요.

================
File: docs/ko/guardrails.md
================
---
search:
  exclude: true
---
# 가드레일

가드레일을 사용하면 사용자 입력과 에이전트 출력에 대한 검사 및 검증을 수행할 수 있습니다. 예를 들어, 고객 요청을 돕기 위해 매우 똑똑한(따라서 느리고/비용이 큰) 모델을 사용하는 에이전트가 있다고 가정해 보겠습니다. 악의적인 사용자가 모델에게 수학 숙제를 도와달라고 요청하는 상황은 원치 않을 것입니다. 그래서 빠르고/저렴한 모델로 가드레일을 실행할 수 있습니다. 가드레일이 악의적 사용을 감지하면 즉시 오류를 발생시켜 고비용 모델 실행을 막을 수 있어 시간과 비용을 절약할 수 있습니다(**blocking 가드레일을 사용할 때 해당하며, parallel 가드레일의 경우 가드레일이 완료되기 전에 고비용 모델 실행이 이미 시작되었을 수 있습니다. 자세한 내용은 아래의 "실행 모드"를 참고하세요**)

가드레일에는 두 가지 종류가 있습니다:

1. 입력 가드레일은 초기 사용자 입력에서 실행됩니다
2. 출력 가드레일은 최종 에이전트 출력에서 실행됩니다

## 입력 가드레일

입력 가드레일은 3단계로 실행됩니다:

1. 먼저, 가드레일은 에이전트에 전달된 것과 동일한 입력을 받습니다
2. 다음으로, 가드레일 함수가 실행되어 [`GuardrailFunctionOutput`][agents.guardrail.GuardrailFunctionOutput]을 생성하고, 이것이 [`InputGuardrailResult`][agents.guardrail.InputGuardrailResult]로 래핑됩니다
3. 마지막으로, [`.tripwire_triggered`][agents.guardrail.GuardrailFunctionOutput.tripwire_triggered]가 true인지 확인합니다. true이면 [`InputGuardrailTripwireTriggered`][agents.exceptions.InputGuardrailTripwireTriggered] 예외가 발생하므로, 사용자에게 적절히 응답하거나 예외를 처리할 수 있습니다

!!! Note

    입력 가드레일은 사용자 입력에서 실행되도록 설계되었으므로, 에이전트의 가드레일은 해당 에이전트가 *첫 번째* 에이전트일 때만 실행됩니다. `guardrails` 속성이 `Runner.run`에 전달되는 대신 에이전트에 있는 이유가 궁금할 수 있습니다. 이는 가드레일이 실제 Agent와 관련되는 경우가 많기 때문입니다. 에이전트마다 서로 다른 가드레일을 실행하게 되므로, 코드를 같은 위치에 두는 것이 가독성에 유리합니다.

### 실행 모드

입력 가드레일은 두 가지 실행 모드를 지원합니다:

- **병렬 실행** (기본값, `run_in_parallel=True`): 가드레일이 에이전트 실행과 동시에 실행됩니다. 둘 다 같은 시점에 시작되므로 지연 시간이 가장 좋습니다. 하지만 가드레일이 실패하면, 에이전트가 취소되기 전에 이미 토큰을 소비하고 도구를 실행했을 수 있습니다.

- **차단 실행** (`run_in_parallel=False`): 가드레일이 에이전트 시작 *전에* 실행 및 완료됩니다. 가드레일 tripwire가 트리거되면 에이전트는 실행되지 않으므로 토큰 소비와 도구 실행을 방지할 수 있습니다. 비용 최적화와 도구 호출로 인한 잠재적 부작용을 피하고 싶을 때 이상적입니다.

## 출력 가드레일

출력 가드레일은 3단계로 실행됩니다:

1. 먼저, 가드레일은 에이전트가 생성한 출력을 받습니다
2. 다음으로, 가드레일 함수가 실행되어 [`GuardrailFunctionOutput`][agents.guardrail.GuardrailFunctionOutput]을 생성하고, 이것이 [`OutputGuardrailResult`][agents.guardrail.OutputGuardrailResult]로 래핑됩니다
3. 마지막으로, [`.tripwire_triggered`][agents.guardrail.GuardrailFunctionOutput.tripwire_triggered]가 true인지 확인합니다. true이면 [`OutputGuardrailTripwireTriggered`][agents.exceptions.OutputGuardrailTripwireTriggered] 예외가 발생하므로, 사용자에게 적절히 응답하거나 예외를 처리할 수 있습니다

!!! Note

    출력 가드레일은 최종 에이전트 출력에서 실행되도록 설계되었으므로, 에이전트의 가드레일은 해당 에이전트가 *마지막* 에이전트일 때만 실행됩니다. 입력 가드레일과 마찬가지로, 이는 가드레일이 실제 Agent와 관련되는 경우가 많기 때문입니다. 에이전트마다 서로 다른 가드레일을 실행하게 되므로, 코드를 같은 위치에 두는 것이 가독성에 유리합니다.

    출력 가드레일은 항상 에이전트 완료 후 실행되므로 `run_in_parallel` 매개변수를 지원하지 않습니다.

## 도구 가드레일

도구 가드레일은 **함수 도구**를 감싸며, 실행 전후에 도구 호출을 검증하거나 차단할 수 있게 해줍니다. 도구 자체에 구성되며, 해당 도구가 호출될 때마다 실행됩니다.

- 입력 도구 가드레일은 도구 실행 전에 실행되며 호출을 건너뛰거나, 출력을 메시지로 대체하거나, tripwire를 발생시킬 수 있습니다.
- 출력 도구 가드레일은 도구 실행 후에 실행되며 출력을 대체하거나 tripwire를 발생시킬 수 있습니다.
- 도구 가드레일은 [`function_tool`][agents.function_tool]로 생성된 함수 도구에만 적용됩니다. 호스티드 툴(`WebSearchTool`, `FileSearchTool`, `HostedMCPTool`, `CodeInterpreterTool`, `ImageGenerationTool`) 및 내장 실행 도구(`ComputerTool`, `ShellTool`, `ApplyPatchTool`, `LocalShellTool`)는 이 가드레일 파이프라인을 사용하지 않습니다.

자세한 내용은 아래 코드 스니펫을 참고하세요.

## 트립와이어

입력 또는 출력이 가드레일 검사를 통과하지 못하면 Guardrail은 tripwire로 이를 알릴 수 있습니다. tripwire가 트리거된 가드레일이 확인되는 즉시 `{Input,Output}GuardrailTripwireTriggered` 예외를 발생시키고 Agent 실행을 중단합니다.

## 가드레일 구현

입력을 받아 [`GuardrailFunctionOutput`][agents.guardrail.GuardrailFunctionOutput]을 반환하는 함수를 제공해야 합니다. 이 예제에서는 내부적으로 Agent를 실행하는 방식으로 이를 수행합니다.

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

1. 가드레일 함수에서 이 에이전트를 사용합니다.
2. 에이전트의 입력/컨텍스트를 받아 결과를 반환하는 가드레일 함수입니다.
3. 가드레일 결과에 추가 정보를 포함할 수 있습니다.
4. 워크플로를 정의하는 실제 에이전트입니다.

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

1. 실제 에이전트의 출력 타입입니다.
2. 가드레일의 출력 타입입니다.
3. 에이전트의 출력을 받아 결과를 반환하는 가드레일 함수입니다.
4. 워크플로를 정의하는 실제 에이전트입니다.

마지막으로, 아래는 도구 가드레일 예제입니다.

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

핸드오프를 사용하면 한 에이전트가 다른 에이전트에 작업을 위임할 수 있습니다. 이는 서로 다른 에이전트가 각기 다른 영역을 전문으로 다루는 시나리오에서 특히 유용합니다. 예를 들어 고객 지원 앱에서는 주문 상태, 환불, FAQ 등의 작업을 각각 전담하는 에이전트가 있을 수 있습니다

핸드오프는 LLM에 도구로 표현됩니다. 따라서 `Refund Agent`라는 이름의 에이전트로 핸드오프가 있다면, 도구 이름은 `transfer_to_refund_agent`가 됩니다

## 핸드오프 생성

모든 에이전트에는 [`handoffs`][agents.agent.Agent.handoffs] 매개변수가 있으며, 여기에 `Agent`를 직접 전달하거나 핸드오프를 커스터마이즈하는 `Handoff` 객체를 전달할 수 있습니다

일반 `Agent` 인스턴스를 전달하면, 해당 에이전트의 [`handoff_description`][agents.agent.Agent.handoff_description] (설정된 경우)이 기본 도구 설명에 추가됩니다. 전체 `handoff()` 객체를 작성하지 않고도 모델이 해당 핸드오프를 선택해야 하는 시점을 힌트로 제공할 때 사용하세요

Agents SDK에서 제공하는 [`handoff()`][agents.handoffs.handoff] 함수를 사용해 핸드오프를 만들 수 있습니다. 이 함수로 핸드오프 대상 에이전트와 선택적 오버라이드, 입력 필터를 지정할 수 있습니다

### 기본 사용법

다음은 간단한 핸드오프를 만드는 방법입니다

```python
from agents import Agent, handoff

billing_agent = Agent(name="Billing agent")
refund_agent = Agent(name="Refund agent")

# (1)!
triage_agent = Agent(name="Triage agent", handoffs=[billing_agent, handoff(refund_agent)])
```

1. 에이전트를 직접 사용할 수 있고(`billing_agent`처럼), 또는 `handoff()` 함수를 사용할 수 있습니다

### `handoff()` 함수를 통한 핸드오프 커스터마이즈

[`handoff()`][agents.handoffs.handoff] 함수로 여러 항목을 커스터마이즈할 수 있습니다

-   `agent`: 핸드오프할 대상 에이전트입니다
-   `tool_name_override`: 기본적으로 `Handoff.default_tool_name()` 함수가 사용되며, 이는 `transfer_to_<agent_name>`으로 해석됩니다. 이를 오버라이드할 수 있습니다
-   `tool_description_override`: `Handoff.default_tool_description()`의 기본 도구 설명을 오버라이드합니다
-   `on_handoff`: 핸드오프가 호출될 때 실행되는 콜백 함수입니다. 핸드오프 호출이 확정되는 즉시 데이터 가져오기를 시작하는 등의 용도에 유용합니다. 이 함수는 에이전트 컨텍스트를 받고, 선택적으로 LLM이 생성한 입력도 받을 수 있습니다. 입력 데이터는 `input_type` 매개변수로 제어됩니다
-   `input_type`: 핸드오프가 기대하는 입력 타입(선택 사항)입니다
-   `input_filter`: 다음 에이전트가 받는 입력을 필터링할 수 있습니다. 자세한 내용은 아래를 참고하세요
-   `is_enabled`: 핸드오프 활성화 여부입니다. 불리언 또는 불리언을 반환하는 함수를 사용할 수 있어 런타임에 동적으로 활성화/비활성화할 수 있습니다
-   `nest_handoff_history`: RunConfig 수준 `nest_handoff_history` 설정에 대한 호출별 선택적 오버라이드입니다. `None`이면 대신 현재 활성 실행 구성에 정의된 값을 사용합니다

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

특정 상황에서는 LLM이 핸드오프를 호출할 때 일부 데이터를 제공하도록 하고 싶을 수 있습니다. 예를 들어 "Escalation agent"로 핸드오프한다고 가정해 보겠습니다. 로깅할 수 있도록 사유를 제공받고 싶을 수 있습니다

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

## 입력 필터

핸드오프가 발생하면 새 에이전트가 대화를 인계받아 이전 대화 기록 전체를 보게 되는 것과 같습니다. 이를 변경하려면 [`input_filter`][agents.handoffs.Handoff.input_filter]를 설정할 수 있습니다. 입력 필터는 [`HandoffInputData`][agents.handoffs.HandoffInputData]를 통해 기존 입력을 받아 새로운 `HandoffInputData`를 반환해야 하는 함수입니다

중첩 핸드오프는 옵트인 베타로 제공되며, 안정화 작업 중이므로 기본적으로 비활성화되어 있습니다. [`RunConfig.nest_handoff_history`][agents.run.RunConfig.nest_handoff_history]를 활성화하면, 러너는 이전 대화록을 단일 어시스턴트 요약 메시지로 축약하고 `<CONVERSATION HISTORY>` 블록으로 감쌉니다. 같은 실행 중 여러 핸드오프가 발생하면 이 블록에 새 턴이 계속 추가됩니다. 전체 `input_filter`를 작성하지 않고 생성된 메시지를 대체하려면 [`RunConfig.handoff_history_mapper`][agents.run.RunConfig.handoff_history_mapper]를 통해 자체 매핑 함수를 제공할 수 있습니다. 이 옵트인은 핸드오프와 실행 모두에서 명시적 `input_filter`를 제공하지 않은 경우에만 적용되므로, 이미 페이로드를 커스터마이즈하는 기존 코드(이 저장소의 예제 포함)는 변경 없이 현재 동작을 유지합니다. [`handoff(...)`][agents.handoffs.handoff]에 `nest_handoff_history=True` 또는 `False`를 전달해 단일 핸드오프의 중첩 동작을 오버라이드할 수 있으며, 이는 [`Handoff.nest_handoff_history`][agents.handoffs.Handoff.nest_handoff_history]를 설정합니다. 생성된 요약의 래퍼 텍스트만 변경하려면 에이전트를 실행하기 전에 [`set_conversation_history_wrappers`][agents.handoffs.set_conversation_history_wrappers](및 선택적으로 [`reset_conversation_history_wrappers`][agents.handoffs.reset_conversation_history_wrappers])를 호출하세요

몇 가지 일반적인 패턴(예: 기록에서 모든 도구 호출 제거)은 [`agents.extensions.handoff_filters`][]에 구현되어 있습니다

```python
from agents import Agent, handoff
from agents.extensions import handoff_filters

agent = Agent(name="FAQ agent")

handoff_obj = handoff(
    agent=agent,
    input_filter=handoff_filters.remove_all_tools, # (1)!
)
```

1. 이렇게 하면 `FAQ agent`가 호출될 때 기록에서 모든 도구가 자동으로 제거됩니다

## 권장 프롬프트

LLM이 핸드오프를 올바르게 이해하도록 하려면, 에이전트에 핸드오프 관련 정보를 포함하는 것을 권장합니다. [`agents.extensions.handoff_prompt.RECOMMENDED_PROMPT_PREFIX`][]에 권장 접두사가 있으며, [`agents.extensions.handoff_prompt.prompt_with_handoff_instructions`][]를 호출해 프롬프트에 권장 데이터를 자동으로 추가할 수도 있습니다

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

휴먼인더루프 (HITL) 흐름을 사용하면 사람이 민감한 도구 호출을 승인하거나 거절할 때까지 에이전트 실행을 일시 중지할 수 있습니다. 도구는 승인 필요 여부를 선언하고, 실행 결과는 대기 중인 승인을 인터럽션으로 표시하며, `RunState`를 통해 결정 이후 실행을 직렬화하고 재개할 수 있습니다.

## 승인이 필요한 도구 표시

항상 승인이 필요하도록 `needs_approval`을 `True`로 설정하거나, 호출별로 결정하는 비동기 함수를 제공할 수 있습니다. 이 callable은 실행 컨텍스트, 파싱된 도구 매개변수, 도구 호출 ID를 받습니다.

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

`needs_approval`은 [`function_tool`][agents.tool.function_tool], [`Agent.as_tool`][agents.agent.Agent.as_tool], [`ShellTool`][agents.tool.ShellTool], [`ApplyPatchTool`][agents.tool.ApplyPatchTool]에서 사용할 수 있습니다. 로컬 MCP 서버도 [`MCPServerStdio`][agents.mcp.server.MCPServerStdio], [`MCPServerSse`][agents.mcp.server.MCPServerSse], [`MCPServerStreamableHttp`][agents.mcp.server.MCPServerStreamableHttp]의 `require_approval`을 통해 승인을 지원합니다. 호스티드 MCP 서버는 [`HostedMCPTool`][agents.tool.HostedMCPTool]에서 `tool_config={"require_approval": "always"}`로 승인 기능을 지원하며, 선택적으로 `on_approval_request` 콜백을 사용할 수 있습니다. Shell 및 apply_patch 도구는 인터럽션을 노출하지 않고 자동 승인 또는 자동 거절하려는 경우 `on_approval` 콜백을 받을 수 있습니다.

## 승인 흐름 작동 방식

1. 모델이 도구 호출을 생성하면 runner가 `needs_approval`을 평가합니다
2. 해당 도구 호출에 대한 승인 결정이 이미 [`RunContextWrapper`][agents.run_context.RunContextWrapper]에 저장되어 있으면(예: `always_approve=True`), runner는 추가 확인 없이 진행합니다. 호출별 승인은 특정 호출 ID 범위로 제한됩니다. 이후 호출도 자동 허용하려면 `always_approve=True`를 사용하세요
3. 그렇지 않으면 실행이 일시 중지되고 `RunResult.interruptions`(또는 `RunResultStreaming.interruptions`)에 `agent.name`, `name`, `arguments` 같은 상세 정보를 포함한 `ToolApprovalItem` 항목이 들어갑니다
4. `result.to_state()`로 결과를 `RunState`로 변환하고, `state.approve(...)` 또는 `state.reject(...)`를 호출한 뒤(`always_approve` 또는 `always_reject`를 선택적으로 전달), `Runner.run(agent, state)` 또는 `Runner.run_streamed(agent, state)`로 재개합니다
5. 재개된 실행은 중단된 지점부터 계속되며, 새 승인이 필요하면 이 흐름으로 다시 진입합니다

## 예시: 일시 중지, 승인, 재개

아래 스니펫은 JavaScript HITL 가이드와 동일한 흐름입니다. 도구에 승인이 필요할 때 일시 중지하고, 상태를 디스크에 저장한 뒤, 다시 불러와 결정을 수집한 후 재개합니다.

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

이 예시에서 `prompt_approval`은 `input()`을 사용하고 `run_in_executor(...)`로 실행되므로 동기 함수입니다. 승인 소스가 이미 비동기라면(예: HTTP 요청 또는 비동기 데이터베이스 쿼리) `async def` 함수를 사용해 직접 `await`할 수 있습니다.

승인 대기 중에도 출력을 스트리밍하려면 `Runner.run_streamed`를 호출하고, 완료될 때까지 `result.stream_events()`를 소비한 뒤, 위에 나온 동일한 `result.to_state()` 및 재개 단계를 따르세요.

## 리포지토리 패턴 및 코드 예제

- **스트리밍 승인**: `examples/agent_patterns/human_in_the_loop_stream.py`는 `stream_events()`를 소진한 뒤 대기 중인 도구 호출을 승인하고 `Runner.run_streamed(agent, state)`로 재개하는 방법을 보여줍니다
- **에이전트를 도구로 사용하는 승인**: `Agent.as_tool(..., needs_approval=...)`는 위임된 에이전트 작업에 검토가 필요할 때 동일한 인터럽션 흐름을 적용합니다
- **Shell 및 apply_patch 도구**: `ShellTool`과 `ApplyPatchTool`도 `needs_approval`을 지원합니다. 이후 호출에 대한 결정을 캐시하려면 `state.approve(interruption, always_approve=True)` 또는 `state.reject(..., always_reject=True)`를 사용하세요. 자동 결정을 위해서는 `on_approval`을 제공하고(`examples/tools/shell.py` 참고), 수동 결정을 위해서는 인터럽션을 처리하세요(`examples/tools/shell_human_in_the_loop.py` 참고)
- **로컬 MCP 서버**: `MCPServerStdio` / `MCPServerSse` / `MCPServerStreamableHttp`의 `require_approval`을 사용해 MCP 도구 호출을 게이트할 수 있습니다(`examples/mcp/get_all_mcp_tools_example/main.py` 및 `examples/mcp/tool_filter_example/main.py` 참고)
- **호스티드 MCP 서버**: HITL을 강제하려면 `HostedMCPTool`에서 `require_approval`을 `"always"`로 설정하세요. 선택적으로 `on_approval_request`를 제공해 자동 승인 또는 거절할 수 있습니다(`examples/hosted_mcp/human_in_the_loop.py` 및 `examples/hosted_mcp/on_approval.py` 참고). 신뢰하는 서버에는 `"never"`를 사용하세요(`examples/hosted_mcp/simple.py`)
- **세션 및 메모리**: 여러 턴에 걸쳐 승인과 대화 기록을 유지하려면 `Runner.run`에 세션을 전달하세요. SQLite 및 OpenAI Conversations 세션 변형은 `examples/memory/memory_session_hitl_example.py`와 `examples/memory/openai_session_hitl_example.py`에 있습니다
- **실시간 에이전트**: 실시간 데모는 `RealtimeSession`의 `approve_tool_call` / `reject_tool_call`을 통해 도구 호출을 승인 또는 거절하는 WebSocket 메시지를 노출합니다(서버 측 핸들러는 `examples/realtime/app/server.py` 참고)

## 장기 실행 승인

`RunState`는 내구성을 고려해 설계되었습니다. `state.to_json()` 또는 `state.to_string()`을 사용해 대기 중인 작업을 데이터베이스나 큐에 저장하고, 이후 `RunState.from_json(...)` 또는 `RunState.from_string(...)`으로 다시 생성할 수 있습니다.

유용한 직렬화 옵션:

-   `context_serializer`: 매핑이 아닌 컨텍스트 객체를 직렬화하는 방식을 사용자 지정합니다
-   `strict_context=True`: 컨텍스트가 이미 매핑이거나 적절한 serializer/deserializer를 제공하지 않으면 직렬화 또는 역직렬화를 실패시킵니다
-   `context_override`: 상태를 로드할 때 직렬화된 컨텍스트를 교체합니다. 원래 컨텍스트 객체를 복원하고 싶지 않을 때 유용하지만, 이미 직렬화된 페이로드에서 해당 컨텍스트를 제거하지는 않습니다
-   `include_tracing_api_key=True`: 재개된 작업이 동일한 자격 증명으로 트레이스를 계속 내보내야 할 때 직렬화된 트레이스 페이로드에 트레이싱 API 키를 포함합니다

`RunState`는 트레이스 메타데이터와 서버 관리 대화 설정도 보존하므로, 재개된 실행이 동일한 트레이스와 동일한 `conversation_id` / `previous_response_id` 체인을 이어갈 수 있습니다.

## 대기 중 작업 버전 관리

승인이 한동안 대기할 수 있다면, 직렬화된 상태와 함께 에이전트 정의 또는 SDK 버전 마커를 저장하세요. 그러면 모델, 프롬프트, 도구 정의가 변경될 때 비호환성을 피하기 위해 역직렬화를 일치하는 코드 경로로 라우팅할 수 있습니다.

================
File: docs/ko/index.md
================
---
search:
  exclude: true
---
# OpenAI Agents SDK

[OpenAI Agents SDK](https://github.com/openai/openai-agents-python)는 매우 적은 추상화로 구성된 가볍고 사용하기 쉬운 패키지에서 에이전트형 AI 앱을 구축할 수 있게 해줍니다. 이는 이전 에이전트 실험인 [Swarm](https://github.com/openai/swarm/tree/main)의 프로덕션 준비 버전 업그레이드입니다. Agents SDK는 매우 작은 기본 구성 요소 집합을 제공합니다

-   **에이전트**: instructions와 tools가 탑재된 LLM
-   **Agents as tools / 핸드오프**: 에이전트가 특정 작업을 위해 다른 에이전트에 위임할 수 있게 해주는 기능
-   **가드레일**: 에이전트 입력과 출력의 검증을 가능하게 하는 기능

이 기본 구성 요소들은 Python과 결합될 때 도구와 에이전트 간의 복잡한 관계를 표현할 만큼 강력하며, 가파른 학습 곡선 없이 실제 애플리케이션을 구축할 수 있게 해줍니다. 또한 SDK에는 에이전트형 흐름을 시각화하고 디버깅하며, 평가하고, 애플리케이션에 맞춰 모델을 파인튜닝할 수 있게 해주는 내장 **트레이싱**이 포함되어 있습니다.

## Agents SDK 사용 이유

SDK에는 두 가지 핵심 설계 원칙이 있습니다

1. 사용할 가치가 있을 만큼 충분한 기능을 제공하되, 빠르게 익힐 수 있도록 기본 구성 요소는 적게 유지합니다
2. 기본 설정만으로도 잘 동작하지만, 정확히 어떤 일이 일어날지 직접 맞춤 설정할 수 있습니다

다음은 SDK의 주요 기능입니다

-   **에이전트 루프**: 도구 호출을 처리하고, 결과를 LLM에 다시 전달하며, 작업이 완료될 때까지 계속하는 내장 에이전트 루프
-   **파이썬 우선**: 새로운 추상화를 배울 필요 없이 내장 언어 기능으로 에이전트를 오케스트레이션하고 체이닝
-   **Agents as tools / 핸드오프**: 여러 에이전트 간 작업을 조율하고 위임하는 강력한 메커니즘
-   **가드레일**: 에이전트 실행과 병렬로 입력 검증 및 안전성 점검을 실행하고, 검사를 통과하지 못하면 즉시 실패 처리
-   **함수 도구**: 자동 스키마 생성과 Pydantic 기반 검증으로 모든 Python 함수를 도구로 변환
-   **MCP 서버 도구 호출**: 함수 도구와 동일한 방식으로 동작하는 내장 MCP 서버 도구 통합
-   **세션**: 에이전트 루프 내 작업 컨텍스트 유지를 위한 영속 메모리 계층
-   **휴먼인더루프 (HITL)**: 에이전트 실행 전반에 사람을 참여시키기 위한 내장 메커니즘
-   **트레이싱**: 워크플로우 시각화, 디버깅, 모니터링을 위한 내장 트레이싱과 OpenAI 평가, 파인튜닝, 증류 도구 모음 지원
-   **실시간 에이전트**: 자동 인터럽션(중단 처리) 감지, 컨텍스트 관리, 가드레일 등 기능을 갖춘 강력한 음성 에이전트 구축

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

-   [Quickstart](quickstart.md)로 첫 텍스트 기반 에이전트를 구축하세요
-   그런 다음 [Running agents](running_agents.md#choose-a-memory-strategy)에서 턴 간 상태를 어떻게 유지할지 결정하세요
-   handoffs와 매니저 스타일 오케스트레이션 사이에서 고민 중이라면 [Agent orchestration](multi_agent.md)을 읽어보세요

## 경로 선택

수행할 작업은 알고 있지만 어떤 페이지에 설명되어 있는지 모를 때 이 표를 사용하세요

| 목표 | 시작 지점 |
| --- | --- |
| 첫 텍스트 에이전트를 만들고 하나의 전체 실행을 확인 | [Quickstart](quickstart.md) |
| 함수 도구, 호스티드 툴, 또는 Agents as tools 추가 | [Tools](tools.md) |
| handoffs와 매니저 스타일 오케스트레이션 중 선택 | [Agent orchestration](multi_agent.md) |
| 턴 간 메모리 유지 | [Running agents](running_agents.md#choose-a-memory-strategy) 및 [Sessions](sessions/index.md) |
| OpenAI 모델, websocket 전송, 또는 비 OpenAI 제공자 사용 | [Models](models/index.md) |
| 출력, 실행 항목, 인터럽션(중단 처리), 재개 상태 검토 | [Results](results.md) |
| 저지연 음성 에이전트 구축 | [Realtime agents quickstart](realtime/quickstart.md) |
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

`Runner.run` 메서드를 호출하면 다음 중 하나를 받습니다

-   `run` 또는 `run_sync`를 호출하면 [`RunResult`][agents.result.RunResult]
-   `run_streamed`를 호출하면 [`RunResultStreaming`][agents.result.RunResultStreaming]

이 둘은 모두 [`RunResultBase`][agents.result.RunResultBase]를 상속하며, 대부분의 유용한 정보는 여기에 있습니다

## 어떤 결과 속성을 사용해야 하나요?

대부분의 애플리케이션은 몇 가지 결과 속성이나 헬퍼만 필요합니다

| 속성 또는 헬퍼 | 다음이 필요할 때 사용 |
| --- | --- |
| `final_output` | 사용자에게 보여줄 최종 답변 |
| `to_input_list()` | 대화 기록을 직접 수동으로 유지할 때, 다음 턴을 위한 전체 입력 목록 |
| `new_items` | 로그, UI 또는 감사용으로 에이전트, 도구, 핸드오프 메타데이터가 포함된 풍부한 실행 항목 |
| `last_agent` | 일반적으로 다음 턴을 처리해야 하는 에이전트 |
| `last_response_id` | 다음 OpenAI Responses 턴에서 `previous_response_id`로 이어서 진행 |
| `agent_tool_invocation` | 이 결과가 `Agent.as_tool()`에서 온 경우 바깥쪽 도구 호출에 대한 메타데이터 |
| `interruptions` | 재개 전에 반드시 해결해야 하는 대기 중 도구 승인 |
| `to_state()` | 일시 중지/재개 또는 내구성 있는 작업 워크플로를 위한 직렬화 가능한 스냅샷 |

## 최종 출력

[`final_output`][agents.result.RunResultBase.final_output] 속성에는 마지막으로 실행된 에이전트의 최종 출력이 들어 있습니다. 이는 다음 중 하나입니다

-   마지막 에이전트에 `output_type`이 정의되지 않은 경우 `str`
-   에이전트에 출력 타입이 정의된 경우 `last_agent.output_type` 타입의 객체

!!! note

    `final_output`의 타입은 `Any`입니다. 핸드오프 때문에 이를 정적으로 타입 지정할 수 없습니다. 핸드오프가 발생하면 어떤 Agent든 마지막 에이전트가 될 수 있으므로, 가능한 출력 타입 집합을 정적으로 알 수 없습니다

## 다음 턴 입력

[`result.to_input_list()`][agents.result.RunResultBase.to_input_list]를 사용하면 결과를 입력 목록으로 변환할 수 있으며, 여기에는 사용자가 제공한 원래 입력과 에이전트 실행 중 생성된 항목이 이어 붙여집니다. 이를 통해 한 에이전트 실행의 출력을 다른 실행에 전달하거나, 루프에서 실행하면서 매번 새로운 사용자 입력을 덧붙이기 편리합니다

실무에서는

-   애플리케이션이 전체 대화 기록을 수동으로 유지한다면 `result.to_input_list()` 사용
-   SDK가 기록을 로드/저장하게 하려면 [`session=...`](sessions/index.md) 사용
-   `conversation_id` 또는 `previous_response_id`로 OpenAI 서버 관리 상태를 사용하는 경우, 보통 `result.to_input_list()`를 다시 보내는 대신 새 사용자 입력만 전달하고 저장된 ID를 재사용

## 마지막 에이전트

[`last_agent`][agents.result.RunResultBase.last_agent] 속성에는 마지막으로 실행된 에이전트가 들어 있습니다. 애플리케이션에 따라 이는 사용자의 다음 입력 처리에 자주 유용합니다. 예를 들어, 언어별 에이전트로 핸드오프하는 프런트라인 분류 에이전트가 있다면 마지막 에이전트를 저장해 두고, 사용자가 다음에 메시지를 보낼 때 재사용할 수 있습니다

스트리밍 모드에서는 실행이 진행됨에 따라 [`RunResultStreaming.current_agent`][agents.result.RunResultStreaming.current_agent]가 업데이트되므로, 핸드오프가 발생하는 순간을 관찰할 수 있습니다

## 새 항목

[`new_items`][agents.result.RunResultBase.new_items] 속성에는 실행 중 생성된 새 항목이 들어 있습니다. 항목은 [`RunItem`][agents.items.RunItem]이며, 실행 항목은 LLM이 생성한 원문 항목을 감쌉니다

-   [`MessageOutputItem`][agents.items.MessageOutputItem]: LLM의 메시지를 나타냅니다. 원문 항목은 생성된 메시지입니다
-   [`HandoffCallItem`][agents.items.HandoffCallItem]: LLM이 핸드오프 도구를 호출했음을 나타냅니다. 원문 항목은 LLM의 도구 호출 항목입니다
-   [`HandoffOutputItem`][agents.items.HandoffOutputItem]: 핸드오프가 발생했음을 나타냅니다. 원문 항목은 핸드오프 도구 호출에 대한 도구 응답입니다. 항목에서 소스/타깃 에이전트에도 접근할 수 있습니다
-   [`ToolCallItem`][agents.items.ToolCallItem]: LLM이 도구를 호출했음을 나타냅니다
-   [`ToolCallOutputItem`][agents.items.ToolCallOutputItem]: 도구가 호출되었음을 나타냅니다. 원문 항목은 도구 응답입니다. 항목에서 도구 출력에도 접근할 수 있습니다
-   [`ReasoningItem`][agents.items.ReasoningItem]: LLM의 추론 항목을 나타냅니다. 원문 항목은 생성된 추론입니다

## 실행 상태

실행의 직렬화 가능한 스냅샷이 필요할 때 [`result.to_state()`][agents.result.RunResult.to_state]를 호출하세요. 이는 완료되었거나 일시 중지된 실행과 이후 재개 사이를 연결하는 브리지이며, 특히 승인 흐름이나 내구성 있는 워커 시스템에서 유용합니다

## Agent-as-tool 메타데이터

결과가 중첩된 [`Agent.as_tool()`][agents.agent.Agent.as_tool] 실행에서 온 경우, [`agent_tool_invocation`][agents.result.RunResultBase.agent_tool_invocation]은 바깥쪽 도구 호출에 대한 불변 메타데이터를 제공합니다

-   `tool_name`
-   `tool_call_id`
-   `tool_arguments`

일반적인 최상위 실행에서는 `agent_tool_invocation`이 `None`입니다

## 기타 정보

### 가드레일 결과

[`input_guardrail_results`][agents.result.RunResultBase.input_guardrail_results] 및 [`output_guardrail_results`][agents.result.RunResultBase.output_guardrail_results] 속성에는 가드레일 결과(있는 경우)가 들어 있습니다. 가드레일 결과에는 로그 기록이나 저장에 유용한 정보가 포함될 수 있으므로 이를 사용할 수 있도록 제공합니다

도구 가드레일 결과는 [`tool_input_guardrail_results`][agents.result.RunResultBase.tool_input_guardrail_results] 및 [`tool_output_guardrail_results`][agents.result.RunResultBase.tool_output_guardrail_results]로 별도로 제공됩니다. 이러한 가드레일은 도구에 연결할 수 있으며, 해당 도구 호출은 에이전트 워크플로 중에 가드레일을 실행합니다

### 원문 응답

[`raw_responses`][agents.result.RunResultBase.raw_responses] 속성에는 LLM이 생성한 [`ModelResponse`][agents.items.ModelResponse]가 들어 있습니다

### 원래 입력

[`input`][agents.result.RunResultBase.input] 속성에는 `run` 메서드에 제공한 원래 입력이 들어 있습니다. 대부분의 경우 필요하지 않지만, 필요할 때를 위해 제공됩니다

### 인터럽션(중단 처리) 및 실행 재개

실행이 도구 승인 때문에 일시 중지되면, 대기 중 승인은
[`RunResult.interruptions`][agents.result.RunResult.interruptions] 또는
[`RunResultStreaming.interruptions`][agents.result.RunResultStreaming.interruptions]에 노출됩니다. 결과를
`to_state()`로 [`RunState`][agents.run_state.RunState]로 변환하고, 인터럽션(중단 처리)을 승인 또는 거부한 뒤
`Runner.run(...)` 또는 `Runner.run_streamed(...)`로 재개하세요

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

[`RunResult`][agents.result.RunResult]와
[`RunResultStreaming`][agents.result.RunResultStreaming]은 모두 `to_state()`를 지원합니다. 내구성 있는
승인 워크플로는 [휴먼인더루프 (HITL) 가이드](human_in_the_loop.md)를 참고하세요

### 편의 헬퍼

`RunResultBase`에는 프로덕션 흐름에서 유용한 몇 가지 헬퍼 메서드/속성이 포함되어 있습니다

- [`final_output_as(...)`][agents.result.RunResultBase.final_output_as]: 최종 출력을 특정 타입으로 캐스팅합니다(선택적으로 런타임 타입 검사 포함)
- [`last_response_id`][agents.result.RunResultBase.last_response_id]: 최신 모델 응답 ID를 반환합니다. 다음 턴에서 OpenAI Responses API 체인을 이어가려면 이를 `previous_response_id`로 다시 전달하세요
- [`agent_tool_invocation`][agents.result.RunResultBase.agent_tool_invocation]: 결과가 `Agent.as_tool()`에서 온 경우 바깥쪽 도구 호출 메타데이터를 반환합니다
- [`release_agents(...)`][agents.result.RunResultBase.release_agents]: 결과 확인 후 메모리 압박을 줄이기 위해 에이전트에 대한 강한 참조를 해제합니다

================
File: docs/ko/running_agents.md
================
---
search:
  exclude: true
---
# 에이전트 실행

[`Runner`][agents.run.Runner] 클래스를 통해 에이전트를 실행할 수 있습니다. 선택지는 3가지입니다:

1. [`Runner.run()`][agents.run.Runner.run]: 비동기로 실행되며 [`RunResult`][agents.result.RunResult]를 반환합니다
2. [`Runner.run_sync()`][agents.run.Runner.run_sync]: 동기 메서드이며 내부적으로 `.run()`을 실행합니다
3. [`Runner.run_streamed()`][agents.run.Runner.run_streamed]: 비동기로 실행되며 [`RunResultStreaming`][agents.result.RunResultStreaming]을 반환합니다. 스트리밍 모드로 LLM을 호출하고, 이벤트를 수신되는 즉시 스트리밍합니다

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

자세한 내용은 [결과 가이드](results.md)에서 확인하세요.

## Runner 수명 주기 및 구성

### 에이전트 루프

`Runner`에서 run 메서드를 사용할 때 시작 에이전트와 입력을 전달합니다. 입력은 다음 중 하나일 수 있습니다:

-   문자열(사용자 메시지로 처리)
-   OpenAI Responses API 형식의 입력 항목 리스트
-   중단된 실행을 재개할 때의 [`RunState`][agents.run_state.RunState]

Runner는 이후 다음 루프를 실행합니다:

1. 현재 입력으로 현재 에이전트에 대해 LLM을 호출합니다
2. LLM이 출력을 생성합니다
    1. LLM이 `final_output`을 반환하면 루프를 종료하고 결과를 반환합니다
    2. LLM이 핸드오프를 수행하면 현재 에이전트와 입력을 갱신하고 루프를 다시 실행합니다
    3. LLM이 도구 호출을 생성하면 해당 도구 호출을 실행하고 결과를 추가한 뒤 루프를 다시 실행합니다
3. 전달된 `max_turns`를 초과하면 [`MaxTurnsExceeded`][agents.exceptions.MaxTurnsExceeded] 예외를 발생시킵니다

!!! note

    LLM 출력이 "최종 출력"으로 간주되는 기준은 원하는 타입의 텍스트 출력을 생성하고 도구 호출이 없는 경우입니다

### 스트리밍

스트리밍을 사용하면 LLM 실행 중 스트리밍 이벤트를 추가로 받을 수 있습니다. 스트림이 완료되면 [`RunResultStreaming`][agents.result.RunResultStreaming]에 실행에 대한 전체 정보(새로 생성된 모든 출력 포함)가 담깁니다. 스트리밍 이벤트는 `.stream_events()`로 호출할 수 있습니다. 자세한 내용은 [스트리밍 가이드](streaming.md)를 참고하세요.

#### Responses WebSocket 전송(선택적 헬퍼)

OpenAI Responses websocket 전송을 활성화하면 일반 `Runner` API를 계속 사용할 수 있습니다. websocket 세션 헬퍼는 연결 재사용에 권장되지만 필수는 아닙니다.

이는 websocket 전송 기반 Responses API이며, [Realtime API](realtime/guide.md)가 아닙니다.

구체적인 모델 객체 또는 커스텀 프로바이더와 관련된 전송 선택 규칙 및 주의사항은 [Models](models/index.md#responses-websocket-transport)를 참고하세요.

##### 패턴 1: 세션 헬퍼 없음(동작함)

websocket 전송만 원하고 SDK가 공유 provider/session을 관리할 필요가 없을 때 사용하세요.

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

이 패턴은 단일 실행에 적합합니다. `Runner.run()` / `Runner.run_streamed()`를 반복 호출하면 동일한 `RunConfig` / provider 인스턴스를 수동 재사용하지 않는 한 실행마다 재연결될 수 있습니다.

##### 패턴 2: `responses_websocket_session()` 사용(멀티 턴 재사용에 권장)

여러 실행 간(동일한 `run_config`를 상속하는 중첩된 agent-as-tool 호출 포함) websocket 지원 provider와 `RunConfig`를 공유하려면 [`responses_websocket_session()`][agents.responses_websocket_session]을 사용하세요.

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

컨텍스트를 종료하기 전에 스트리밍된 결과 소비를 마치세요. websocket 요청이 아직 진행 중일 때 컨텍스트를 종료하면 공유 연결이 강제로 닫힐 수 있습니다.

### 실행 구성

`run_config` 매개변수로 에이전트 실행의 일부 전역 설정을 구성할 수 있습니다:

#### 공통 실행 구성 카테고리

각 에이전트 정의를 변경하지 않고 단일 실행의 동작을 재정의하려면 `RunConfig`를 사용하세요.

##### 모델, provider, 세션 기본값

-   [`model`][agents.run.RunConfig.model]: 각 Agent의 `model`과 관계없이 전역 LLM 모델을 설정할 수 있습니다
-   [`model_provider`][agents.run.RunConfig.model_provider]: 모델 이름 조회용 모델 provider이며 기본값은 OpenAI입니다
-   [`model_settings`][agents.run.RunConfig.model_settings]: 에이전트별 설정을 재정의합니다. 예: 전역 `temperature` 또는 `top_p` 설정
-   [`session_settings`][agents.run.RunConfig.session_settings]: 실행 중 히스토리를 조회할 때 세션 수준 기본값(예: `SessionSettings(limit=...)`)을 재정의합니다
-   [`session_input_callback`][agents.run.RunConfig.session_input_callback]: Sessions 사용 시 각 턴 전에 새 사용자 입력을 세션 히스토리와 병합하는 방식을 사용자 지정합니다. 콜백은 동기 또는 비동기일 수 있습니다

##### 가드레일, 핸드오프, 모델 입력 형상화

-   [`input_guardrails`][agents.run.RunConfig.input_guardrails], [`output_guardrails`][agents.run.RunConfig.output_guardrails]: 모든 실행에 포함할 입력/출력 가드레일 목록
-   [`handoff_input_filter`][agents.run.RunConfig.handoff_input_filter]: 핸드오프에 이미 필터가 없을 경우 모든 핸드오프에 적용할 전역 입력 필터입니다. 입력 필터를 통해 새 에이전트로 전송되는 입력을 편집할 수 있습니다. 자세한 내용은 [`Handoff.input_filter`][agents.handoffs.Handoff.input_filter] 문서를 참고하세요
-   [`nest_handoff_history`][agents.run.RunConfig.nest_handoff_history]: 다음 에이전트를 호출하기 전에 이전 transcript를 하나의 assistant 메시지로 축약하는 옵트인 베타 기능입니다. 중첩 핸드오프 안정화 중이므로 기본값은 비활성화입니다. 활성화하려면 `True`, 원문 transcript를 그대로 전달하려면 `False`로 두세요. [Runner 메서드][agents.run.Runner]는 `RunConfig`를 전달하지 않으면 자동으로 생성하므로, 퀵스타트와 예제는 기본적으로 비활성 상태를 유지하며 명시적 [`Handoff.input_filter`][agents.handoffs.Handoff.input_filter] 콜백은 계속 이를 우선 재정의합니다. 개별 핸드오프는 [`Handoff.nest_handoff_history`][agents.handoffs.Handoff.nest_handoff_history]로 이 설정을 재정의할 수 있습니다
-   [`handoff_history_mapper`][agents.run.RunConfig.handoff_history_mapper]: `nest_handoff_history`를 옵트인했을 때마다 정규화된 transcript(히스토리 + 핸드오프 항목)를 받는 선택적 callable입니다. 다음 에이전트로 전달할 정확한 입력 항목 리스트를 반환해야 하며, 이를 통해 전체 핸드오프 필터를 작성하지 않고도 내장 요약을 대체할 수 있습니다
-   [`call_model_input_filter`][agents.run.RunConfig.call_model_input_filter]: 모델 호출 직전에 완전히 준비된 모델 입력(instructions 및 입력 항목)을 편집하는 훅입니다. 예: 히스토리 축소, 시스템 프롬프트 주입
-   [`reasoning_item_id_policy`][agents.run.RunConfig.reasoning_item_id_policy]: Runner가 이전 출력을 다음 턴 모델 입력으로 변환할 때 reasoning item ID를 유지할지 생략할지 제어합니다

##### 트레이싱 및 관측성

-   [`tracing_disabled`][agents.run.RunConfig.tracing_disabled]: 전체 실행에 대해 [트레이싱](tracing.md)을 비활성화할 수 있습니다
-   [`tracing`][agents.run.RunConfig.tracing]: 이 실행의 exporter, processor 또는 트레이싱 메타데이터를 재정의하려면 [`TracingConfig`][agents.tracing.TracingConfig]를 전달하세요
-   [`trace_include_sensitive_data`][agents.run.RunConfig.trace_include_sensitive_data]: LLM 및 도구 호출 입력/출력과 같은 잠재적 민감 데이터를 트레이스에 포함할지 구성합니다
-   [`workflow_name`][agents.run.RunConfig.workflow_name], [`trace_id`][agents.run.RunConfig.trace_id], [`group_id`][agents.run.RunConfig.group_id]: 실행의 트레이싱 workflow name, trace ID, trace group ID를 설정합니다. 최소한 `workflow_name` 설정을 권장합니다. group ID는 여러 실행의 트레이스를 연결할 수 있는 선택 필드입니다
-   [`trace_metadata`][agents.run.RunConfig.trace_metadata]: 모든 트레이스에 포함할 메타데이터

##### 도구 승인 및 도구 오류 동작

-   [`tool_error_formatter`][agents.run.RunConfig.tool_error_formatter]: 승인 플로우 중 도구 호출이 거부될 때 모델에 보이는 메시지를 사용자 지정합니다

중첩 핸드오프는 옵트인 베타로 제공됩니다. 축약 transcript 동작을 사용하려면 `RunConfig(nest_handoff_history=True)`를 전달하거나, 특정 핸드오프에만 적용하려면 `handoff(..., nest_handoff_history=True)`를 설정하세요. 원문 transcript(기본값)를 유지하려면 플래그를 설정하지 않거나, 필요한 형태로 대화를 그대로 전달하는 `handoff_input_filter`(또는 `handoff_history_mapper`)를 제공하세요. 커스텀 mapper를 작성하지 않고 생성된 요약의 래퍼 텍스트를 변경하려면 [`set_conversation_history_wrappers`][agents.handoffs.set_conversation_history_wrappers]를 호출하세요(기본값 복원은 [`reset_conversation_history_wrappers`][agents.handoffs.reset_conversation_history_wrappers]).

#### 실행 구성 상세

##### `tool_error_formatter`

승인 플로우에서 도구 호출이 거부될 때 모델로 반환되는 메시지를 사용자 지정하려면 `tool_error_formatter`를 사용하세요.

formatter는 다음 정보를 포함한 [`ToolErrorFormatterArgs`][agents.run_config.ToolErrorFormatterArgs]를 받습니다:

-   `kind`: 오류 카테고리. 현재는 `"approval_rejected"`입니다
-   `tool_type`: 도구 런타임(`"function"`, `"computer"`, `"shell"`, `"apply_patch"`)
-   `tool_name`: 도구 이름
-   `call_id`: 도구 호출 ID
-   `default_message`: SDK 기본 모델 표시 메시지
-   `run_context`: 활성 실행 컨텍스트 래퍼

메시지를 대체할 문자열을 반환하거나, SDK 기본값을 사용하려면 `None`을 반환하세요.

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

`reasoning_item_id_policy`는 Runner가 히스토리를 다음 턴으로 이어갈 때(예: `RunResult.to_input_list()` 또는 세션 기반 실행 사용 시) reasoning 항목을 다음 턴 모델 입력으로 변환하는 방식을 제어합니다.

-   `None` 또는 `"preserve"`(기본값): reasoning item ID 유지
-   `"omit"`: 생성되는 다음 턴 입력에서 reasoning item ID 제거

`"omit"`은 주로 Responses API 400 오류 유형에 대한 옵트인 완화책으로 사용합니다. 예를 들어 reasoning item이 `id`와 함께 전송되었지만 필수 후속 항목이 없는 경우입니다(`Item 'rs_...' of type 'reasoning' was provided without its required following item.`).

이 문제는 SDK가 이전 출력으로 후속 입력을 구성하는 멀티 턴 에이전트 실행에서 발생할 수 있습니다(세션 영속성, 서버 관리 대화 델타, 스트리밍/비스트리밍 후속 턴, 재개 경로 포함). 이때 reasoning item ID는 유지되지만 provider가 해당 ID가 대응되는 후속 항목과 쌍으로 유지되기를 요구할 수 있습니다.

`reasoning_item_id_policy="omit"`를 설정하면 reasoning 내용은 유지하면서 reasoning item `id`만 제거하므로 SDK 생성 후속 입력에서 해당 API 불변 조건 위반을 피할 수 있습니다.

범위 참고:

-   이는 SDK가 후속 입력을 구성할 때 SDK가 생성/전달하는 reasoning 항목에만 적용됩니다
-   사용자가 제공한 초기 입력 항목은 재작성하지 않습니다
-   `call_model_input_filter`는 이 정책 적용 후에도 의도적으로 reasoning ID를 다시 도입할 수 있습니다

## 상태 및 대화 관리

### 메모리 전략 선택

다음 턴으로 상태를 전달하는 일반적인 방법은 네 가지입니다:

| 전략 | 상태 저장 위치 | 최적 사용 사례 | 다음 턴에 전달할 것 |
| --- | --- | --- | --- |
| `result.to_input_list()` | 앱 메모리 | 작은 채팅 루프, 완전 수동 제어, 모든 provider | `result.to_input_list()`의 리스트 + 다음 사용자 메시지 |
| `session` | 사용자 저장소 + SDK | 영구 채팅 상태, 재개 가능한 실행, 커스텀 스토어 | 동일한 `session` 인스턴스 또는 같은 스토어를 가리키는 다른 인스턴스 |
| `conversation_id` | OpenAI Conversations API | 워커나 서비스 간 공유할 서버 측 명명 대화 | 동일한 `conversation_id` + 새 사용자 턴만 |
| `previous_response_id` | OpenAI Responses API | 대화 리소스 생성 없이 경량 서버 관리 연속 실행 | `result.last_response_id` + 새 사용자 턴만 |

`result.to_input_list()`와 `session`은 클라이언트 관리 방식입니다. `conversation_id`와 `previous_response_id`는 OpenAI 관리 방식이며 OpenAI Responses API 사용 시에만 적용됩니다. 대부분의 애플리케이션에서는 대화당 하나의 영속화 전략을 선택하세요. 클라이언트 관리 히스토리와 OpenAI 관리 상태를 혼합하면 두 레이어를 의도적으로 조정하지 않는 한 컨텍스트가 중복될 수 있습니다.

!!! note

    세션 영속성은 서버 관리 대화 설정
    (`conversation_id`, `previous_response_id`, `auto_previous_response_id`)과
    동일 실행에서 함께 사용할 수 없습니다. 호출당 한 가지 접근 방식만 선택하세요

### 대화/채팅 스레드

어떤 run 메서드를 호출하더라도 하나 이상의 에이전트가 실행될 수 있고(따라서 하나 이상의 LLM 호출이 발생), 채팅 대화에서 하나의 논리적 턴을 나타냅니다. 예:

1. 사용자 턴: 사용자가 텍스트 입력
2. Runner 실행: 첫 번째 에이전트가 LLM 호출, 도구 실행, 두 번째 에이전트로 핸드오프, 두 번째 에이전트가 추가 도구 실행 후 출력 생성

에이전트 실행이 끝나면 사용자에게 무엇을 보여줄지 선택할 수 있습니다. 예를 들어 에이전트가 생성한 모든 새 항목을 보여주거나 최종 출력만 보여줄 수 있습니다. 어느 쪽이든 사용자가 후속 질문을 하면 run 메서드를 다시 호출할 수 있습니다.

#### 수동 대화 관리

다음 턴 입력을 얻기 위해 [`RunResultBase.to_input_list()`][agents.result.RunResultBase.to_input_list] 메서드로 대화 히스토리를 수동 관리할 수 있습니다:

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

더 간단한 접근으로 [Sessions](sessions/index.md)를 사용하면 `.to_input_list()`를 수동 호출하지 않고 대화 히스토리를 자동 처리할 수 있습니다:

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

Sessions는 자동으로 다음을 수행합니다:

-   각 실행 전에 대화 히스토리 조회
-   각 실행 후 새 메시지 저장
-   서로 다른 session ID별로 별도 대화 유지

자세한 내용은 [Sessions 문서](sessions/index.md)를 참고하세요.

#### 서버 관리 대화

`to_input_list()` 또는 `Sessions`로 로컬 처리하는 대신 OpenAI 대화 상태 기능에 서버 측 대화 상태 관리를 맡길 수도 있습니다. 이렇게 하면 과거 메시지를 모두 수동 재전송하지 않고 대화 히스토리를 유지할 수 있습니다. 아래 두 서버 관리 방식 모두에서 각 요청마다 새 턴 입력만 전달하고 저장된 ID를 재사용하세요. 자세한 내용은 [OpenAI Conversation state guide](https://platform.openai.com/docs/guides/conversation-state?api-mode=responses)를 참고하세요.

OpenAI는 턴 간 상태 추적 방법을 두 가지 제공합니다:

##### 1. `conversation_id` 사용

먼저 OpenAI Conversations API로 대화를 생성한 다음, 이후 모든 호출에서 해당 ID를 재사용합니다:

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

다른 방법은 **response chaining**으로, 각 턴이 이전 턴의 response ID에 명시적으로 연결됩니다.

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

실행이 승인 대기 상태로 멈추고 [`RunState`][agents.run_state.RunState]에서 재개하는 경우,
SDK는 저장된 `conversation_id` / `previous_response_id` / `auto_previous_response_id`
설정을 유지하므로 재개된 턴도 동일한 서버 관리 대화에서 계속됩니다.

`conversation_id`와 `previous_response_id`는 상호 배타적입니다. 시스템 간 공유 가능한 명명 대화 리소스를 원하면 `conversation_id`를 사용하세요. 턴 간 가장 경량의 Responses API 연속 실행 원시 기능을 원하면 `previous_response_id`를 사용하세요.

!!! note

    SDK는 `conversation_locked` 오류를 백오프로 자동 재시도합니다. 서버 관리 대화 실행에서는
    재시도 전에 내부 conversation-tracker 입력을 되감아 동일한 준비 항목을 깔끔하게
    재전송할 수 있도록 합니다

    로컬 세션 기반 실행(`conversation_id`, `previous_response_id`, `auto_previous_response_id`와
    함께 사용할 수 없음)에서도 SDK는 재시도 후 중복 히스토리 항목을 줄이기 위해 최근에
    저장된 입력 항목을 가능한 범위에서 롤백합니다

## 훅 및 사용자 지정

### 모델 호출 입력 필터

모델 호출 직전에 모델 입력을 편집하려면 `call_model_input_filter`를 사용하세요. 이 훅은 현재 에이전트, 컨텍스트, 결합된 입력 항목(존재 시 세션 히스토리 포함)을 받고 새로운 `ModelInputData`를 반환합니다.

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

민감 데이터 마스킹, 긴 히스토리 축소, 추가 시스템 가이드 주입을 위해 `run_config`를 통해 실행별로 이 훅을 설정하세요.

## 오류 및 복구

### 오류 핸들러

모든 `Runner` 진입점은 오류 종류를 키로 하는 딕셔너리 `error_handlers`를 받습니다. 현재 지원 키는 `"max_turns"`입니다. `MaxTurnsExceeded`를 발생시키는 대신 제어된 최종 출력을 반환하려면 이를 사용하세요.

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

대체 출력을 대화 히스토리에 추가하지 않으려면 `include_in_history=False`를 설정하세요.

## Durable 실행 통합 및 휴먼인더루프 (HITL)

도구 승인 pause/resume 패턴은 전용 [Human-in-the-loop 가이드](human_in_the_loop.md)부터 확인하세요.
아래 통합은 실행이 긴 대기, 재시도, 프로세스 재시작에 걸칠 수 있는 내구성 오케스트레이션용입니다.

### Temporal

Agents SDK [Temporal](https://temporal.io/) 통합을 사용해 휴먼인더루프 작업을 포함한 내구성 있는 장기 실행 워크플로를 실행할 수 있습니다. Temporal과 Agents SDK가 실제로 장기 실행 작업을 완료하는 데 동작하는 데모는 [이 비디오](https://www.youtube.com/watch?v=fFBZqzT4DD8)에서 확인하고, [문서는 여기](https://github.com/temporalio/sdk-python/tree/main/temporalio/contrib/openai_agents)에서 확인하세요.

### Restate

Agents SDK [Restate](https://restate.dev/) 통합을 사용해 휴먼 승인, 핸드오프, 세션 관리를 포함한 경량의 내구성 있는 에이전트를 사용할 수 있습니다. 이 통합은 Restate의 단일 바이너리 런타임을 의존성으로 필요로 하며, 프로세스/컨테이너 또는 서버리스 함수로 에이전트 실행을 지원합니다.
자세한 내용은 [개요](https://www.restate.dev/blog/durable-orchestration-for-ai-agents-with-restate-and-openai-sdk) 또는 [문서](https://docs.restate.dev/ai)를 참고하세요.

### DBOS

Agents SDK [DBOS](https://dbos.dev/) 통합을 사용해 장애 및 재시작 시에도 진행 상태를 보존하는 신뢰성 높은 에이전트를 실행할 수 있습니다. 장기 실행 에이전트, 휴먼인더루프 워크플로, 핸드오프를 지원합니다. 동기 및 비동기 메서드를 모두 지원합니다. 이 통합은 SQLite 또는 Postgres 데이터베이스만 필요합니다. 자세한 내용은 통합 [repo](https://github.com/dbos-inc/dbos-openai-agents)와 [문서](https://docs.dbos.dev/integrations/openai-agents)를 확인하세요.

## 예외

SDK는 특정 경우 예외를 발생시킵니다. 전체 목록은 [`agents.exceptions`][]에 있습니다. 개요는 다음과 같습니다:

-   [`AgentsException`][agents.exceptions.AgentsException]: SDK 내부에서 발생하는 모든 예외의 기본 클래스입니다. 다른 모든 구체적 예외가 파생되는 일반 타입입니다
-   [`MaxTurnsExceeded`][agents.exceptions.MaxTurnsExceeded]: 에이전트 실행이 `Runner.run`, `Runner.run_sync`, `Runner.run_streamed` 메서드에 전달된 `max_turns` 한도를 초과할 때 발생합니다. 지정된 상호작용 턴 수 내에 에이전트가 작업을 완료하지 못했음을 의미합니다
-   [`ModelBehaviorError`][agents.exceptions.ModelBehaviorError]: 기본 모델(LLM)이 예상치 못하거나 유효하지 않은 출력을 생성할 때 발생합니다. 예:
    -   잘못된 JSON 형식: 모델이 도구 호출 또는 직접 출력에서 잘못된 JSON 구조를 제공한 경우(특히 특정 `output_type`이 정의된 경우)
    -   예상치 못한 도구 관련 실패: 모델이 예상된 방식으로 도구를 사용하지 못한 경우
-   [`ToolTimeoutError`][agents.exceptions.ToolTimeoutError]: 함수 도구 호출이 설정된 타임아웃을 초과하고 도구가 `timeout_behavior="raise_exception"`을 사용하는 경우 발생합니다
-   [`UserError`][agents.exceptions.UserError]: SDK를 사용하는 코드 작성자(사용자)가 SDK 사용 중 오류를 낼 때 발생합니다. 일반적으로 잘못된 코드 구현, 유효하지 않은 구성, SDK API 오용에서 비롯됩니다
-   [`InputGuardrailTripwireTriggered`][agents.exceptions.InputGuardrailTripwireTriggered], [`OutputGuardrailTripwireTriggered`][agents.exceptions.OutputGuardrailTripwireTriggered]: 입력 가드레일 또는 출력 가드레일 조건이 각각 충족될 때 발생합니다. 입력 가드레일은 처리 전 수신 메시지를 검사하고, 출력 가드레일은 전달 전 에이전트의 최종 응답을 검사합니다

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

Agents SDK는 모든 실행에 대해 토큰 사용량을 자동으로 추적합니다. 실행 컨텍스트에서 접근하여 비용 모니터링, 한도 강제, 분석 기록에 사용할 수 있습니다.

## 추적 항목

- **requests**: 수행된 LLM API 호출 수
- **input_tokens**: 전송된 입력 토큰 합계
- **output_tokens**: 수신된 출력 토큰 합계
- **total_tokens**: 입력 + 출력
- **request_usage_entries**: 요청 단위 사용량 분해 목록
- **details**:
  - `input_tokens_details.cached_tokens`
  - `output_tokens_details.reasoning_tokens`

## 실행에서 사용량 접근

`Runner.run(...)` 이후 `result.context_wrapper.usage`를 통해 사용량에 접근합니다.

```python
result = await Runner.run(agent, "What's the weather in Tokyo?")
usage = result.context_wrapper.usage

print("Requests:", usage.requests)
print("Input tokens:", usage.input_tokens)
print("Output tokens:", usage.output_tokens)
print("Total tokens:", usage.total_tokens)
```

실행 중의 모든 모델 호출(도구 호출과 핸드오프 포함)에 걸쳐 사용량이 집계됩니다.

### LiteLLM 모델에서 사용량 활성화

LiteLLM 제공자는 기본적으로 사용량 지표를 보고하지 않습니다. [`LitellmModel`](models/litellm.md)을 사용할 때, 에이전트에 `ModelSettings(include_usage=True)`를 전달하면 LiteLLM 응답이 `result.context_wrapper.usage`에 채워집니다.

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

SDK는 `request_usage_entries`에 각 API 요청의 사용량을 자동으로 추적하며, 세부 비용 계산과 컨텍스트 윈도우 소비 모니터링에 유용합니다.

```python
result = await Runner.run(agent, "What's the weather in Tokyo?")

for i, request in enumerate(result.context_wrapper.usage.request_usage_entries):
    print(f"Request {i + 1}: {request.input_tokens} in, {request.output_tokens} out")
```

## 세션에서 사용량 접근

`Session`(예: `SQLiteSession`)을 사용할 때 `Runner.run(...)`의 각 호출은 해당 실행에 대한 사용량을 반환합니다. 세션은 컨텍스트를 위한 대화 히스토리를 유지하지만, 각 실행의 사용량은 서로 독립적입니다.

```python
session = SQLiteSession("my_conversation")

first = await Runner.run(agent, "Hi!", session=session)
print(first.context_wrapper.usage.total_tokens)  # Usage for first run

second = await Runner.run(agent, "Can you elaborate?", session=session)
print(second.context_wrapper.usage.total_tokens)  # Usage for second run
```

세션은 실행 간 대화 컨텍스트를 보존하지만, 각 `Runner.run()` 호출에서 반환되는 사용량 지표는 해당 실행만을 나타냅니다. 세션에서는 이전 메시지가 각 실행의 입력으로 다시 전달될 수 있으며, 이는 이후 턴의 입력 토큰 수에 영향을 줍니다.

## 훅에서 사용량 활용

`RunHooks`를 사용하는 경우, 각 훅에 전달되는 `context` 객체에 `usage`가 포함됩니다. 이를 통해 수명 주기의 핵심 시점에 사용량을 기록할 수 있습니다.

```python
class MyHooks(RunHooks):
    async def on_agent_end(self, context: RunContextWrapper, agent: Agent, output: Any) -> None:
        u = context.usage
        print(f"{agent.name} → {u.requests} requests, {u.total_tokens} total tokens")
```

## API 레퍼런스

자세한 API 문서는 다음을 참고하세요:

-   [`Usage`][agents.usage.Usage] - 사용량 추적 데이터 구조
-   [`RequestUsage`][agents.usage.RequestUsage] - 요청별 사용량 세부정보
-   [`RunContextWrapper`][agents.run.RunContextWrapper] - 실행 컨텍스트에서 사용량 접근
-   [`RunHooks`][agents.run.RunHooks] - 사용량 추적 수명 주기에 훅 연결

================
File: docs/ko/visualization.md
================
---
search:
  exclude: true
---
# 에이전트 시각화

에이전트 시각화는 **Graphviz**를 사용해 에이전트와 그 관계를 구조화된 그래프 형태로 생성합니다. 이는 애플리케이션 내에서 에이전트, 도구, 핸드오프가 어떻게 상호작용하는지 이해하는 데 유용합니다.

## 설치

선택적 `viz` 종속성 그룹을 설치하세요:

```bash
pip install "openai-agents[viz]"
```

## 그래프 생성

`draw_graph` 함수를 사용하여 에이전트 시각화를 생성할 수 있습니다. 이 함수는 다음과 같은 방향성 그래프를 만듭니다:

- **에이전트**는 노란색 상자로 표시됩니다.
- **MCP 서버**는 회색 상자로 표시됩니다.
- **도구**는 녹색 타원으로 표시됩니다.
- **핸드오프**는 한 에이전트에서 다른 에이전트로의 방향성 에지로 표시됩니다.

### 사용 예

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

이는 **triage agent**의 구조와 하위 에이전트 및 도구와의 연결을 시각적으로 나타내는 그래프를 생성합니다.


## 시각화 이해

생성된 그래프에는 다음이 포함됩니다:

- 진입점을 나타내는 **start 노드**(`__start__`)
- 노란색 채우기의 **직사각형**으로 표시된 에이전트
- 녹색 채우기의 **타원**으로 표시된 도구
- 회색 채우기의 **직사각형**으로 표시된 MCP 서버
- 상호작용을 나타내는 방향성 에지:
  - 에이전트 간 핸드오프는 **실선 화살표**
  - 도구 호출은 **점선 화살표**
  - MCP 서버 호출은 **파선 화살표**
- 실행이 종료되는 지점을 나타내는 **end 노드**(`__end__`)

**Note:** MCP 서버는 최근 버전의
`agents` 패키지에서 렌더링됩니다( **v0.2.8** 에서 검증됨). 시각화에 MCP 상자가 보이지 않는다면 최신 릴리스로 업그레이드하세요.

## 그래프 커스터마이징

### 그래프 표시
기본적으로 `draw_graph`는 그래프를 인라인으로 표시합니다. 그래프를 별도 창에 표시하려면 다음을 사용하세요:

```python
draw_graph(triage_agent).view()
```

### 그래프 저장
기본적으로 `draw_graph`는 그래프를 인라인으로 표시합니다. 파일로 저장하려면 파일 이름을 지정하세요:

```python
draw_graph(triage_agent, filename="agent_graph")
```

그러면 작업 디렉터리에 `agent_graph.png`가 생성됩니다.

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

This guide provides an in-depth look at building voice-enabled AI agents using the OpenAI Agents SDK's realtime capabilities.

!!! warning "Beta feature"
Realtime agents are in beta. Expect some breaking changes as we improve the implementation.

## Overview

Realtime agents allow for conversational flows, processing audio and text inputs in real time and responding with realtime audio. They maintain persistent connections with OpenAI's Realtime API, enabling natural voice conversations with low latency and the ability to handle interruptions gracefully.

## Architecture

### Core Components

The realtime system consists of several key components:

-   **RealtimeAgent**: An agent, configured with instructions, tools and handoffs.
-   **RealtimeRunner**: Manages configuration. You can call `runner.run()` to get a session.
-   **RealtimeSession**: A single interaction session. You typically create one each time a user starts a conversation, and keep it alive until the conversation is done.
-   **RealtimeModel**: The underlying model interface (typically OpenAI's WebSocket implementation)

### Session flow

A typical realtime session follows this flow:

1. **Create your RealtimeAgent(s)** with instructions, tools and handoffs.
2. **Set up a RealtimeRunner** with the agent and configuration options
3. **Start the session** using `await runner.run()` which returns a RealtimeSession.
4. **Send audio or text messages** to the session using `send_audio()` or `send_message()`
5. **Listen for events** by iterating over the session - events include audio output, transcripts, tool calls, handoffs, and errors
6. **Handle interruptions** when users speak over the agent, which automatically stops current audio generation

The session maintains the conversation history and manages the persistent connection with the realtime model.

## Agent configuration

RealtimeAgent works similarly to the regular Agent class with some key differences. For full API details, see the [`RealtimeAgent`][agents.realtime.agent.RealtimeAgent] API reference.

Key differences from regular agents:

-   Model choice is configured at the session level, not the agent level.
-   No structured output support (`outputType` is not supported).
-   Voice can be configured per agent but cannot be changed after the first agent speaks.
-   All other features like tools, handoffs, and instructions work the same way.

## Session configuration

### Model settings

The session configuration allows you to control the underlying realtime model behavior. You can configure the model name (such as `gpt-realtime`), voice selection (alloy, echo, fable, onyx, nova, shimmer), and supported modalities (text and/or audio). Audio formats can be set for both input and output, with PCM16 being the default.

### Audio configuration

Audio settings control how the session handles voice input and output. You can configure input audio transcription using models like Whisper, set language preferences, and provide transcription prompts to improve accuracy for domain-specific terms. Turn detection settings control when the agent should start and stop responding, with options for voice activity detection thresholds, silence duration, and padding around detected speech.

Additional configuration options you can set on `RealtimeRunner(config=...)` include:

-   `model_settings.output_modalities` to constrain output to text and/or audio.
-   `model_settings.input_audio_noise_reduction` to tune noise reduction for near-field or far-field audio.
-   `guardrails_settings.debounce_text_length` to control how frequently output guardrails run.
-   `async_tool_calls` to run function tools concurrently.
-   `tool_error_formatter` to customize model-visible tool error messages.

See [`RealtimeRunConfig`][agents.realtime.config.RealtimeRunConfig] and [`RealtimeSessionModelSettings`][agents.realtime.config.RealtimeSessionModelSettings] for the complete typed configuration.

## Tools and Functions

### Adding Tools

Just like regular agents, realtime agents support function tools that execute during conversations:

```python
from agents import function_tool

@function_tool
def get_weather(city: str) -> str:
    """Get current weather for a city."""
    # Your weather API logic here
    return f"The weather in {city} is sunny, 72°F"

@function_tool
def book_appointment(date: str, time: str, service: str) -> str:
    """Book an appointment."""
    # Your booking logic here
    return f"Appointment booked for {service} on {date} at {time}"

agent = RealtimeAgent(
    name="Assistant",
    instructions="You can help with weather and appointments.",
    tools=[get_weather, book_appointment],
)
```

## Handoffs

### Creating Handoffs

Handoffs allow transferring conversations between specialized agents.

```python
from agents.realtime import realtime_handoff

# Specialized agents
billing_agent = RealtimeAgent(
    name="Billing Support",
    instructions="You specialize in billing and payment issues.",
)

technical_agent = RealtimeAgent(
    name="Technical Support",
    instructions="You handle technical troubleshooting.",
)

# Main agent with handoffs
main_agent = RealtimeAgent(
    name="Customer Service",
    instructions="You are the main customer service agent. Hand off to specialists when needed.",
    handoffs=[
        realtime_handoff(billing_agent, tool_description="Transfer to billing support"),
        realtime_handoff(technical_agent, tool_description="Transfer to technical support"),
    ]
)
```

## Runtime behavior and session handling

### Event handling

The session streams events that you can listen to by iterating over the session object. Events include audio output chunks, transcription results, tool execution start and end, agent handoffs, and errors. Key events to handle include:

-   **audio**: Raw audio data from the agent's response
-   **audio_end**: Agent finished speaking
-   **audio_interrupted**: User interrupted the agent
-   **tool_start/tool_end**: Tool execution lifecycle
-   **handoff**: Agent handoff occurred
-   **error**: Error occurred during processing

For complete event details, see [`RealtimeSessionEvent`][agents.realtime.events.RealtimeSessionEvent].

### Guardrails

Only output guardrails are supported for realtime agents. These guardrails are debounced and run periodically (not on every word) to avoid performance issues during real-time generation. The default debounce length is 100 characters, but this is configurable.

Guardrails can be attached directly to a `RealtimeAgent` or provided via the session's `run_config`. Guardrails from both sources run together.

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

When a guardrail is triggered, it generates a `guardrail_tripped` event and can interrupt the agent's current response. The debounce behavior helps balance safety with real-time performance requirements. Unlike text agents, realtime agents do **not** raise an Exception when guardrails are tripped.

### Audio processing

Send audio to the session using [`session.send_audio(audio_bytes)`][agents.realtime.session.RealtimeSession.send_audio] or send text using [`session.send_message()`][agents.realtime.session.RealtimeSession.send_message].

For audio output, listen for `audio` events and play the audio data through your preferred audio library. Make sure to listen for `audio_interrupted` events to stop playback immediately and clear any queued audio when the user interrupts the agent.

## Advanced integrations and low-level access

### SIP integration

You can attach realtime agents to phone calls that arrive via the [Realtime Calls API](https://platform.openai.com/docs/guides/realtime-sip). The SDK provides [`OpenAIRealtimeSIPModel`][agents.realtime.openai_realtime.OpenAIRealtimeSIPModel], which reuses the same agent flow while negotiating media over SIP.

To use it, pass the model instance to the runner and supply the SIP `call_id` when starting the session. The call ID is delivered by the webhook that signals an incoming call.

```python
from agents.realtime import RealtimeAgent, RealtimeRunner
from agents.realtime.openai_realtime import OpenAIRealtimeSIPModel

runner = RealtimeRunner(
    starting_agent=agent,
    model=OpenAIRealtimeSIPModel(),
)

async with await runner.run(
    model_config={
        "call_id": call_id_from_webhook,
        "initial_model_settings": {
            "turn_detection": {"type": "semantic_vad", "interrupt_response": True},
        },
    },
) as session:
    async for event in session:
        ...
```

When the caller hangs up, the SIP session ends and the realtime connection closes automatically. For a complete telephony example, see [`examples/realtime/twilio_sip`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/twilio_sip).

### Direct model access

You can access the underlying model to add custom listeners or perform advanced operations:

```python
# Add a custom listener to the model
session.model.add_listener(my_custom_listener)
```

This gives you direct access to the [`RealtimeModel`][agents.realtime.model.RealtimeModel] interface for advanced use cases where you need lower-level control over the connection.

### Examples and further reading

For complete working examples, check out the [examples/realtime directory](https://github.com/openai/openai-agents-python/tree/main/examples/realtime) which includes demos with and without UI components.

### Azure OpenAI endpoint format

When connecting to Azure OpenAI, use the GA Realtime endpoint format and pass credentials via
headers in `model_config`:

```python
model_config = {
    "url": "wss://<your-resource>.openai.azure.com/openai/v1/realtime?model=<deployment-name>",
    "headers": {"api-key": "<your-azure-api-key>"},
}
```

For token-based auth, use `{"authorization": f"Bearer {token}"}` in `headers`.

================
File: docs/realtime/quickstart.md
================
# Quickstart

Realtime agents enable voice conversations with your AI agents using OpenAI's Realtime API. This guide walks you through creating your first realtime voice agent.

!!! warning "Beta feature"
Realtime agents are in beta. Expect some breaking changes as we improve the implementation.

## Prerequisites

-   Python 3.10 or higher
-   OpenAI API key
-   Basic familiarity with the OpenAI Agents SDK

## Installation

If you haven't already, install the OpenAI Agents SDK:

```bash
pip install openai-agents
```

## Creating your first realtime agent

### 1. Import required components

```python
import asyncio
from agents.realtime import RealtimeAgent, RealtimeRunner
```

### 2. Create a realtime agent

```python
agent = RealtimeAgent(
    name="Assistant",
    instructions="You are a helpful voice assistant. Keep your responses conversational and friendly.",
)
```

### 3. Set up the runner

```python
runner = RealtimeRunner(
    starting_agent=agent,
    config={
        "model_settings": {
            "model_name": "gpt-realtime",
            "voice": "ash",
            "modalities": ["audio"],
            "input_audio_format": "pcm16",
            "output_audio_format": "pcm16",
            "input_audio_transcription": {"model": "gpt-4o-mini-transcribe"},
            "turn_detection": {"type": "semantic_vad", "interrupt_response": True},
        }
    }
)
```

### 4. Start a session

```python
# Start the session
session = await runner.run()

async with session:
    print("Session started! The agent will stream audio responses in real-time.")
    # Process events
    async for event in session:
        try:
            if event.type == "agent_start":
                print(f"Agent started: {event.agent.name}")
            elif event.type == "agent_end":
                print(f"Agent ended: {event.agent.name}")
            elif event.type == "handoff":
                print(f"Handoff from {event.from_agent.name} to {event.to_agent.name}")
            elif event.type == "tool_start":
                print(f"Tool started: {event.tool.name}")
            elif event.type == "tool_end":
                print(f"Tool ended: {event.tool.name}; output: {event.output}")
            elif event.type == "audio_end":
                print("Audio ended")
            elif event.type == "audio":
                # Enqueue audio for callback-based playback with metadata
                # Non-blocking put; queue is unbounded, so drops won’t occur.
                pass
            elif event.type == "audio_interrupted":
                print("Audio interrupted")
                # Begin graceful fade + flush in the audio callback and rebuild jitter buffer.
            elif event.type == "error":
                print(f"Error: {event.error}")
            elif event.type == "history_updated":
                pass  # Skip these frequent events
            elif event.type == "history_added":
                pass  # Skip these frequent events
            elif event.type == "raw_model_event":
                print(f"Raw model event: {_truncate_str(str(event.data), 200)}")
            else:
                print(f"Unknown event type: {event.type}")
        except Exception as e:
            print(f"Error processing event: {_truncate_str(str(e), 200)}")

def _truncate_str(s: str, max_length: int) -> str:
    if len(s) > max_length:
        return s[:max_length] + "..."
    return s
```

## Full example (same flow in one file)

This is the same quickstart flow rewritten as a single script.

```python
import asyncio
from agents.realtime import RealtimeAgent, RealtimeRunner

async def main():
    # Create the agent
    agent = RealtimeAgent(
        name="Assistant",
        instructions="You are a helpful voice assistant. Keep responses brief and conversational.",
    )
    # Set up the runner with configuration
    runner = RealtimeRunner(
        starting_agent=agent,
        config={
            "model_settings": {
                "model_name": "gpt-realtime",
                "voice": "ash",
                "modalities": ["audio"],
                "input_audio_format": "pcm16",
                "output_audio_format": "pcm16",
                "input_audio_transcription": {"model": "gpt-4o-mini-transcribe"},
                "turn_detection": {"type": "semantic_vad", "interrupt_response": True},
            }
        },
    )
    # Start the session
    session = await runner.run()

    async with session:
        print("Session started! The agent will stream audio responses in real-time.")
        # Process events
        async for event in session:
            try:
                if event.type == "agent_start":
                    print(f"Agent started: {event.agent.name}")
                elif event.type == "agent_end":
                    print(f"Agent ended: {event.agent.name}")
                elif event.type == "handoff":
                    print(f"Handoff from {event.from_agent.name} to {event.to_agent.name}")
                elif event.type == "tool_start":
                    print(f"Tool started: {event.tool.name}")
                elif event.type == "tool_end":
                    print(f"Tool ended: {event.tool.name}; output: {event.output}")
                elif event.type == "audio_end":
                    print("Audio ended")
                elif event.type == "audio":
                    # Enqueue audio for callback-based playback with metadata
                    # Non-blocking put; queue is unbounded, so drops won’t occur.
                    pass
                elif event.type == "audio_interrupted":
                    print("Audio interrupted")
                    # Begin graceful fade + flush in the audio callback and rebuild jitter buffer.
                elif event.type == "error":
                    print(f"Error: {event.error}")
                elif event.type == "history_updated":
                    pass  # Skip these frequent events
                elif event.type == "history_added":
                    pass  # Skip these frequent events
                elif event.type == "raw_model_event":
                    print(f"Raw model event: {_truncate_str(str(event.data), 200)}")
                else:
                    print(f"Unknown event type: {event.type}")
            except Exception as e:
                print(f"Error processing event: {_truncate_str(str(e), 200)}")

def _truncate_str(s: str, max_length: int) -> str:
    if len(s) > max_length:
        return s[:max_length] + "..."
    return s

if __name__ == "__main__":
    # Run the session
    asyncio.run(main())
```

## Configuration and deployment notes

Use these options after you have a basic session running.

### Model settings

-   `model_name`: Choose from available realtime models (e.g., `gpt-realtime`)
-   `voice`: Select voice (`alloy`, `echo`, `fable`, `onyx`, `nova`, `shimmer`)
-   `modalities`: Enable text or audio (`["text"]` or `["audio"]`)
-   `output_modalities`: Optionally constrain output to text and/or audio (`["text"]`, `["audio"]`, or both)

### Audio settings

-   `input_audio_format`: Format for input audio (`pcm16`, `g711_ulaw`, `g711_alaw`)
-   `output_audio_format`: Format for output audio
-   `input_audio_transcription`: Transcription configuration
-   `input_audio_noise_reduction`: Input noise-reduction config (`near_field` or `far_field`)

### Turn detection

-   `type`: Detection method (`server_vad`, `semantic_vad`)
-   `threshold`: Voice activity threshold (0.0-1.0)
-   `silence_duration_ms`: Silence duration to detect turn end
-   `prefix_padding_ms`: Audio padding before speech

### Run settings

-   `async_tool_calls`: Whether function tools run asynchronously (defaults to `True`)
-   `guardrails_settings.debounce_text_length`: Minimum accumulated transcript size before output guardrails run (defaults to `100`)
-   `tool_error_formatter`: Callback to customize model-visible tool error messages

For the full schema, see the API reference for [`RealtimeRunConfig`][agents.realtime.config.RealtimeRunConfig] and [`RealtimeSessionModelSettings`][agents.realtime.config.RealtimeSessionModelSettings].

### Authentication

Make sure your OpenAI API key is set in your environment:

```bash
export OPENAI_API_KEY="your-api-key-here"
```

Or pass it directly when creating the session:

```python
session = await runner.run(model_config={"api_key": "your-api-key"})
```

### Azure OpenAI endpoint format

If you connect to Azure OpenAI instead of OpenAI's default endpoint, pass a GA Realtime URL in
`model_config["url"]` and set auth headers explicitly.

```python
session = await runner.run(
    model_config={
        "url": "wss://<your-resource>.openai.azure.com/openai/v1/realtime?model=<deployment-name>",
        "headers": {"api-key": "<your-azure-api-key>"},
    }
)
```

You can also use a bearer token:

```python
session = await runner.run(
    model_config={
        "url": "wss://<your-resource>.openai.azure.com/openai/v1/realtime?model=<deployment-name>",
        "headers": {"authorization": f"Bearer {token}"},
    }
)
```

Avoid using the legacy beta path (`/openai/realtime?api-version=...`) with realtime agents. The
SDK expects the GA Realtime interface.

## Next steps

-   [Learn more about realtime agents](guide.md)
-   Check out working examples in the [examples/realtime](https://github.com/openai/openai-agents-python/tree/main/examples/realtime) folder
-   Add tools to your agent
-   Implement handoffs between agents
-   Set up guardrails for safety

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
# ::: agents.extensions.memory.dapr_session.DaprSession

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
# Advanced SQLite Sessions

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


## API Reference

- [`AdvancedSQLiteSession`][agents.extensions.memory.advanced_sqlite_session.AdvancedSQLiteSession] - Main class
- [`Session`][agents.memory.session.Session] - Base session protocol

================
File: docs/sessions/encrypted_session.md
================
# Encrypted Sessions

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

### TTL (Time To Live)

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

## API Reference

- [`EncryptedSession`][agents.extensions.memory.encrypt_session.EncryptedSession] - Main class
- [`Session`][agents.memory.session.Session] - Base session protocol

================
File: docs/sessions/index.md
================
# Sessions

The Agents SDK provides built-in session memory to automatically maintain conversation history across multiple agent runs, eliminating the need to manually handle `.to_input_list()` between turns.

Sessions stores conversation history for a specific session, allowing agents to maintain context without requiring explicit manual memory management. This is particularly useful for building chat applications or multi-turn conversations where you want the agent to remember previous interactions.

Use sessions when you want the SDK to manage client-side memory for you. If you are already using OpenAI server-managed state with `conversation_id` or `previous_response_id`, you usually do not also need a session for the same conversation.

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

Use this when you need custom pruning, reordering, or selective inclusion of history without changing how the session stores items.

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

## API Reference

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
# SQLAlchemy Sessions

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


## API Reference

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

Agents SDK 开箱即用地支持两种形式的 OpenAI 模型：

-   **推荐**：[`OpenAIResponsesModel`][agents.models.openai_responses.OpenAIResponsesModel]，使用新的 [Responses API](https://platform.openai.com/docs/api-reference/responses) 调用 OpenAI API。
-   [`OpenAIChatCompletionsModel`][agents.models.openai_chatcompletions.OpenAIChatCompletionsModel]，使用 [Chat Completions API](https://platform.openai.com/docs/api-reference/chat) 调用 OpenAI API。

## 模型设置选择

请根据你的配置按以下顺序使用本页：

| 目标 | 从这里开始 |
| --- | --- |
| 使用 SDK 默认配置的 OpenAI 托管模型 | [OpenAI 模型](#openai-models) |
| 通过 websocket 传输使用 OpenAI Responses API | [Responses WebSocket 传输](#responses-websocket-transport) |
| 使用非 OpenAI 提供方 | [非 OpenAI 模型](#non-openai-models) |
| 在一个工作流中混用模型/提供方 | [高级模型选择与混用](#advanced-model-selection-and-mixing) 和 [跨提供方混用模型](#mixing-models-across-providers) |
| 调试提供方兼容性问题 | [非 OpenAI 提供方故障排查](#troubleshooting-non-openai-providers) |

## OpenAI 模型

当你在初始化 `Agent` 时未指定模型，将使用默认模型。当前默认值是 [`gpt-4.1`](https://platform.openai.com/docs/models/gpt-4.1)，以兼顾兼容性与低延迟。如果你有权限访问，我们建议将智能体设置为 [`gpt-5.2`](https://platform.openai.com/docs/models/gpt-5.2) 以获得更高质量，同时显式设置 `model_settings`。

如果你想切换到其他模型（如 [`gpt-5.2`](https://platform.openai.com/docs/models/gpt-5.2)），有两种方式配置智能体。

### 默认模型

首先，如果你希望对所有未设置自定义模型的智能体始终使用某个特定模型，请在运行智能体前设置 `OPENAI_DEFAULT_MODEL` 环境变量。

```bash
export OPENAI_DEFAULT_MODEL=gpt-5.2
python3 my_awesome_agent.py
```

其次，你可以通过 `RunConfig` 为一次运行设置默认模型。如果你未为智能体设置模型，则会使用本次运行的模型。

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

当你以这种方式使用任意 GPT-5.x 模型（如 [`gpt-5.2`](https://platform.openai.com/docs/models/gpt-5.2)）时，SDK 会应用默认 `ModelSettings`。它会设置在大多数场景下效果最佳的配置。要调整默认模型的推理强度，请传入你自己的 `ModelSettings`：

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

为获得更低延迟，建议在 `gpt-5.2` 上使用 `reasoning.effort="none"`。gpt-4.1 系列（包括 mini 和 nano 变体）在构建交互式智能体应用时也依然是可靠选择。

#### 非 GPT-5 模型

如果你传入非 GPT-5 的模型名且未提供自定义 `model_settings`，SDK 会回退到与任意模型兼容的通用 `ModelSettings`。

### Responses WebSocket 传输

默认情况下，OpenAI Responses API 请求使用 HTTP 传输。使用 OpenAI 支持的模型时，你可以选择启用 websocket 传输。

```python
from agents import set_default_openai_responses_transport

set_default_openai_responses_transport("websocket")
```

这会影响由默认 OpenAI 提供方解析的 OpenAI Responses 模型（包括如 `"gpt-5.2"` 这样的字符串模型名）。

传输方式的选择发生在 SDK 将模型名解析为模型实例时。如果你传入具体的 [`Model`][agents.models.interface.Model] 对象，其传输方式已固定：[`OpenAIResponsesWSModel`][agents.models.openai_responses.OpenAIResponsesWSModel] 使用 websocket，[`OpenAIResponsesModel`][agents.models.openai_responses.OpenAIResponsesModel] 使用 HTTP，[`OpenAIChatCompletionsModel`][agents.models.openai_chatcompletions.OpenAIChatCompletionsModel] 则保持使用 Chat Completions。如果你传入 `RunConfig(model_provider=...)`，则由该提供方控制传输方式选择，而不是全局默认值。

你也可以按提供方或按单次运行配置 websocket 传输：

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

如果你需要基于前缀的模型路由（例如在一次运行中混用 `openai/...` 与 `litellm/...` 模型名），请改用 [`MultiProvider`][agents.MultiProvider] 并在其中设置 `openai_use_responses_websocket=True`。

如果你使用自定义的 OpenAI 兼容端点或代理，websocket 传输还要求存在兼容的 websocket `/responses` 端点。在这些配置下，你可能需要显式设置 `websocket_base_url`。

注意：

-   这里指的是通过 websocket 传输的 Responses API，而不是 [Realtime API](../realtime/guide.md)。除非支持 Responses websocket `/responses` 端点，否则这不适用于 Chat Completions 或非 OpenAI 提供方。
-   如果你的环境中尚未安装，请安装 `websockets` 包。
-   启用 websocket 传输后，你可以直接使用 [`Runner.run_streamed()`][agents.run.Runner.run_streamed]。对于希望在多轮工作流（以及嵌套的 agent-as-tool 调用）中复用同一 websocket 连接的场景，建议使用 [`responses_websocket_session()`][agents.responses_websocket_session] 辅助函数。参见 [运行智能体](../running_agents.md) 指南和 [`examples/basic/stream_ws.py`](https://github.com/openai/openai-agents-python/tree/main/examples/basic/stream_ws.py)。

## 非 OpenAI 模型

你可以通过 [LiteLLM 集成](./litellm.md) 使用大多数其他非 OpenAI 模型。首先，安装 litellm 依赖组：

```bash
pip install "openai-agents[litellm]"
```

然后，使用任意[支持的模型](https://docs.litellm.ai/docs/providers)，并加上 `litellm/` 前缀：

```python
claude_agent = Agent(model="litellm/anthropic/claude-3-5-sonnet-20240620", ...)
gemini_agent = Agent(model="litellm/gemini/gemini-2.5-flash-preview-04-17", ...)
```

### 使用非 OpenAI 模型的其他方式

你还可以通过另外 3 种方式集成其他 LLM 提供方（示例见[这里](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/)）：

1. [`set_default_openai_client`][agents.set_default_openai_client] 适用于你希望全局使用 `AsyncOpenAI` 实例作为 LLM 客户端的情况。适合 LLM 提供方具备 OpenAI 兼容 API 端点，且你可以设置 `base_url` 与 `api_key` 的场景。可配置示例见 [examples/model_providers/custom_example_global.py](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/custom_example_global.py)。
2. [`ModelProvider`][agents.models.interface.ModelProvider] 位于 `Runner.run` 层级。这让你可以声明“本次运行中的所有智能体都使用自定义模型提供方”。可配置示例见 [examples/model_providers/custom_example_provider.py](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/custom_example_provider.py)。
3. [`Agent.model`][agents.agent.Agent.model] 允许你在特定 Agent 实例上指定模型。这使你能够为不同智能体混用不同提供方。可配置示例见 [examples/model_providers/custom_example_agent.py](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/custom_example_agent.py)。使用多数可用模型的简便方式是通过 [LiteLLM 集成](./litellm.md)。

在你没有 `platform.openai.com` API key 的情况下，我们建议通过 `set_tracing_disabled()` 关闭追踪，或配置[其他追踪进程](../tracing.md)。

!!! note

    在这些示例中，我们使用 Chat Completions API/模型，因为大多数 LLM 提供方尚不支持 Responses API。如果你的 LLM 提供方支持，我们建议使用 Responses。

## 高级模型选择与混用

在单个工作流中，你可能希望为每个智能体使用不同模型。例如，你可以为分流使用更小、更快的模型，同时为复杂任务使用更大、能力更强的模型。配置 [`Agent`][agents.Agent] 时，你可以通过以下方式之一选择特定模型：

1. 传入模型名称。
2. 传入任意模型名 + 可将该名称映射为 Model 实例的 [`ModelProvider`][agents.models.interface.ModelProvider]。
3. 直接提供 [`Model`][agents.models.interface.Model] 实现。

!!!note

    虽然我们的 SDK 同时支持 [`OpenAIResponsesModel`][agents.models.openai_responses.OpenAIResponsesModel] 与 [`OpenAIChatCompletionsModel`][agents.models.openai_chatcompletions.OpenAIChatCompletionsModel] 两种形态，但我们建议在每个工作流中使用单一模型形态，因为两者支持的功能和工具集合不同。如果你的工作流需要混用不同模型形态，请确保你使用的所有功能在两者上都可用。

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

当你希望进一步配置智能体使用的模型时，可以传入 [`ModelSettings`][agents.models.interface.ModelSettings]，它提供了可选的模型配置参数，如 temperature。

```python
from agents import Agent, ModelSettings

english_agent = Agent(
    name="English agent",
    instructions="You only speak English",
    model="gpt-4.1",
    model_settings=ModelSettings(temperature=0.1),
)
```

此外，当你使用 OpenAI 的 Responses API 时，[还有一些其他可选参数](https://platform.openai.com/docs/api-reference/responses/create)（例如 `user`、`service_tier` 等）。如果它们在顶层不可用，你也可以通过 `extra_args` 传入。

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

如果你遇到与追踪相关的错误，是因为 trace 会上传到 OpenAI 服务端，而你没有 OpenAI API key。你有三种解决方式：

1. 完全禁用追踪：[`set_tracing_disabled(True)`][agents.set_tracing_disabled]。
2. 为追踪设置 OpenAI key：[`set_tracing_export_api_key(...)`][agents.set_tracing_export_api_key]。该 API key 仅用于上传 trace，且必须来自 [platform.openai.com](https://platform.openai.com/)。
3. 使用非 OpenAI 追踪进程。参见 [追踪文档](../tracing.md#custom-tracing-processors)。

### Responses API 支持

SDK 默认使用 Responses API，但大多数其他 LLM 提供方尚不支持。因此你可能会看到 404 或类似问题。你有两种解决方式：

1. 调用 [`set_default_openai_api("chat_completions")`][agents.set_default_openai_api]。当你通过环境变量设置 `OPENAI_API_KEY` 和 `OPENAI_BASE_URL` 时可用。
2. 使用 [`OpenAIChatCompletionsModel`][agents.models.openai_chatcompletions.OpenAIChatCompletionsModel]。示例见[这里](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/)。

### structured outputs 支持

部分模型提供方不支持 [structured outputs](https://platform.openai.com/docs/guides/structured-outputs)。这有时会导致如下所示的错误：

```

BadRequestError: Error code: 400 - {'error': {'message': "'response_format.type' : value is not one of the allowed values ['text','json_object']", 'type': 'invalid_request_error'}}

```

这是某些模型提供方的短板——它们支持 JSON 输出，但不允许你为输出指定要使用的 `json_schema`。我们正在修复这一问题，但建议你依赖支持 JSON schema 输出的提供方，否则应用会经常因 JSON 格式错误而中断。

## 跨提供方混用模型

你需要注意不同模型提供方的功能差异，否则可能遇到错误。例如，OpenAI 支持 structured outputs、多模态输入，以及托管的文件检索和网络检索，但许多其他提供方不支持这些能力。请注意以下限制：

-   不要向不支持的提供方发送其无法理解的 `tools`
-   在调用仅支持文本的模型前，先过滤掉多模态输入
-   注意不支持结构化 JSON 输出的提供方会偶尔生成无效 JSON

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

本指南深入介绍如何使用 OpenAI Agents SDK 的 realtime 能力构建支持语音的 AI 智能体。

!!! warning "Beta 功能"
Realtime 智能体目前处于 beta 阶段。随着我们改进实现，预计会有一些破坏性变更。

## 概览

Realtime 智能体支持对话流程，能够实时处理音频与文本输入，并以 realtime 音频进行响应。它们与 OpenAI 的 Realtime API 保持持久连接，从而实现低延迟的自然语音对话，并能优雅地处理打断。

## 架构

### 核心组件

realtime 系统由几个关键组件组成：

-   **RealtimeAgent**：一个智能体，使用 instructions、tools 和 handoffs 进行配置。
-   **RealtimeRunner**：管理配置。你可以调用 `runner.run()` 获取一个会话。
-   **RealtimeSession**：单次交互会话。通常在用户开始对话时创建一个，并在对话结束前保持存活。
-   **RealtimeModel**：底层模型接口（通常是 OpenAI 的 WebSocket 实现）

### 会话流程

一个典型的 realtime 会话遵循如下流程：

1. 使用 instructions、tools 和 handoffs **创建你的 RealtimeAgent（可多个）**。
2. 使用智能体与配置选项 **设置 RealtimeRunner**。
3. 使用 `await runner.run()` **启动会话**，该调用会返回一个 RealtimeSession。
4. 使用 `send_audio()` 或 `send_message()` **向会话发送音频或文本消息**。
5. 通过遍历会话 **监听事件**——事件包括音频输出、转写文本、工具调用、任务转移以及错误。
6. 在用户打断智能体讲话时 **处理打断**，系统会自动停止当前音频生成。

会话会维护对话历史，并管理与 realtime 模型的持久连接。

## 智能体配置

RealtimeAgent 的工作方式与常规 Agent 类相似，但存在一些关键差异。完整 API 细节请参见 [`RealtimeAgent`][agents.realtime.agent.RealtimeAgent] API 参考。

与常规智能体的主要差异：

-   模型选择在会话级别配置，而非智能体级别。
-   不支持 structured outputs（不支持 `outputType`）。
-   可按智能体配置语音，但在第一个智能体开口后不可再更改。
-   其他特性（如 tools、handoffs 与 instructions）的工作方式相同。

## 会话配置

### 模型设置

会话配置允许你控制底层 realtime 模型的行为。你可以配置模型名称（例如 `gpt-realtime`）、语音选择（alloy、echo、fable、onyx、nova、shimmer）以及支持的模态（文本和/或音频）。输入与输出的音频格式均可设置，默认是 PCM16。

### 音频配置

音频设置控制会话如何处理语音输入与输出。你可以使用 Whisper 等模型配置输入音频转写，设置语言偏好，并提供转写提示词以提升领域术语的准确率。轮次检测设置用于控制智能体何时开始与停止响应，可配置语音活动检测阈值、静默时长以及在检测到语音前后的填充。

你还可以在 `RealtimeRunner(config=...)` 上设置的其他配置选项包括：

-   `model_settings.output_modalities`：将输出约束为文本和/或音频。
-   `model_settings.input_audio_noise_reduction`：针对近场或远场音频调节降噪。
-   `guardrails_settings.debounce_text_length`：控制输出安全防护措施的运行频率。
-   `async_tool_calls`：并发运行工具调用。
-   `tool_error_formatter`：自定义模型可见的工具错误消息。

完整的类型化配置请参见 [`RealtimeRunConfig`][agents.realtime.config.RealtimeRunConfig] 与 [`RealtimeSessionModelSettings`][agents.realtime.config.RealtimeSessionModelSettings]。

## 工具与函数

### 添加工具

与常规智能体一样，realtime 智能体支持在对话过程中执行的工具调用：

```python
from agents import function_tool

@function_tool
def get_weather(city: str) -> str:
    """Get current weather for a city."""
    # Your weather API logic here
    return f"The weather in {city} is sunny, 72°F"

@function_tool
def book_appointment(date: str, time: str, service: str) -> str:
    """Book an appointment."""
    # Your booking logic here
    return f"Appointment booked for {service} on {date} at {time}"

agent = RealtimeAgent(
    name="Assistant",
    instructions="You can help with weather and appointments.",
    tools=[get_weather, book_appointment],
)
```

## 任务转移

### 创建任务转移

任务转移允许在专门化智能体之间转移对话。

```python
from agents.realtime import realtime_handoff

# Specialized agents
billing_agent = RealtimeAgent(
    name="Billing Support",
    instructions="You specialize in billing and payment issues.",
)

technical_agent = RealtimeAgent(
    name="Technical Support",
    instructions="You handle technical troubleshooting.",
)

# Main agent with handoffs
main_agent = RealtimeAgent(
    name="Customer Service",
    instructions="You are the main customer service agent. Hand off to specialists when needed.",
    handoffs=[
        realtime_handoff(billing_agent, tool_description="Transfer to billing support"),
        realtime_handoff(technical_agent, tool_description="Transfer to technical support"),
    ]
)
```

## 运行时行为与会话处理

### 事件处理

会话会流式输出事件，你可以通过遍历会话对象来监听。事件包括音频输出分块、转写结果、工具执行开始与结束、智能体任务转移以及错误。需要处理的关键事件包括：

-   **audio**：来自智能体响应的原始音频数据
-   **audio_end**：智能体结束讲话
-   **audio_interrupted**：用户打断了智能体
-   **tool_start/tool_end**：工具执行生命周期
-   **handoff**：发生了智能体任务转移
-   **error**：处理过程中发生错误

完整事件细节请参见 [`RealtimeSessionEvent`][agents.realtime.events.RealtimeSessionEvent]。

### 安全防护措施

realtime 智能体仅支持输出安全防护措施。这些安全防护措施会进行去抖并周期性运行（而不是每个词都运行），以避免实时生成过程中的性能问题。默认去抖长度为 100 个字符，但可配置。

安全防护措施可以直接挂载到 `RealtimeAgent`，也可以通过会话的 `run_config` 提供。两种来源的安全防护措施会一起运行。

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

当触发安全防护措施时，会生成一个 `guardrail_tripped` 事件，并可能中断智能体当前的响应。去抖行为有助于在安全性与实时性能需求之间取得平衡。与文本智能体不同，realtime 智能体在安全防护措施触发时**不会**抛出 Exception。

### 音频处理

使用 [`session.send_audio(audio_bytes)`][agents.realtime.session.RealtimeSession.send_audio] 向会话发送音频，或使用 [`session.send_message()`][agents.realtime.session.RealtimeSession.send_message] 发送文本。

对于音频输出，监听 `audio` 事件，并通过你偏好的音频库播放音频数据。务必监听 `audio_interrupted` 事件，在用户打断智能体时立即停止播放，并清空所有排队的音频。

## 高级集成与底层访问

### SIP 集成

你可以将 realtime 智能体接入通过 [Realtime Calls API](https://platform.openai.com/docs/guides/realtime-sip) 接入的电话呼叫。SDK 提供了 [`OpenAIRealtimeSIPModel`][agents.realtime.openai_realtime.OpenAIRealtimeSIPModel]，它会在通过 SIP 协商媒体的同时复用相同的智能体流程。

使用方式是：将模型实例传给 runner，并在启动会话时提供 SIP `call_id`。该 call ID 由用于通知来电的 webhook 投递。

```python
from agents.realtime import RealtimeAgent, RealtimeRunner
from agents.realtime.openai_realtime import OpenAIRealtimeSIPModel

runner = RealtimeRunner(
    starting_agent=agent,
    model=OpenAIRealtimeSIPModel(),
)

async with await runner.run(
    model_config={
        "call_id": call_id_from_webhook,
        "initial_model_settings": {
            "turn_detection": {"type": "semantic_vad", "interrupt_response": True},
        },
    },
) as session:
    async for event in session:
        ...
```

当来电方挂断时，SIP 会话结束，realtime 连接会自动关闭。完整的电话示例请参见 [`examples/realtime/twilio_sip`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/twilio_sip)。

### 直接访问模型

你可以访问底层模型以添加自定义监听器或执行高级操作：

```python
# Add a custom listener to the model
session.model.add_listener(my_custom_listener)
```

这会让你直接访问 [`RealtimeModel`][agents.realtime.model.RealtimeModel] 接口，适用于需要更底层连接控制的高级用例。

### 代码示例与延伸阅读

如需完整可运行的代码示例，请查看 [examples/realtime directory](https://github.com/openai/openai-agents-python/tree/main/examples/realtime)，其中包含带 UI 组件与不带 UI 组件的演示。

### Azure OpenAI 端点格式

连接 Azure OpenAI 时，请使用 GA Realtime 端点格式，并通过
`model_config` 中的 headers 传递凭据：

```python
model_config = {
    "url": "wss://<your-resource>.openai.azure.com/openai/v1/realtime?model=<deployment-name>",
    "headers": {"api-key": "<your-azure-api-key>"},
}
```

对于基于 token 的鉴权，请在 `headers` 中使用 `{"authorization": f"Bearer {token}"}`。

================
File: docs/zh/realtime/quickstart.md
================
---
search:
  exclude: true
---
# 快速入门

Realtime 智能体让你可以使用 OpenAI 的 Realtime API 与你的 AI 智能体进行语音对话。本指南将带你创建你的第一个 realtime 语音智能体。

!!! warning "Beta 功能"
Realtime 智能体目前处于 beta 阶段。随着我们改进实现，可能会出现一些破坏性变更。

## 前提条件

-   Python 3.10 或更高版本
-   OpenAI API key
-   对 OpenAI Agents SDK 有基本了解

## 安装

如果你还没有安装，请安装 OpenAI Agents SDK：

```bash
pip install openai-agents
```

## 创建你的第一个 realtime 智能体

### 1. 导入所需组件

```python
import asyncio
from agents.realtime import RealtimeAgent, RealtimeRunner
```

### 2. 创建一个 realtime 智能体

```python
agent = RealtimeAgent(
    name="Assistant",
    instructions="You are a helpful voice assistant. Keep your responses conversational and friendly.",
)
```

### 3. 设置 runner

```python
runner = RealtimeRunner(
    starting_agent=agent,
    config={
        "model_settings": {
            "model_name": "gpt-realtime",
            "voice": "ash",
            "modalities": ["audio"],
            "input_audio_format": "pcm16",
            "output_audio_format": "pcm16",
            "input_audio_transcription": {"model": "gpt-4o-mini-transcribe"},
            "turn_detection": {"type": "semantic_vad", "interrupt_response": True},
        }
    }
)
```

### 4. 启动一个会话

```python
# Start the session
session = await runner.run()

async with session:
    print("Session started! The agent will stream audio responses in real-time.")
    # Process events
    async for event in session:
        try:
            if event.type == "agent_start":
                print(f"Agent started: {event.agent.name}")
            elif event.type == "agent_end":
                print(f"Agent ended: {event.agent.name}")
            elif event.type == "handoff":
                print(f"Handoff from {event.from_agent.name} to {event.to_agent.name}")
            elif event.type == "tool_start":
                print(f"Tool started: {event.tool.name}")
            elif event.type == "tool_end":
                print(f"Tool ended: {event.tool.name}; output: {event.output}")
            elif event.type == "audio_end":
                print("Audio ended")
            elif event.type == "audio":
                # Enqueue audio for callback-based playback with metadata
                # Non-blocking put; queue is unbounded, so drops won’t occur.
                pass
            elif event.type == "audio_interrupted":
                print("Audio interrupted")
                # Begin graceful fade + flush in the audio callback and rebuild jitter buffer.
            elif event.type == "error":
                print(f"Error: {event.error}")
            elif event.type == "history_updated":
                pass  # Skip these frequent events
            elif event.type == "history_added":
                pass  # Skip these frequent events
            elif event.type == "raw_model_event":
                print(f"Raw model event: {_truncate_str(str(event.data), 200)}")
            else:
                print(f"Unknown event type: {event.type}")
        except Exception as e:
            print(f"Error processing event: {_truncate_str(str(e), 200)}")

def _truncate_str(s: str, max_length: int) -> str:
    if len(s) > max_length:
        return s[:max_length] + "..."
    return s
```

## 完整示例（同一流程放在一个文件中）

这是将同一快速入门流程改写为单个脚本后的版本。

```python
import asyncio
from agents.realtime import RealtimeAgent, RealtimeRunner

async def main():
    # Create the agent
    agent = RealtimeAgent(
        name="Assistant",
        instructions="You are a helpful voice assistant. Keep responses brief and conversational.",
    )
    # Set up the runner with configuration
    runner = RealtimeRunner(
        starting_agent=agent,
        config={
            "model_settings": {
                "model_name": "gpt-realtime",
                "voice": "ash",
                "modalities": ["audio"],
                "input_audio_format": "pcm16",
                "output_audio_format": "pcm16",
                "input_audio_transcription": {"model": "gpt-4o-mini-transcribe"},
                "turn_detection": {"type": "semantic_vad", "interrupt_response": True},
            }
        },
    )
    # Start the session
    session = await runner.run()

    async with session:
        print("Session started! The agent will stream audio responses in real-time.")
        # Process events
        async for event in session:
            try:
                if event.type == "agent_start":
                    print(f"Agent started: {event.agent.name}")
                elif event.type == "agent_end":
                    print(f"Agent ended: {event.agent.name}")
                elif event.type == "handoff":
                    print(f"Handoff from {event.from_agent.name} to {event.to_agent.name}")
                elif event.type == "tool_start":
                    print(f"Tool started: {event.tool.name}")
                elif event.type == "tool_end":
                    print(f"Tool ended: {event.tool.name}; output: {event.output}")
                elif event.type == "audio_end":
                    print("Audio ended")
                elif event.type == "audio":
                    # Enqueue audio for callback-based playback with metadata
                    # Non-blocking put; queue is unbounded, so drops won’t occur.
                    pass
                elif event.type == "audio_interrupted":
                    print("Audio interrupted")
                    # Begin graceful fade + flush in the audio callback and rebuild jitter buffer.
                elif event.type == "error":
                    print(f"Error: {event.error}")
                elif event.type == "history_updated":
                    pass  # Skip these frequent events
                elif event.type == "history_added":
                    pass  # Skip these frequent events
                elif event.type == "raw_model_event":
                    print(f"Raw model event: {_truncate_str(str(event.data), 200)}")
                else:
                    print(f"Unknown event type: {event.type}")
            except Exception as e:
                print(f"Error processing event: {_truncate_str(str(e), 200)}")

def _truncate_str(s: str, max_length: int) -> str:
    if len(s) > max_length:
        return s[:max_length] + "..."
    return s

if __name__ == "__main__":
    # Run the session
    asyncio.run(main())
```

## 配置与部署说明

在你已经跑通一个基础会话之后，再使用这些选项。

### 模型设置

-   `model_name`: 从可用的 realtime 模型中选择（例如 `gpt-realtime`）
-   `voice`: 选择语音（`alloy`、`echo`、`fable`、`onyx`、`nova`、`shimmer`）
-   `modalities`: 启用文本或音频（`["text"]` 或 `["audio"]`）
-   `output_modalities`: 可选地将输出限制为文本和/或音频（`["text"]`、`["audio"]` 或两者）

### 音频设置

-   `input_audio_format`: 输入音频的格式（`pcm16`、`g711_ulaw`、`g711_alaw`）
-   `output_audio_format`: 输出音频的格式
-   `input_audio_transcription`: 转写配置
-   `input_audio_noise_reduction`: 输入降噪配置（`near_field` 或 `far_field`）

### 轮次检测

-   `type`: 检测方法（`server_vad`、`semantic_vad`）
-   `threshold`: 语音活动阈值（0.0-1.0）
-   `silence_duration_ms`: 用于检测轮次结束的静默时长
-   `prefix_padding_ms`: 语音前的音频填充

### 运行设置

-   `async_tool_calls`: 工具调用是否异步运行（默认为 `True`）
-   `guardrails_settings.debounce_text_length`: 在输出安全防护措施运行前，累计转写内容的最小大小（默认为 `100`）
-   `tool_error_formatter`: 用于自定义模型可见的工具错误消息的回调

完整 schema 请参阅 [`RealtimeRunConfig`][agents.realtime.config.RealtimeRunConfig] 与 [`RealtimeSessionModelSettings`][agents.realtime.config.RealtimeSessionModelSettings] 的 API 参考。

### 身份验证

请确保你的环境中已设置 OpenAI API key：

```bash
export OPENAI_API_KEY="your-api-key-here"
```

或者在创建会话时直接传入：

```python
session = await runner.run(model_config={"api_key": "your-api-key"})
```

### Azure OpenAI 端点格式

如果你连接的是 Azure OpenAI 而不是 OpenAI 的默认端点，请在
`model_config["url"]` 中传入一个 GA Realtime URL，并显式设置 auth headers。

```python
session = await runner.run(
    model_config={
        "url": "wss://<your-resource>.openai.azure.com/openai/v1/realtime?model=<deployment-name>",
        "headers": {"api-key": "<your-azure-api-key>"},
    }
)
```

你也可以使用 bearer token：

```python
session = await runner.run(
    model_config={
        "url": "wss://<your-resource>.openai.azure.com/openai/v1/realtime?model=<deployment-name>",
        "headers": {"authorization": f"Bearer {token}"},
    }
)
```

避免在 realtime 智能体中使用旧的 beta 路径（`/openai/realtime?api-version=...`）。该
SDK 期望使用 GA Realtime 接口。

## 后续步骤

-   [进一步了解 realtime 智能体](guide.md)
-   查看 [examples/realtime](https://github.com/openai/openai-agents-python/tree/main/examples/realtime) 文件夹中的可运行示例
-   为你的智能体添加工具
-   实现智能体之间的任务转移
-   设置安全防护措施以确保安全

================
File: docs/zh/sessions/advanced_sqlite_session.md
================
---
search:
  exclude: true
---
# 高级 SQLite 会话

`AdvancedSQLiteSession` 是对基础 `SQLiteSession` 的增强版本，提供高级对话管理功能，包括对话分支、详细的用量分析以及结构化的对话查询。

## 功能

- **对话分支**: 从任意用户消息创建替代的对话路径
- **用量跟踪**: 按回合的详细 token 用量分析，并提供完整的 JSON 分解
- **结构化查询**: 按回合获取对话、工具使用统计等
- **分支管理**: 独立的分支切换与管理
- **消息结构元数据**: 跟踪消息类型、工具使用与对话流转

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

- `session_id` (str): 对话会话的唯一标识符
- `db_path` (str | Path): SQLite 数据库文件路径。默认为 `:memory:`（内存存储）
- `create_tables` (bool): 是否自动创建高级表。默认 `False`
- `logger` (logging.Logger | None): 会话的自定义日志记录器。默认为模块级日志记录器

## 用量跟踪

AdvancedSQLiteSession 通过按对话回合存储 token 用量数据来提供详细的用量分析。**这完全依赖于在每次智能体运行后调用 `store_run_usage` 方法。**

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

AdvancedSQLiteSession 的关键特性之一是能够从任意用户消息创建对话分支，从而探索替代的对话路径。

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

AdvancedSQLiteSession 提供多种方法来分析对话结构与内容。

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

会话会自动跟踪消息结构，包括：

- 消息类型（用户、助手、tool_call 等）
- 工具调用的工具名称
- 回合号与序列号
- 分支关联
- 时间戳

## 数据库模式

AdvancedSQLiteSession 在基础 SQLite 模式上扩展了两个附加表：

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

查看[完整示例](https://github.com/openai/openai-agents-python/tree/main/examples/memory/advanced_sqlite_session_example.py)，以获得对所有功能的全面演示。


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

`EncryptedSession` 为任何会话实现提供透明加密，通过自动过期机制保护对话数据并在过期后静默跳过旧项。

## 功能

- **透明加密**：使用 Fernet 加密封装任何会话
- **会话级密钥**：使用 HKDF 为每个会话派生唯一加密密钥
- **自动过期**：当 TTL 到期时旧项会被静默跳过
- **可直接替换**：可与任何现有会话实现配合使用

## 安装

加密会话需要安装 `encrypt` 扩展：

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

加密密钥可以是 Fernet 密钥或任意字符串：

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

### TTL（存活时间）

设置加密项保持有效的时长：

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

## 与不同会话类型的用法

### 搭配 SQLite 会话

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

### 搭配 SQLAlchemy 会话

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

    当将 `EncryptedSession` 与高级会话实现（如 `AdvancedSQLiteSession`）一起使用时，请注意：

    - 由于消息内容已被加密，`find_turns_by_content()` 等方法将无法有效工作
    - 基于内容的检索会在加密数据上执行，其效果受限



## 密钥派生

EncryptedSession 使用 HKDF（基于 HMAC 的密钥派生函数）为每个会话派生唯一加密密钥：

- **主密钥**：你提供的加密密钥
- **会话盐值**：会话 ID
- **Info 字符串**：`"agents.session-store.hkdf.v1"`
- **输出**：32 字节的 Fernet 密钥

这可以确保：
- 每个会话都有唯一的加密密钥
- 没有主密钥无法派生出会话密钥
- 不同会话之间的数据无法相互解密

## 自动过期

当项目超过 TTL 时，在检索过程中会被自动跳过：

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

Agents SDK 提供内置的会话内存，可在多次智能体运行间自动维护对话历史，无需在轮次之间手动处理 `.to_input_list()`。

会话会为特定会话存储对话历史，让智能体无需显式手动管理内存即可保持上下文。这对构建聊天应用或多轮对话尤其有用，因为你希望智能体记住先前交互。

当你希望 SDK 为你管理客户端内存时，请使用会话。如果你已经在使用 OpenAI 通过 `conversation_id` 或 `previous_response_id` 管理的服务端状态，通常不需要再为同一对话使用会话。

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

如果某次运行因审批而暂停，请使用同一个会话实例（或另一个指向同一底层存储的会话实例）进行恢复，以便恢复后的轮次延续同一份已存储的对话历史。

```python
result = await Runner.run(agent, "Delete temporary files that are no longer needed.", session=session)

if result.interruptions:
    state = result.to_state()
    for interruption in result.interruptions:
        state.approve(interruption)
    result = await Runner.run(agent, state, session=session)
```

## 核心会话行为

启用会话内存后：

1. **每次运行前**: 运行器会自动检索该会话的对话历史，并将其预置到输入项前。
2. **每次运行后**: 运行期间生成的所有新项（用户输入、助手回复、工具调用等）都会自动存储到会话中。
3. **上下文保持**: 使用同一会话的每次后续运行都会包含完整对话历史，从而让智能体保持上下文。

这消除了在运行之间手动调用 `.to_input_list()` 并管理对话状态的需要。

## 控制历史记录与新输入的合并方式

当你传入会话时，运行器通常按以下方式准备模型输入：

1. 会话历史（从 `session.get_items(...)` 检索）
2. 当前轮次新输入

可使用 [`RunConfig.session_input_callback`][agents.run.RunConfig.session_input_callback] 在调用模型前自定义该合并步骤。该回调接收两个列表：

-   `history`: 检索到的会话历史（已标准化为输入项格式）
-   `new_input`: 当前轮次的新输入项

返回应发送给模型的最终输入项列表。

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

当你需要自定义裁剪、重排或选择性纳入历史，而不改变会话存储项方式时，可使用此功能。

## 限制检索历史记录

使用 [`SessionSettings`][agents.memory.SessionSettings] 控制每次运行前获取多少历史记录。

-   `SessionSettings(limit=None)`（默认）：检索所有可用会话项
-   `SessionSettings(limit=N)`：仅检索最近 `N` 个项

你可以通过 [`RunConfig.session_settings`][agents.run.RunConfig.session_settings] 按次运行应用：

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

如果你的会话实现暴露了默认会话设置，`RunConfig.session_settings` 会覆盖该次运行中所有非 `None` 的值。这对于长对话很有用，可在不改变会话默认行为的情况下限制检索大小。

## 内存操作

### 基本操作

会话支持多种用于管理对话历史的操作：

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

在阅读下方详细示例前，可先用此表选择起点。

| 会话类型 | 最适用场景 | 说明 |
| --- | --- | --- |
| `SQLiteSession` | 本地开发与简单应用 | 内置、轻量、支持文件或内存存储 |
| `AsyncSQLiteSession` | 搭配 `aiosqlite` 的异步 SQLite | 扩展后端，支持异步驱动 |
| `RedisSession` | 跨 worker/服务的共享内存 | 适合低延迟分布式部署 |
| `SQLAlchemySession` | 使用现有数据库的生产应用 | 适用于 SQLAlchemy 支持的数据库 |
| `OpenAIConversationsSession` | OpenAI 中的服务端托管存储 | 基于 OpenAI Conversations API 的历史记录 |
| `OpenAIResponsesCompactionSession` | 需要自动压缩的长对话 | 对另一会话后端的封装 |
| `AdvancedSQLiteSession` | SQLite + 分支/分析 | 功能更重；见专门页面 |
| `EncryptedSession` | 在另一会话之上提供加密 + TTL | 封装器；先选择底层后端 |

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

使用 `OpenAIResponsesCompactionSession` 通过 Responses API（`responses.compact`）压缩已存储的对话历史。它封装一个底层会话，并可基于 `should_trigger_compaction` 在每轮后自动压缩。不要将其包裹在 `OpenAIConversationsSession` 外层；这两种功能以不同方式管理历史记录。

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

`compaction_mode="previous_response_id"` 在你已使用 Responses API 的响应 ID 串联轮次时效果最佳。`compaction_mode="input"` 则改为基于当前会话项重建压缩请求；当响应链不可用或你希望会话内容成为事实来源时，这很有用。默认值 `"auto"` 会选择当前可用的最安全选项。

#### 自动压缩可能阻塞流式传输

压缩会清空并重写会话历史，因此 SDK 会等待压缩完成后才将运行视为完成。在流式模式下，如果压缩较重，这意味着 `run.stream_events()` 可能在最后一个输出 token 后仍保持打开数秒。

如果你希望低延迟流式传输或更快轮转，禁用自动压缩，并在轮次之间（或空闲时）自行调用 `run_compaction()`。你可以根据自己的标准决定何时强制压缩。

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

当你希望使用由 `aiosqlite` 支持持久化的 SQLite 时，使用 `AsyncSQLiteSession`。

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

使用 `RedisSession` 在多个 worker 或服务间共享会话内存。

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

使用任意 SQLAlchemy 支持数据库的生产级会话：

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

详细文档见 [SQLAlchemy 会话](sqlalchemy_session.md)。



### 高级 SQLite 会话

具备对话分支、用量分析和结构化查询能力的增强型 SQLite 会话：

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

详细文档见 [高级 SQLite 会话](advanced_sqlite_session.md)。

### 加密会话

适用于任意会话实现的透明加密封装：

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

详细文档见 [加密会话](encrypted_session.md)。

### 其他会话类型

还有更多内置选项。请参阅 `examples/memory/` 和 `extensions/memory/` 下的源代码。

## 运行模式

### 会话 ID 命名

使用有意义的会话 ID 以便组织对话：

-   基于用户：`"user_12345"`
-   基于线程：`"thread_abc123"`
-   基于上下文：`"support_ticket_456"`

### 内存持久化

-   对临时对话使用内存 SQLite（`SQLiteSession("session_id")`）
-   对持久对话使用文件 SQLite（`SQLiteSession("session_id", "path/to/db.sqlite")`）
-   当你需要基于 `aiosqlite` 的实现时，使用异步 SQLite（`AsyncSQLiteSession("session_id", db_path="...")`）
-   对共享、低延迟会话内存使用 Redis 支持的会话（`RedisSession.from_url("session_id", url="redis://...")`）
-   对使用 SQLAlchemy 支持的现有数据库的生产系统，使用 SQLAlchemy 驱动的会话（`SQLAlchemySession("session_id", engine=engine, create_tables=True)`）
-   对支持 30+ 数据库后端且内置遥测、追踪和数据隔离的生产云原生部署，使用 Dapr 状态存储会话（`DaprSession.from_address("session_id", state_store_name="statestore", dapr_address="localhost:50001")`）
-   当你希望将历史记录存储在 OpenAI Conversations API 中时，使用 OpenAI 托管存储（`OpenAIConversationsSession()`）
-   使用加密会话（`EncryptedSession(session_id, underlying_session, encryption_key)`）为任意会话添加透明加密和基于 TTL 的过期
-   可考虑为其他生产系统（例如 Django）实现自定义会话后端，以支持更高级用例

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

以下是一个展示会话内存实际效果的完整示例：

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

你可以通过创建遵循 [`Session`][agents.memory.session.Session] 协议的类来实现你自己的会话内存：

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

| Package | 描述 |
|---------|-------------|
| [openai-django-sessions](https://pypi.org/project/openai-django-sessions/) | 基于 Django ORM 的会话，适用于任何 Django 支持的数据库（PostgreSQL、MySQL、SQLite 等） |

如果你构建了会话实现，欢迎提交文档 PR 将其添加到这里！

## API 参考

详细 API 文档见：

-   [`Session`][agents.memory.session.Session] - 协议接口
-   [`OpenAIConversationsSession`][agents.memory.OpenAIConversationsSession] - OpenAI Conversations API 实现
-   [`OpenAIResponsesCompactionSession`][agents.memory.openai_responses_compaction_session.OpenAIResponsesCompactionSession] - Responses API 压缩封装
-   [`SQLiteSession`][agents.memory.sqlite_session.SQLiteSession] - 基础 SQLite 实现
-   [`AsyncSQLiteSession`][agents.extensions.memory.async_sqlite_session.AsyncSQLiteSession] - 基于 `aiosqlite` 的异步 SQLite 实现
-   [`RedisSession`][agents.extensions.memory.redis_session.RedisSession] - Redis 支持的会话实现
-   [`SQLAlchemySession`][agents.extensions.memory.sqlalchemy_session.SQLAlchemySession] - SQLAlchemy 驱动实现
-   [`DaprSession`][agents.extensions.memory.dapr_session.DaprSession] - Dapr 状态存储实现
-   [`AdvancedSQLiteSession`][agents.extensions.memory.advanced_sqlite_session.AdvancedSQLiteSession] - 带分支与分析能力的增强型 SQLite
-   [`EncryptedSession`][agents.extensions.memory.encrypt_session.EncryptedSession] - 适用于任意会话的加密封装

================
File: docs/zh/sessions/sqlalchemy_session.md
================
---
search:
  exclude: true
---
# SQLAlchemy 会话

`SQLAlchemySession` 使用 SQLAlchemy 提供一套可用于生产的会话实现，允许你将 SQLAlchemy 支持的任意数据库（PostgreSQL、MySQL、SQLite 等）用于会话存储。

## 安装

SQLAlchemy 会话需要安装 `sqlalchemy` 扩展：

```bash
pip install openai-agents[sqlalchemy]
```

## 快速开始

### 使用数据库 URL

最简单的用法：

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

### 使用已存在的 engine

适用于已有 SQLAlchemy engine 的应用：

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

智能体是应用中的核心构建模块。智能体是一个大语言模型（LLM），并配置了 instructions 和 tools。

## 基础配置

你将为智能体配置的最常见属性有：

-   `name`：用于标识智能体的必填字符串。
-   `instructions`：也称为开发者消息或系统提示词。
-   `model`：使用哪个 LLM，以及可选的 `model_settings` 用于配置模型调优参数，如 temperature、top_p 等。
-   `prompt`：在使用 OpenAI 的 Responses API 时，通过 id（及变量）引用提示词模板。
-   `tools`：智能体可用于完成任务的工具。
-   `mcp_servers`：为智能体提供工具的 MCP 服务。参见 [MCP 指南](mcp.md)。
-   `reset_tool_choice`：是否在一次工具调用后重置 `tool_choice`（默认：`True`）以避免工具使用循环。参见[强制使用工具](#forcing-tool-use)。

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

你可以通过设置 `prompt` 来引用在 OpenAI 平台中创建的提示词模板。这适用于使用 Responses API 的 OpenAI 模型。

要使用它，请：

1. 前往 https://platform.openai.com/playground/prompts
2. 创建一个新的提示词变量 `poem_style`。
3. 创建一个系统提示词，内容如下：

    ```
    Write a poem in {{poem_style}}
    ```

4. 使用 `--prompt-id` 参数运行示例。

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

智能体的 `context` 类型是通用的。上下文是一种依赖注入工具：它是你创建并传递给 `Runner.run()` 的对象，会被传递给每个智能体、工具、任务转移等，并作为智能体运行所需依赖和状态的集合。你可以提供任何 Python 对象作为上下文。

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

默认情况下，智能体会生成纯文本（即 `str`）输出。如果你希望智能体生成特定类型的输出，可以使用 `output_type` 参数。常见选择是使用 [Pydantic](https://docs.pydantic.dev/) 对象，但我们支持任何可被 Pydantic 的 [TypeAdapter](https://docs.pydantic.dev/latest/api/type_adapter/) 包装的类型——dataclasses、lists、TypedDict 等。

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

    当你传入 `output_type` 时，这会告诉模型使用[structured outputs](https://platform.openai.com/docs/guides/structured-outputs)，而不是常规纯文本响应。

## 多智能体系统设计模式

设计多智能体系统的方法有很多，但我们常见到两种广泛适用的模式：

1. 管理者（Agents as tools）：中心管理者/编排器将专用子智能体作为工具调用，并保留对对话的控制权。
2. 任务转移：对等智能体将控制权转移给专用智能体，由其接管对话。这是去中心化方式。

更多细节请参见[构建智能体实用指南](https://cdn.openai.com/business-guides-and-resources/a-practical-guide-to-building-agents.pdf)。

### 管理者（Agents as tools）

`customer_facing_agent` 负责所有用户交互，并调用以工具形式暴露的专用子智能体。更多信息请阅读 [tools](tools.md#agents-as-tools) 文档。

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

任务转移是智能体可委派的子智能体。发生任务转移时，被委派的智能体会接收对话历史并接管对话。该模式支持模块化、专用化的智能体，使其在单一任务上表现出色。更多信息请阅读 [handoffs](handoffs.md) 文档。

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

在大多数情况下，你可以在创建智能体时提供 instructions。不过，你也可以通过函数提供动态 instructions。该函数将接收智能体和上下文，并且必须返回提示词。普通函数和 `async` 函数都受支持。

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

有时你会希望观察智能体的生命周期。例如，你可能想在某些事件发生时记录日志、预取数据或记录用量。

有两个 hooks 作用域：

-   [`RunHooks`][agents.lifecycle.RunHooks] 观察整个 `Runner.run(...)` 调用，包括向其他智能体的任务转移。
-   [`AgentHooks`][agents.lifecycle.AgentHooks] 通过 `agent.hooks` 绑定到特定智能体实例。

回调上下文也会因事件不同而变化：

-   智能体开始/结束 hooks 接收 [`AgentHookContext`][agents.run_context.AgentHookContext]，它包装了你的原始上下文并携带共享的运行用量状态。
-   LLM、工具和任务转移 hooks 接收 [`RunContextWrapper`][agents.run_context.RunContextWrapper]。

典型 hooks 时机：

-   `on_agent_start` / `on_agent_end`：某个特定智能体开始或结束生成最终输出时。
-   `on_llm_start` / `on_llm_end`：每次模型调用的前后。
-   `on_tool_start` / `on_tool_end`：每次本地工具调用的前后。
-   `on_handoff`：控制权从一个智能体转移到另一个智能体时。

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

完整回调范围请参见[生命周期 API 参考](ref/lifecycle.md)。

## 安全防护措施

安全防护措施允许你在智能体运行的同时并行检查/验证用户输入，并在智能体输出生成后检查其输出。例如，你可以筛查用户输入和智能体输出是否相关。更多信息请阅读 [guardrails](guardrails.md) 文档。

## 克隆/复制智能体

通过在智能体上使用 `clone()` 方法，你可以复制一个 Agent，并可按需更改任意属性。

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

## 强制使用工具

提供工具列表并不总是意味着 LLM 会使用工具。你可以通过设置 [`ModelSettings.tool_choice`][agents.model_settings.ModelSettings.tool_choice] 来强制使用工具。有效值有：

1. `auto`，允许 LLM 决定是否使用工具。
2. `required`，要求 LLM 使用工具（但它可以智能决定使用哪个工具）。
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

`Agent` 配置中的 `tool_use_behavior` 参数用于控制如何处理工具输出：

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

- `StopAtTools(stop_at_tool_names=[...])`：如果调用了任一指定工具则停止，并将其输出作为最终响应。

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

- `ToolsToFinalOutputFunction`：自定义函数，用于处理工具结果并决定是停止还是继续调用 LLM。

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

    为防止无限循环，框架会在一次工具调用后自动将 `tool_choice` 重置为 "auto"。该行为可通过 [`agent.reset_tool_choice`][agents.agent.Agent.reset_tool_choice] 配置。之所以会出现无限循环，是因为工具结果会发送给 LLM，而 LLM 又由于 `tool_choice` 生成新的工具调用，如此无限重复。

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

上下文（Context）是一个含义很宽泛的术语。你可能会关注两类主要的上下文：

1. 你的代码在本地可用的上下文：这是在工具函数运行时、`on_handoff` 等回调期间、生命周期钩子中等场景可能需要的数据与依赖。
2. LLM 可用的上下文：这是 LLM 在生成响应时看到的数据。

## 本地上下文

这通过 [`RunContextWrapper`][agents.run_context.RunContextWrapper] 类以及其中的 [`context`][agents.run_context.RunContextWrapper.context] 属性来表示。其工作方式如下：

1. 你创建任意你想要的 Python 对象。常见模式是使用 dataclass 或 Pydantic 对象。
2. 你将该对象传给各种 run 方法（例如 `Runner.run(..., context=whatever)`）。
3. 你所有的工具调用、生命周期钩子等都会收到一个包装对象 `RunContextWrapper[T]`，其中 `T` 表示你的上下文对象类型；你可以通过 `wrapper.context` 访问它。

需要注意的**最重要**的一点是：对于一次给定的智能体运行，该运行中的每个智能体、工具函数、生命周期等都必须使用相同的上下文 _类型_。

你可以用上下文来做这些事情，例如：

-   运行的上下文数据（例如用户名/uid 或其他与用户相关的信息）
-   依赖（例如 logger 对象、数据获取器等）
-   辅助函数

!!! danger "注意"

    上下文对象**不会**发送给 LLM。它完全是一个本地对象，你可以从中读取、向其中写入并调用其方法。

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

1. 这是上下文对象。这里我们使用了 dataclass，但你可以使用任何类型。
2. 这是一个工具。你可以看到它接收 `RunContextWrapper[UserInfo]`。该工具实现会从上下文中读取数据。
3. 我们用泛型 `UserInfo` 标注该智能体，这样类型检查器就能捕获错误（例如，如果我们尝试传入一个接收不同上下文类型的工具）。
4. 上下文被传入 `run` 函数。
5. 该智能体正确调用工具并获取年龄。

---

### 高级：`ToolContext`

在某些情况下，你可能想访问正在执行的工具的额外元数据——例如工具名、调用 ID，或原始参数字符串。  
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
并额外提供当前工具调用特有的字段：

- `tool_name` – 被调用工具的名称  
- `tool_call_id` – 此次工具调用的唯一标识符  
- `tool_arguments` – 传给工具的原始参数字符串  

当你在执行期间需要工具级元数据时，使用 `ToolContext`。  
对于智能体与工具之间的一般上下文共享，`RunContextWrapper` 仍然足够。

---

## 智能体/LLM 上下文

当调用 LLM 时，它能看到的**唯一**数据来自对话历史。这意味着，如果你想让一些新数据对 LLM 可用，你必须以一种能让它出现在历史中的方式来做。实现方式有几种：

1. 你可以把它加入智能体的 `instructions`。这也被称为 “system prompt” 或 “developer message”。系统提示词可以是静态字符串，也可以是接收上下文并输出字符串的动态函数。这是针对始终有用的信息的常见策略（例如用户的名字或当前日期）。
2. 在调用 `Runner.run` 函数时，把它加入 `input`。这与 `instructions` 的策略类似，但允许你的消息在[指令优先级链](https://cdn.openai.com/spec/model-spec-2024-05-08.html#follow-the-chain-of-command)中处于更低位置。
3. 通过工具调用暴露它。这适用于 _按需_ 上下文——LLM 决定何时需要某些数据，并可以调用工具来获取这些数据。
4. 使用检索或网络检索。这些是特殊工具，能够从文件或数据库（检索）或从网络（网络检索）中获取相关数据。这有助于将响应“落地”到相关的上下文数据之上。

================
File: docs/zh/examples.md
================
---
search:
  exclude: true
---
# 代码示例

欢迎在 [repo](https://github.com/openai/openai-agents-python/tree/main/examples) 的代码示例部分查看 SDK 的多种示例实现。这些代码示例按多个目录组织，用于展示不同的模式与能力。

## 目录

-   **[agent_patterns](https://github.com/openai/openai-agents-python/tree/main/examples/agent_patterns):**
    此目录下的代码示例展示了常见的智能体设计模式，例如：

    -   确定性工作流
    -   Agents as tools
    -   并行智能体执行
    -   条件化工具使用
    -   输入/输出安全防护措施
    -   LLM 作为裁判
    -   路由
    -   流式传输安全防护措施

-   **[basic](https://github.com/openai/openai-agents-python/tree/main/examples/basic):**
    这些代码示例展示 SDK 的基础能力，例如：

    -   Hello world 代码示例（默认模型、GPT-5、开源权重模型）
    -   智能体生命周期管理
    -   动态系统提示词
    -   流式传输输出（文本、条目、函数调用参数）
    -   使用共享的跨轮次会话辅助工具进行 Responses websocket 传输（`examples/basic/stream_ws.py`）
    -   提示词模板
    -   文件处理（本地与远程、图片与 PDF）
    -   用量追踪
    -   非严格输出类型
    -   之前的 response ID 用法

-   **[customer_service](https://github.com/openai/openai-agents-python/tree/main/examples/customer_service):**
    面向航空公司的示例客服系统。

-   **[financial_research_agent](https://github.com/openai/openai-agents-python/tree/main/examples/financial_research_agent):**
    金融研究智能体，展示使用智能体与工具的结构化研究工作流，用于金融数据分析。

-   **[handoffs](https://github.com/openai/openai-agents-python/tree/main/examples/handoffs):**
    查看结合消息过滤的智能体任务转移实践代码示例。

-   **[hosted_mcp](https://github.com/openai/openai-agents-python/tree/main/examples/hosted_mcp):**
    展示如何使用托管的 MCP（Model Context Protocol）连接器与审批的代码示例。

-   **[mcp](https://github.com/openai/openai-agents-python/tree/main/examples/mcp):**
    学习如何使用 MCP（Model Context Protocol）构建智能体，包括：

    -   文件系统代码示例
    -   Git 代码示例
    -   MCP 提示词服务器代码示例
    -   SSE（Server-Sent Events）代码示例
    -   可流式 HTTP 代码示例

-   **[memory](https://github.com/openai/openai-agents-python/tree/main/examples/memory):**
    不同智能体记忆实现的代码示例，包括：

    -   SQLite 会话存储
    -   高级 SQLite 会话存储
    -   Redis 会话存储
    -   SQLAlchemy 会话存储
    -   加密会话存储
    -   OpenAI 会话存储

-   **[model_providers](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers):**
    探索如何在 SDK 中使用非 OpenAI 模型，包括自定义 provider 与 LiteLLM 集成。

-   **[realtime](https://github.com/openai/openai-agents-python/tree/main/examples/realtime):**
    展示如何使用 SDK 构建实时体验的代码示例，包括：

    -   Web 应用
    -   命令行界面
    -   Twilio 集成
    -   Twilio SIP 集成

-   **[reasoning_content](https://github.com/openai/openai-agents-python/tree/main/examples/reasoning_content):**
    展示如何使用推理内容与 structured outputs 的代码示例。

-   **[research_bot](https://github.com/openai/openai-agents-python/tree/main/examples/research_bot):**
    简易深度研究克隆项目，展示复杂的多智能体研究工作流。

-   **[tools](https://github.com/openai/openai-agents-python/tree/main/examples/tools):**
    学习如何实现 由OpenAI托管的工具 与实验性的 Codex 工具能力，例如：

    -   网络检索，以及带过滤器的网络检索
    -   文件检索
    -   Code Interpreter
    -   带内联技能的托管容器 shell（`examples/tools/container_shell_inline_skill.py`）
    -   带技能引用的托管容器 shell（`examples/tools/container_shell_skill_reference.py`）
    -   计算机操作
    -   图像生成
    -   实验性 Codex 工具工作流（`examples/tools/codex.py`）
    -   实验性 Codex 同线程工作流（`examples/tools/codex_same_thread.py`）

-   **[voice](https://github.com/openai/openai-agents-python/tree/main/examples/voice):**
    查看语音智能体的代码示例，使用我们的 TTS 与 STT 模型，包括流式语音代码示例。

================
File: docs/zh/guardrails.md
================
---
search:
  exclude: true
---
# 安全防护措施

安全防护措施使你能够对用户输入和智能体输出进行检查与验证。举例来说，假设你有一个智能体，它使用一个非常智能（因此也较慢/较昂贵）的模型来帮助处理客户请求。你不会希望恶意用户让模型帮他们做数学作业。因此，你可以用一个快速/便宜的模型运行安全防护措施。如果安全防护措施检测到恶意使用，它可以立即抛出错误并阻止昂贵模型运行，从而节省时间和成本（**在使用阻塞式安全防护措施时；对于并行安全防护措施，昂贵模型可能会在安全防护措施完成前就已开始运行。详情见下方“执行模式”**）。

安全防护措施有两种：

1. 输入安全防护措施：运行在初始用户输入上
2. 输出安全防护措施：运行在最终智能体输出上

## 输入安全防护措施

输入安全防护措施分 3 步运行：

1. 首先，安全防护措施接收与传给智能体相同的输入。
2. 接着，安全防护措施函数运行并产生一个 [`GuardrailFunctionOutput`][agents.guardrail.GuardrailFunctionOutput]，随后被包装为一个 [`InputGuardrailResult`][agents.guardrail.InputGuardrailResult]
3. 最后，我们检查 [`.tripwire_triggered`][agents.guardrail.GuardrailFunctionOutput.tripwire_triggered] 是否为 true。若为 true，则会抛出 [`InputGuardrailTripwireTriggered`][agents.exceptions.InputGuardrailTripwireTriggered] 异常，以便你适当地响应用户或处理该异常。

!!! Note

    输入安全防护措施用于处理用户输入，因此只有当该智能体是*第一个*智能体时，智能体上的安全防护措施才会运行。你可能会问，为什么 `guardrails` 属性放在智能体上，而不是传给 `Runner.run`？这是因为安全防护措施通常与实际的 Agent 相关——不同智能体会运行不同的安全防护措施，因此将代码放在一起有助于可读性。

### 执行模式

输入安全防护措施支持两种执行模式：

- **并行执行**（默认，`run_in_parallel=True`）：安全防护措施与智能体执行并发运行。由于二者同时开始，这可提供最佳延迟表现。但如果安全防护措施失败，智能体在被取消前可能已经消耗了 tokens 并执行了工具调用。

- **阻塞执行**（`run_in_parallel=False`）：安全防护措施会在智能体启动*之前*运行并完成。如果触发安全防护措施的跳闸条件，智能体将不会执行，从而避免 token 消耗和工具执行。这非常适合成本优化，以及你希望避免工具调用潜在副作用的场景。

## 输出安全防护措施

输出安全防护措施分 3 步运行：

1. 首先，安全防护措施接收智能体产生的输出。
2. 接着，安全防护措施函数运行并产生一个 [`GuardrailFunctionOutput`][agents.guardrail.GuardrailFunctionOutput]，随后被包装为一个 [`OutputGuardrailResult`][agents.guardrail.OutputGuardrailResult]
3. 最后，我们检查 [`.tripwire_triggered`][agents.guardrail.GuardrailFunctionOutput.tripwire_triggered] 是否为 true。若为 true，则会抛出 [`OutputGuardrailTripwireTriggered`][agents.exceptions.OutputGuardrailTripwireTriggered] 异常，以便你适当地响应用户或处理该异常。

!!! Note

    输出安全防护措施用于处理最终智能体输出，因此只有当该智能体是*最后一个*智能体时，智能体上的安全防护措施才会运行。与输入安全防护措施类似，我们这样做是因为安全防护措施通常与实际的 Agent 相关——不同智能体会运行不同的安全防护措施，因此将代码放在一起有助于可读性。

    输出安全防护措施总是在智能体完成后运行，因此不支持 `run_in_parallel` 参数。

## 工具安全防护措施

工具安全防护措施封装**工具调用**，让你在执行前后验证或拦截工具调用。它们配置在工具本身上，并在每次调用该工具时运行。

- 输入工具安全防护措施在工具执行前运行，可跳过调用、用一条消息替换输出，或触发跳闸异常。
- 输出工具安全防护措施在工具执行后运行，可替换输出或触发跳闸异常。
- 工具安全防护措施仅适用于通过 [`function_tool`][agents.function_tool] 创建的工具调用；托管工具（`WebSearchTool`、`FileSearchTool`、`HostedMCPTool`、`CodeInterpreterTool`、`ImageGenerationTool`）和内置执行工具（`ComputerTool`、`ShellTool`、`ApplyPatchTool`、`LocalShellTool`）不使用该安全防护流水线。

详见下方代码片段。

## 跳闸机制

如果输入或输出未通过安全防护措施，Guardrail 可通过 tripwire 发出信号。一旦我们发现某个安全防护措施已触发 tripwire，就会立即抛出 `{Input,Output}GuardrailTripwireTriggered` 异常并中止 Agent 执行。

## 安全防护措施实现

你需要提供一个接收输入并返回 [`GuardrailFunctionOutput`][agents.guardrail.GuardrailFunctionOutput] 的函数。在这个示例中，我们会通过在底层运行一个 Agent 来实现。

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

1. 我们将在安全防护措施函数中使用这个智能体。
2. 这是安全防护措施函数，接收智能体的输入/上下文并返回结果。
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
3. 这是安全防护措施函数，接收智能体输出并返回结果。
4. 这是真正定义工作流的智能体。

最后，以下是工具安全防护措施的示例。

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

任务转移允许一个智能体将任务委托给另一个智能体。这在不同智能体专注于不同领域的场景中特别有用。例如，一个客户支持应用可能会有多个智能体，分别专门处理订单状态、退款、常见问题等任务。

任务转移会作为工具呈现给 LLM。因此，如果有一个转移目标是名为 `Refund Agent` 的智能体，那么该工具会被命名为 `transfer_to_refund_agent`。

## 创建任务转移

所有智能体都有一个 [`handoffs`][agents.agent.Agent.handoffs] 参数，它既可以直接接收一个 `Agent`，也可以接收一个用于自定义任务转移的 `Handoff` 对象。

如果你传入的是普通的 `Agent` 实例，它们的 [`handoff_description`][agents.agent.Agent.handoff_description]（设置后）会附加到默认工具描述中。你可以用它来提示模型何时应选择该任务转移，而无需编写完整的 `handoff()` 对象。

你可以使用 Agents SDK 提供的 [`handoff()`][agents.handoffs.handoff] 函数来创建任务转移。该函数允许你指定要转移到的智能体，以及可选的覆盖项和输入过滤器。

### 基本用法

以下是创建一个简单任务转移的方式：

```python
from agents import Agent, handoff

billing_agent = Agent(name="Billing agent")
refund_agent = Agent(name="Refund agent")

# (1)!
triage_agent = Agent(name="Triage agent", handoffs=[billing_agent, handoff(refund_agent)])
```

1. 你可以直接使用智能体（如 `billing_agent`），也可以使用 `handoff()` 函数。

### 通过 `handoff()` 函数自定义任务转移

[`handoff()`][agents.handoffs.handoff] 函数可让你进行自定义。

-   `agent`：这是任务将被转移到的智能体。
-   `tool_name_override`：默认使用 `Handoff.default_tool_name()` 函数，解析为 `transfer_to_<agent_name>`。你可以覆盖它。
-   `tool_description_override`：覆盖来自 `Handoff.default_tool_description()` 的默认工具描述
-   `on_handoff`：当任务转移被调用时执行的回调函数。这对于在确认将触发任务转移时立即启动数据拉取等操作很有用。该函数接收智能体上下文，并且也可以选择接收由 LLM 生成的输入。输入数据由 `input_type` 参数控制。
-   `input_type`：任务转移期望的输入类型（可选）。
-   `input_filter`：它可让你过滤下一个智能体接收到的输入。详见下文。
-   `is_enabled`：任务转移是否启用。它可以是布尔值，也可以是返回布尔值的函数，从而允许你在运行时动态启用或禁用任务转移。
-   `nest_handoff_history`：对 RunConfig 级别 `nest_handoff_history` 设置的可选单次调用覆盖项。如果为 `None`，则改用当前运行配置中定义的值。

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

在某些情况下，你希望 LLM 在调用任务转移时提供一些数据。例如，设想一个转移到“升级处理智能体”的任务。你可能希望提供一个原因，以便记录日志。

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

## 输入过滤器

当任务转移发生时，就像新智能体接管了对话，并且可以看到完整的先前对话历史。如果你想改变这一点，可以设置 [`input_filter`][agents.handoffs.Handoff.input_filter]。输入过滤器是一个函数，它通过 [`HandoffInputData`][agents.handoffs.HandoffInputData] 接收现有输入，并且必须返回新的 `HandoffInputData`。

嵌套任务转移作为可选加入的 beta 功能提供，当前默认禁用，我们正在稳定该功能。当你启用 [`RunConfig.nest_handoff_history`][agents.run.RunConfig.nest_handoff_history] 时，运行器会将之前的对话记录折叠为一条 assistant 摘要消息，并将其包裹在 `<CONVERSATION HISTORY>` 块中；在同一次运行中发生多次任务转移时，该块会持续追加新的轮次。你可以通过 [`RunConfig.handoff_history_mapper`][agents.run.RunConfig.handoff_history_mapper] 提供自己的映射函数，以替换生成的消息，而无需编写完整的 `input_filter`。此可选加入机制仅在任务转移和运行都未提供显式 `input_filter` 时生效，因此已有自定义负载的现有代码（包括本仓库中的代码示例）无需更改即可保持当前行为。你还可以通过向 [`handoff(...)`][agents.handoffs.handoff] 传递 `nest_handoff_history=True` 或 `False` 来覆盖单个任务转移的嵌套行为，这会设置 [`Handoff.nest_handoff_history`][agents.handoffs.Handoff.nest_handoff_history]。如果你只需要更改生成摘要的包裹文本，可在运行智能体前调用 [`set_conversation_history_wrappers`][agents.handoffs.set_conversation_history_wrappers]（以及可选的 [`reset_conversation_history_wrappers`][agents.handoffs.reset_conversation_history_wrappers]）。

有一些常见模式（例如从历史中移除所有工具调用），我们已在 [`agents.extensions.handoff_filters`][] 中为你实现。

```python
from agents import Agent, handoff
from agents.extensions import handoff_filters

agent = Agent(name="FAQ agent")

handoff_obj = handoff(
    agent=agent,
    input_filter=handoff_filters.remove_all_tools, # (1)!
)
```

1. 当调用 `FAQ agent` 时，这将自动从历史中移除所有工具。

## 推荐提示词

为了确保 LLM 能正确理解任务转移，我们建议在你的智能体中加入有关任务转移的信息。我们在 [`agents.extensions.handoff_prompt.RECOMMENDED_PROMPT_PREFIX`][] 中提供了建议前缀，或者你可以调用 [`agents.extensions.handoff_prompt.prompt_with_handoff_instructions`][]，自动将推荐内容添加到你的提示词中。

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
# Human-in-the-loop

使用 human-in-the-loop（HITL）流程，在人员批准或拒绝敏感工具调用之前暂停智能体执行。工具会声明何时需要批准，运行结果会将待批准项作为中断呈现，而 `RunState` 让你可以在做出决定后序列化并恢复运行。

## 需要批准的工具标记

将 `needs_approval` 设为 `True` 可始终要求批准，或提供一个异步函数按每次调用决定。该可调用对象会接收运行上下文、解析后的工具参数以及工具调用 ID。

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

`needs_approval` 可用于 [`function_tool`][agents.tool.function_tool]、[`Agent.as_tool`][agents.agent.Agent.as_tool]、[`ShellTool`][agents.tool.ShellTool] 和 [`ApplyPatchTool`][agents.tool.ApplyPatchTool]。本地 MCP 服务也通过 [`MCPServerStdio`][agents.mcp.server.MCPServerStdio]、[`MCPServerSse`][agents.mcp.server.MCPServerSse] 和 [`MCPServerStreamableHttp`][agents.mcp.server.MCPServerStreamableHttp] 上的 `require_approval` 支持批准。托管 MCP 服务通过带有 `tool_config={"require_approval": "always"}` 的 [`HostedMCPTool`][agents.tool.HostedMCPTool] 支持批准，并可选提供 `on_approval_request` 回调。Shell 和 apply_patch 工具接受 `on_approval` 回调，如果你希望在不暴露中断的情况下自动批准或自动拒绝。

## 批准流程工作方式

1. 当模型发出工具调用时，runner 会评估 `needs_approval`。
2. 如果该工具调用的批准决定已存储在 [`RunContextWrapper`][agents.run_context.RunContextWrapper] 中（例如来自 `always_approve=True`），runner 会在不提示的情况下继续。按调用的批准仅作用于特定调用 ID；使用 `always_approve=True` 可自动允许后续调用。
3. 否则，执行会暂停，且 `RunResult.interruptions`（或 `RunResultStreaming.interruptions`）会包含 `ToolApprovalItem` 条目，其中含有 `agent.name`、`name` 和 `arguments` 等详细信息。
4. 使用 `result.to_state()` 将结果转换为 `RunState`，调用 `state.approve(...)` 或 `state.reject(...)`（可选传入 `always_approve` 或 `always_reject`），然后通过 `Runner.run(agent, state)` 或 `Runner.run_streamed(agent, state)` 恢复。
5. 恢复后的运行会从中断处继续；如果需要新的批准，将再次进入此流程。

## 示例：暂停、批准、恢复

下面的代码片段与 JavaScript HITL 指南一致：当工具需要批准时暂停，将状态持久化到磁盘，重新加载后在收集到决定后恢复。

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

在此示例中，`prompt_approval` 是同步的，因为它使用 `input()` 并通过 `run_in_executor(...)` 执行。如果你的批准来源本身已经是异步的（例如 HTTP 请求或异步数据库查询），你可以使用 `async def` 函数并直接 `await` 它。

若要在等待批准时进行流式输出，请调用 `Runner.run_streamed`，消费 `result.stream_events()` 直到完成，然后按上文所示执行相同的 `result.to_state()` 与恢复步骤。

## 仓库模式与代码示例

- **流式批准**：`examples/agent_patterns/human_in_the_loop_stream.py` 展示了如何消费 `stream_events()`，然后在用 `Runner.run_streamed(agent, state)` 恢复前批准待处理工具调用。
- **Agents as tools 批准**：当被委派的智能体任务需要审查时，`Agent.as_tool(..., needs_approval=...)` 应用相同的中断流程。
- **Shell 与 apply_patch 工具**：`ShellTool` 和 `ApplyPatchTool` 同样支持 `needs_approval`。使用 `state.approve(interruption, always_approve=True)` 或 `state.reject(..., always_reject=True)` 可为后续调用缓存决定。对于自动决策，提供 `on_approval`（见 `examples/tools/shell.py`）；对于手动决策，处理中断（见 `examples/tools/shell_human_in_the_loop.py`）。
- **本地 MCP 服务**：在 `MCPServerStdio` / `MCPServerSse` / `MCPServerStreamableHttp` 上使用 `require_approval` 来管控 MCP 工具调用（见 `examples/mcp/get_all_mcp_tools_example/main.py` 和 `examples/mcp/tool_filter_example/main.py`）。
- **托管 MCP 服务**：在 `HostedMCPTool` 上将 `require_approval` 设为 `"always"` 以强制 HITL，并可选提供 `on_approval_request` 以自动批准或拒绝（见 `examples/hosted_mcp/human_in_the_loop.py` 和 `examples/hosted_mcp/on_approval.py`）。对可信服务使用 `"never"`（`examples/hosted_mcp/simple.py`）。
- **会话与记忆**：将会话传给 `Runner.run`，使批准与对话历史可跨多轮保留。SQLite 和 OpenAI Conversations 会话变体位于 `examples/memory/memory_session_hitl_example.py` 和 `examples/memory/openai_session_hitl_example.py`。
- **Realtime 智能体**：实时演示暴露了 WebSocket 消息，可通过 `RealtimeSession` 上的 `approve_tool_call` / `reject_tool_call` 批准或拒绝工具调用（服务端处理器见 `examples/realtime/app/server.py`）。

## 长时间运行批准

`RunState` 设计为可持久化。使用 `state.to_json()` 或 `state.to_string()` 将待处理工作存储到数据库或队列中，并在之后通过 `RunState.from_json(...)` 或 `RunState.from_string(...)` 重新创建。

有用的序列化选项：

-   `context_serializer`：自定义非映射上下文对象的序列化方式。
-   `strict_context=True`：除非上下文已是映射，或你提供了合适的序列化器/反序列化器，否则在序列化或反序列化时失败。
-   `context_override`：加载状态时替换已序列化的上下文。当你不想恢复原始上下文对象时这很有用，但它不会从已序列化的负载中移除该上下文。
-   `include_tracing_api_key=True`：在你需要恢复后的工作继续使用相同凭据导出追踪时，在序列化的追踪负载中包含 tracing API key。

`RunState` 还会保留追踪元数据和由服务端管理的会话设置，因此恢复后的运行可以继续同一条追踪以及同一 `conversation_id` / `previous_response_id` 链。

## 待处理任务版本管理

如果批准可能会搁置一段时间，请在序列化状态旁存储你的智能体定义或 SDK 的版本标记。这样你就可以将反序列化路由到匹配的代码路径，避免在模型、提示词或工具定义变化时出现不兼容。

================
File: docs/zh/index.md
================
---
search:
  exclude: true
---
# OpenAI Agents SDK

[OpenAI Agents SDK](https://github.com/openai/openai-agents-python) 使你能够以一个轻量、易用且抽象极少的软件包来构建智能体式 AI 应用。它是我们此前面向智能体实验项目 [Swarm](https://github.com/openai/swarm/tree/main) 的生产就绪升级版。Agents SDK 仅包含一组非常精简的基本组件：

-   **智能体**，即配备了指令和工具的 LLM
-   **Agents as tools / 任务转移**，允许智能体将特定任务委派给其他智能体
-   **安全防护措施**，可对智能体输入与输出进行验证

结合 Python，这些基本组件足以表达工具与智能体之间的复杂关系，并让你无需陡峭的学习曲线就能构建真实世界应用。此外，SDK 内置了**追踪**能力，可用于可视化和调试你的智能体流程，也可用于评估流程，甚至为你的应用微调模型。

## 使用 Agents SDK 的原因

SDK 有两个核心设计原则：

1. 功能足够丰富，值得使用，同时基本组件足够精简，上手快速。
2. 开箱即用效果出色，同时你也可以精确自定义每一步行为。

以下是 SDK 的主要特性：

-   **智能体循环**：内置智能体循环，负责处理工具调用、将结果回传给 LLM，并持续执行直到任务完成。
-   **Python 优先**：使用语言内置能力进行智能体编排与链式连接，而无需学习新的抽象。
-   **Agents as tools / 任务转移**：一种强大的机制，用于在多个智能体之间协调并委派工作。
-   **安全防护措施**：与智能体执行并行运行输入验证与安全检查，并在检查不通过时快速失败。
-   **工具调用**：将任意 Python 函数转换为工具，并自动生成 schema，结合 Pydantic 提供验证能力。
-   **MCP 服务工具调用**：内置 MCP 服务工具集成，使用方式与工具调用一致。
-   **会话**：用于在智能体循环中维护工作上下文的持久化记忆层。
-   **人类参与回路**：内置机制，支持在智能体运行过程中引入人工参与。
-   **追踪**：内置追踪能力，用于工作流可视化、调试与监控，并支持 OpenAI 的评估、微调与蒸馏工具套件。
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

## 起步

-   使用 [Quickstart](quickstart.md) 构建你的第一个文本智能体。
-   然后在 [Running agents](running_agents.md#choose-a-memory-strategy) 中决定你希望如何在多轮之间传递状态。
-   如果你在任务转移与管理者式编排之间进行选择，请阅读 [智能体编排](multi_agent.md)。

## 路径选择

当你知道想完成的任务，但不确定该看哪一页时，可使用下表。

| 目标 | 从这里开始 |
| --- | --- |
| 构建第一个文本智能体并查看一次完整运行 | [Quickstart](quickstart.md) |
| 添加工具调用、托管工具或 agents as tools | [工具](tools.md) |
| 在任务转移与管理者式编排之间做选择 | [智能体编排](multi_agent.md) |
| 在多轮之间保留记忆 | [Running agents](running_agents.md#choose-a-memory-strategy) 和 [会话](sessions/index.md) |
| 使用 OpenAI 模型、websocket 传输或非 OpenAI 提供商 | [模型](models/index.md) |
| 查看输出、运行项、中断与恢复状态 | [结果](results.md) |
| 构建低延迟语音智能体 | [实时智能体快速入门](realtime/quickstart.md) |
| 构建 speech-to-text / 智能体 / text-to-speech 流水线 | [语音流水线快速入门](voice/quickstart.md) |

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

当你调用 `Runner.run` 方法时，你会得到以下之一：

-   如果调用 `run` 或 `run_sync`，得到 [`RunResult`][agents.result.RunResult]
-   如果调用 `run_streamed`，得到 [`RunResultStreaming`][agents.result.RunResultStreaming]

这两者都继承自 [`RunResultBase`][agents.result.RunResultBase]，其中包含了大多数有用信息。

## 该使用哪个结果属性

大多数应用只需要少数几个结果属性或辅助方法：

| 属性或辅助方法 | 在你需要以下内容时使用... |
| --- | --- |
| `final_output` | 展示给用户的最终答案。 |
| `to_input_list()` | 当你手动维护会话历史时，生成完整的下一轮输入列表。 |
| `new_items` | 包含智能体、工具和任务转移元数据的丰富运行项，用于日志、UI 或审计。 |
| `last_agent` | 通常应处理下一轮的智能体。 |
| `last_response_id` | 在下一次 OpenAI Responses 轮次中通过 `previous_response_id` 继续。 |
| `agent_tool_invocation` | 当结果来自 `Agent.as_tool()` 时，外层工具调用的元数据。 |
| `interruptions` | 在恢复前你必须处理的待定工具审批。 |
| `to_state()` | 用于暂停/恢复或持久化任务工作流的可序列化快照。 |

## 最终输出

[`final_output`][agents.result.RunResultBase.final_output] 属性包含最后一个运行的智能体的最终输出。它可能是：

-   `str`，如果最后一个智能体未定义 `output_type`
-   `last_agent.output_type` 类型的对象，如果该智能体定义了输出类型。

!!! note

    `final_output` 的类型是 `Any`。由于任务转移，我们无法对其进行静态类型标注。如果发生任务转移，任何 Agent 都可能是最后一个智能体，因此我们在静态上无法确定可能的输出类型集合。

## 下一轮输入

你可以使用 [`result.to_input_list()`][agents.result.RunResultBase.to_input_list] 将结果转换为输入列表，它会把你提供的原始输入与智能体运行期间生成的项拼接起来。这使得将一次智能体运行的输出传给下一次运行，或在循环中运行并每次追加新的用户输入，都更方便。

在实践中：

-   当你的应用手动维护完整会话记录时，使用 `result.to_input_list()`。
-   当你希望 SDK 为你加载和保存历史时，使用 [`session=...`](sessions/index.md)。
-   如果你使用带有 `conversation_id` 或 `previous_response_id` 的 OpenAI 服务端托管状态，通常只传入新的用户输入并复用已存储的 ID，而不是重新发送 `result.to_input_list()`。

## 最后一个智能体

[`last_agent`][agents.result.RunResultBase.last_agent] 属性包含最后一个运行的智能体。根据你的应用场景，这通常对用户下一次输入很有用。例如，如果你有一个前线分流智能体会转交给特定语言智能体，你可以存储这个最后的智能体，并在用户下一次发消息时复用它。

在流式传输模式下，[`RunResultStreaming.current_agent`][agents.result.RunResultStreaming.current_agent] 会随着运行进度更新，因此你可以在任务转移发生时实时观察。

## 新增项

[`new_items`][agents.result.RunResultBase.new_items] 属性包含运行期间新生成的项。这些项是 [`RunItem`][agents.items.RunItem]。运行项封装了由 LLM 生成的原始项。

-   [`MessageOutputItem`][agents.items.MessageOutputItem] 表示来自 LLM 的消息。原始项是生成的消息。
-   [`HandoffCallItem`][agents.items.HandoffCallItem] 表示 LLM 调用了任务转移工具。原始项是来自 LLM 的工具调用项。
-   [`HandoffOutputItem`][agents.items.HandoffOutputItem] 表示发生了任务转移。原始项是对任务转移工具调用的工具响应。你也可以从该项访问源/目标智能体。
-   [`ToolCallItem`][agents.items.ToolCallItem] 表示 LLM 调用了某个工具。
-   [`ToolCallOutputItem`][agents.items.ToolCallOutputItem] 表示某个工具已被调用。原始项是工具响应。你也可以从该项访问工具输出。
-   [`ReasoningItem`][agents.items.ReasoningItem] 表示来自 LLM 的推理项。原始项是生成的推理内容。

## 运行状态

当你需要运行的可序列化快照时，调用 [`result.to_state()`][agents.result.RunResult.to_state]。这是已完成或已暂停运行与后续恢复之间的桥梁，尤其适用于审批流程或持久化 worker 系统。

## Agent-as-tool 元数据

当结果来自嵌套的 [`Agent.as_tool()`][agents.agent.Agent.as_tool] 运行时，[`agent_tool_invocation`][agents.result.RunResultBase.agent_tool_invocation] 会暴露有关外层工具调用的不可变元数据：

-   `tool_name`
-   `tool_call_id`
-   `tool_arguments`

对于普通的顶层运行，`agent_tool_invocation` 为 `None`。

## 其他信息

### 安全防护措施结果

[`input_guardrail_results`][agents.result.RunResultBase.input_guardrail_results] 和 [`output_guardrail_results`][agents.result.RunResultBase.output_guardrail_results] 属性包含安全防护措施结果（如果有）。安全防护措施结果有时包含你希望记录或存储的有用信息，因此我们将其提供给你。

工具安全防护措施结果可分别通过 [`tool_input_guardrail_results`][agents.result.RunResultBase.tool_input_guardrail_results] 和 [`tool_output_guardrail_results`][agents.result.RunResultBase.tool_output_guardrail_results] 获取。这些安全防护措施可附加到工具上，并且这些工具调用会在智能体工作流期间执行相应的安全防护措施。

### 原始响应

[`raw_responses`][agents.result.RunResultBase.raw_responses] 属性包含由 LLM 生成的 [`ModelResponse`][agents.items.ModelResponse]。

### 原始输入

[`input`][agents.result.RunResultBase.input] 属性包含你提供给 `run` 方法的原始输入。在大多数情况下你不需要它，但在需要时可用。

### 中断与恢复运行

如果运行因工具审批而暂停，待审批项会在
[`RunResult.interruptions`][agents.result.RunResult.interruptions] 或
[`RunResultStreaming.interruptions`][agents.result.RunResultStreaming.interruptions] 中暴露。将
结果通过 `to_state()` 转换为 [`RunState`][agents.run_state.RunState]，批准或拒绝
中断项，然后使用 `Runner.run(...)` 或 `Runner.run_streamed(...)` 恢复运行。

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

[`RunResult`][agents.result.RunResult] 和
[`RunResultStreaming`][agents.result.RunResultStreaming] 都支持 `to_state()`。关于持久化的
审批工作流，请参阅 [human-in-the-loop 指南](human_in_the_loop.md)。

### 便捷辅助方法

`RunResultBase` 包含一些在生产流程中很有用的辅助方法/属性：

- [`final_output_as(...)`][agents.result.RunResultBase.final_output_as] 将最终输出转换为特定类型（可选运行时类型检查）。
- [`last_response_id`][agents.result.RunResultBase.last_response_id] 返回最新的模型响应 ID。当你希望在下一轮继续 OpenAI Responses API 链时，将其作为 `previous_response_id` 传回。
- [`agent_tool_invocation`][agents.result.RunResultBase.agent_tool_invocation] 当结果来自 `Agent.as_tool()` 时，返回外层工具调用的元数据。
- [`release_agents(...)`][agents.result.RunResultBase.release_agents] 在检查结果后，如需降低内存压力，可释放对智能体的强引用。

================
File: docs/zh/running_agents.md
================
---
search:
  exclude: true
---
# 运行智能体

你可以通过 [`Runner`][agents.run.Runner] 类运行智能体。你有 3 种选择：

1. [`Runner.run()`][agents.run.Runner.run]，以异步方式运行并返回一个 [`RunResult`][agents.result.RunResult]。
2. [`Runner.run_sync()`][agents.run.Runner.run_sync]，这是一个同步方法，底层仅调用 `.run()`。
3. [`Runner.run_streamed()`][agents.run.Runner.run_streamed]，以异步方式运行并返回一个 [`RunResultStreaming`][agents.result.RunResultStreaming]。它会以流式模式调用 LLM，并在收到事件时将其流式传递给你。

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

在[结果指南](results.md)中了解更多。

## Runner 生命周期与配置

### 智能体循环

当你在 `Runner` 中使用 run 方法时，需要传入一个起始智能体和输入。输入可以是：

-   一个字符串（视为用户消息），
-   OpenAI Responses API 格式的输入项列表，或
-   在恢复中断运行时传入一个 [`RunState`][agents.run_state.RunState]。

随后 runner 会运行一个循环：

1. 我们使用当前输入为当前智能体调用 LLM。
2. LLM 产生其输出。
    1. 如果 LLM 返回 `final_output`，循环结束并返回结果。
    2. 如果 LLM 执行了任务转移，我们会更新当前智能体和输入，然后重新运行循环。
    3. 如果 LLM 产生工具调用，我们会执行这些工具调用，附加结果，然后重新运行循环。
3. 如果超过传入的 `max_turns`，我们会抛出 [`MaxTurnsExceeded`][agents.exceptions.MaxTurnsExceeded] 异常。

!!! note

    判断 LLM 输出是否被视为“最终输出”的规则是：它产生了目标类型的文本输出，且没有工具调用。

### 流式传输

流式传输可让你在 LLM 运行时额外接收流式事件。流结束后，[`RunResultStreaming`][agents.result.RunResultStreaming] 将包含该次运行的完整信息，包括所有新生成的输出。你可以调用 `.stream_events()` 获取流式事件。更多信息见[流式传输指南](streaming.md)。

#### Responses WebSocket 传输（可选辅助）

如果你启用 OpenAI Responses websocket 传输，仍然可以继续使用常规的 `Runner` API。建议使用 websocket 会话辅助器以复用连接，但这不是必需的。

这是基于 websocket 传输的 Responses API，而不是 [Realtime API](realtime/guide.md)。

有关传输选择规则，以及具体模型对象或自定义 provider 的注意事项，请参见[模型](models/index.md#responses-websocket-transport)。

##### 模式 1：不使用会话辅助器（可用）

当你只需要 websocket 传输，而不需要 SDK 为你管理共享 provider/session 时使用。

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

此模式适合单次运行。如果你反复调用 `Runner.run()` / `Runner.run_streamed()`，除非你手动复用相同的 `RunConfig` / provider 实例，否则每次运行都可能重新连接。

##### 模式 2：使用 `responses_websocket_session()`（推荐用于多轮复用）

当你希望在多次运行间共享支持 websocket 的 provider 和 `RunConfig`（包括继承相同 `run_config` 的嵌套 Agents-as-tools 调用）时，使用 [`responses_websocket_session()`][agents.responses_websocket_session]。

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

在上下文退出前完成流式结果的消费。如果 websocket 请求仍在进行中就退出上下文，可能会强制关闭共享连接。

### 运行配置

`run_config` 参数允许你为智能体运行配置一些全局设置：

#### 常见运行配置目录

使用 `RunConfig` 可在不修改每个智能体定义的前提下，覆盖单次运行的行为。

##### 模型、provider 与会话默认值

-   [`model`][agents.run.RunConfig.model]：允许设置全局使用的 LLM 模型，不受每个 Agent 的 `model` 配置限制。
-   [`model_provider`][agents.run.RunConfig.model_provider]：用于查找模型名称的模型 provider，默认是 OpenAI。
-   [`model_settings`][agents.run.RunConfig.model_settings]：覆盖智能体特定设置。例如，你可以设置全局 `temperature` 或 `top_p`。
-   [`session_settings`][agents.run.RunConfig.session_settings]：在运行期间检索历史时覆盖会话级默认值（例如 `SessionSettings(limit=...)`）。
-   [`session_input_callback`][agents.run.RunConfig.session_input_callback]：使用 Sessions 时，自定义每轮前如何将新用户输入与会话历史合并。回调可为同步或异步。

##### 安全防护措施、任务转移与模型输入塑形

-   [`input_guardrails`][agents.run.RunConfig.input_guardrails], [`output_guardrails`][agents.run.RunConfig.output_guardrails]：在所有运行中包含的输入或输出安全防护措施列表。
-   [`handoff_input_filter`][agents.run.RunConfig.handoff_input_filter]：应用于所有任务转移的全局输入过滤器（若该任务转移尚未配置过滤器）。输入过滤器允许你编辑发送给新智能体的输入。更多细节见 [`Handoff.input_filter`][agents.handoffs.Handoff.input_filter] 文档。
-   [`nest_handoff_history`][agents.run.RunConfig.nest_handoff_history]：可选启用的 beta 功能，在调用下一个智能体前将先前转录折叠为一条 assistant 消息。默认禁用（我们仍在稳定嵌套任务转移）；设为 `True` 启用，或保持 `False` 以透传原始转录。所有 [Runner methods][agents.run.Runner] 在你未传入 `RunConfig` 时都会自动创建一个，因此快速开始和示例默认保持关闭，且显式的 [`Handoff.input_filter`][agents.handoffs.Handoff.input_filter] 回调仍会覆盖它。单个任务转移可通过 [`Handoff.nest_handoff_history`][agents.handoffs.Handoff.nest_handoff_history] 覆盖此设置。
-   [`handoff_history_mapper`][agents.run.RunConfig.handoff_history_mapper]：可选可调用对象；当你启用 `nest_handoff_history` 时，它会接收规范化转录（历史 + 任务转移项）。它必须返回要转发给下一个智能体的精确输入项列表，使你无需编写完整任务转移过滤器即可替换内置摘要。
-   [`call_model_input_filter`][agents.run.RunConfig.call_model_input_filter]：在模型调用前立即编辑完整准备好的模型输入（instructions 和输入项）的钩子，例如裁剪历史或注入系统提示词。
-   [`reasoning_item_id_policy`][agents.run.RunConfig.reasoning_item_id_policy]：控制 runner 在将先前输出转换为下一轮模型输入时，是否保留或省略 reasoning 项 ID。

##### 追踪与可观测性

-   [`tracing_disabled`][agents.run.RunConfig.tracing_disabled]：允许为整个运行禁用[追踪](tracing.md)。
-   [`tracing`][agents.run.RunConfig.tracing]：传入 [`TracingConfig`][agents.tracing.TracingConfig] 以覆盖本次运行的导出器、进程或追踪元数据。
-   [`trace_include_sensitive_data`][agents.run.RunConfig.trace_include_sensitive_data]：配置追踪中是否包含潜在敏感数据，例如 LLM 和工具调用的输入/输出。
-   [`workflow_name`][agents.run.RunConfig.workflow_name], [`trace_id`][agents.run.RunConfig.trace_id], [`group_id`][agents.run.RunConfig.group_id]：设置该次运行的追踪工作流名称、追踪 ID 和追踪组 ID。我们建议至少设置 `workflow_name`。group ID 是可选字段，可用于关联多次运行的追踪。
-   [`trace_metadata`][agents.run.RunConfig.trace_metadata]：包含在所有追踪中的元数据。

##### 工具审批与工具错误行为

-   [`tool_error_formatter`][agents.run.RunConfig.tool_error_formatter]：在审批流程中工具调用被拒绝时，自定义返回给模型的可见消息。

嵌套任务转移作为可选启用的 beta 功能提供。传入 `RunConfig(nest_handoff_history=True)` 可启用转录折叠行为，或设置 `handoff(..., nest_handoff_history=True)` 仅为特定任务转移启用。如果你希望保留原始转录（默认行为），请保持该标志未设置，或提供一个按需精确转发会话内容的 `handoff_input_filter`（或 `handoff_history_mapper`）。若要在不编写自定义 mapper 的情况下更改生成摘要使用的包装文本，可调用 [`set_conversation_history_wrappers`][agents.handoffs.set_conversation_history_wrappers]（并使用 [`reset_conversation_history_wrappers`][agents.handoffs.reset_conversation_history_wrappers] 恢复默认值）。

#### 运行配置细节

##### `tool_error_formatter`

使用 `tool_error_formatter`，可在审批流程中工具调用被拒绝时自定义返回给模型的消息。

格式化器会接收包含以下字段的 [`ToolErrorFormatterArgs`][agents.run_config.ToolErrorFormatterArgs]：

-   `kind`：错误类别。当前为 `"approval_rejected"`。
-   `tool_type`：工具运行时（`"function"`、`"computer"`、`"shell"` 或 `"apply_patch"`）。
-   `tool_name`：工具名称。
-   `call_id`：工具调用 ID。
-   `default_message`：SDK 默认的模型可见消息。
-   `run_context`：当前活动运行上下文包装器。

返回字符串可替换消息，返回 `None` 则使用 SDK 默认值。

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

`reasoning_item_id_policy` 控制当 runner 传递历史时（例如使用 `RunResult.to_input_list()` 或基于 session 的运行），如何将 reasoning 项转换为下一轮模型输入。

-   `None` 或 `"preserve"`（默认）：保留 reasoning 项 ID。
-   `"omit"`：从生成的下一轮输入中去除 reasoning 项 ID。

`"omit"` 主要用作一种可选缓解措施，针对某类 Responses API 400 错误：发送 reasoning 项时带有 `id`，但缺少必需的后续项（例如：`Item 'rs_...' of type 'reasoning' was provided without its required following item.`）。

这可能发生在多轮智能体运行中：SDK 从先前输出构建后续输入（包括 session 持久化、服务端管理的会话增量、流式/非流式后续轮次及恢复路径）时，若保留了 reasoning 项 ID，而 provider 要求该 ID 必须与对应后续项保持配对，就会触发。

设置 `reasoning_item_id_policy="omit"` 会保留 reasoning 内容，但去除 reasoning 项 `id`，从而避免在 SDK 生成的后续输入中触发该 API 不变式。

作用范围说明：

-   这只会影响 SDK 在构建后续输入时生成/转发的 reasoning 项。
-   不会改写用户提供的初始输入项。
-   在该策略应用后，`call_model_input_filter` 仍可有意重新引入 reasoning ID。

## 状态与会话管理

### 选择记忆策略

将状态传入下一轮通常有四种方式：

| 策略 | 状态存储位置 | 最适合 | 下一轮传入内容 |
| --- | --- | --- | --- |
| `result.to_input_list()` | 你的应用内存 | 小型聊天循环、完全手动控制、任意 provider | `result.to_input_list()` 返回的列表加上下一条用户消息 |
| `session` | 你的存储 + SDK | 持久聊天状态、可恢复运行、自定义存储 | 相同的 `session` 实例，或指向同一存储的另一个实例 |
| `conversation_id` | OpenAI Conversations API | 希望跨 worker 或服务共享的具名服务端会话 | 相同的 `conversation_id`，并且只传入新的用户轮次 |
| `previous_response_id` | OpenAI Responses API | 无需创建 conversation 资源的轻量服务端续接 | `result.last_response_id`，并且只传入新的用户轮次 |

`result.to_input_list()` 和 `session` 由客户端管理。`conversation_id` 和 `previous_response_id` 由 OpenAI 管理，且仅在你使用 OpenAI Responses API 时适用。在大多数应用中，每个会话选择一种持久化策略即可。除非你有意协调这两层，否则混用客户端管理历史和 OpenAI 管理状态可能导致上下文重复。

!!! note

    会话持久化不能与服务端管理会话设置
    （`conversation_id`、`previous_response_id` 或 `auto_previous_response_id`）
    在同一次运行中组合使用。每次调用请选择一种方式。

### 对话/聊天线程

调用任一 run 方法都可能导致一个或多个智能体运行（因此可能有一次或多次 LLM 调用），但它表示聊天会话中的单个逻辑轮次。例如：

1. 用户轮次：用户输入文本
2. Runner 运行：第一个智能体调用 LLM、运行工具、任务转移给第二个智能体，第二个智能体运行更多工具，然后产出输出。

在智能体运行结束时，你可以选择向用户展示什么。例如，你可以展示智能体生成的每个新项，或仅展示最终输出。无论哪种方式，用户随后都可能提出追问，此时你可以再次调用 run 方法。

#### 手动会话管理

你可以使用 [`RunResultBase.to_input_list()`][agents.result.RunResultBase.to_input_list] 方法手动管理会话历史，以获取下一轮输入：

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

#### 使用 Sessions 自动管理会话

更简单的方法是使用 [Sessions](sessions/index.md) 自动处理会话历史，而无需手动调用 `.to_input_list()`：

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

更多信息请参见 [Sessions 文档](sessions/index.md)。


#### 服务端管理会话

你也可以让 OpenAI 会话状态功能在服务端管理会话状态，而不是在本地通过 `to_input_list()` 或 `Sessions` 处理。这使你无需手动重发所有历史消息即可保留会话历史。使用下面任一服务端管理方式时，每次请求只传入新一轮输入，并复用已保存 ID。更多信息见 [OpenAI 会话状态指南](https://platform.openai.com/docs/guides/conversation-state?api-mode=responses)。

OpenAI 提供两种跨轮次跟踪状态的方式：

##### 1. 使用 `conversation_id`

你先通过 OpenAI Conversations API 创建一个会话，然后在后续每次调用中复用其 ID：

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

另一种方式是**响应链式连接**，即每一轮都显式链接到上一轮的 response ID。

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
SDK 会保留已保存的 `conversation_id` / `previous_response_id` / `auto_previous_response_id`
设置，从而使恢复后的轮次继续在同一个服务端管理会话中进行。

`conversation_id` 与 `previous_response_id` 互斥。若你希望使用可跨系统共享的具名会话资源，请用 `conversation_id`。若你希望使用最轻量的 Responses API 逐轮续接基础能力，请用 `previous_response_id`。

!!! note

    SDK 会自动重试 `conversation_locked` 错误并使用退避策略。在服务端管理
    会话运行中，它会在重试前回退内部会话跟踪器输入，以便可以干净地重发
    相同的已准备项。

    在本地基于 session 的运行中（不能与 `conversation_id`、
    `previous_response_id` 或 `auto_previous_response_id` 组合），SDK 也会尽力
    回滚最近持久化的输入项，以减少重试后出现重复历史条目。

## 钩子与自定义

### 模型调用输入过滤器

使用 `call_model_input_filter` 可在模型调用前编辑模型输入。该钩子会接收当前智能体、上下文和合并后的输入项（若存在 session 历史则包含在内），并返回新的 `ModelInputData`。

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

通过 `run_config` 为单次运行设置该钩子，可用于脱敏数据、裁剪过长历史或注入额外系统引导。

## 错误与恢复

### 错误处理器

所有 `Runner` 入口都接受 `error_handlers`，这是一个以错误类型为键的字典。当前支持的键为 `"max_turns"`。当你希望返回可控的最终输出而不是抛出 `MaxTurnsExceeded` 时使用它。

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

当你不希望将回退输出附加到会话历史时，设置 `include_in_history=False`。

## 持久执行集成与 human-in-the-loop

对于工具审批的暂停/恢复模式，请先阅读专门的[Human-in-the-loop 指南](human_in_the_loop.md)。
下面的集成用于持久化编排，适用于运行可能跨越长时间等待、重试或进程重启的场景。

### Temporal

你可以使用 Agents SDK 的 [Temporal](https://temporal.io/) 集成来运行可持久化、长时间运行的工作流，包括 human-in-the-loop 任务。查看 Temporal 与 Agents SDK 协作完成长时任务的演示[视频](https://www.youtube.com/watch?v=fFBZqzT4DD8)，并在[此处查看文档](https://github.com/temporalio/sdk-python/tree/main/temporalio/contrib/openai_agents)。 

### Restate

你可以使用 Agents SDK 的 [Restate](https://restate.dev/) 集成来构建轻量、可持久化的智能体，包括人工审批、任务转移和会话管理。该集成依赖 Restate 的单二进制运行时，并支持将智能体作为进程/容器或无服务器函数运行。
更多信息请阅读[概览](https://www.restate.dev/blog/durable-orchestration-for-ai-agents-with-restate-and-openai-sdk)或查看[文档](https://docs.restate.dev/ai)。

### DBOS

你可以使用 Agents SDK 的 [DBOS](https://dbos.dev/) 集成来运行可靠智能体，在故障和重启后仍能保留进度。它支持长时运行智能体、human-in-the-loop 工作流和任务转移。它同时支持同步和异步方法。该集成仅需 SQLite 或 Postgres 数据库。更多信息请查看该集成的 [repo](https://github.com/dbos-inc/dbos-openai-agents) 和[文档](https://docs.dbos.dev/integrations/openai-agents)。

## 异常

SDK 在某些情况下会抛出异常。完整列表见 [`agents.exceptions`][]。概览如下：

-   [`AgentsException`][agents.exceptions.AgentsException]：这是 SDK 内所有异常的基类，作为通用类型，其他更具体的异常均派生自它。
-   [`MaxTurnsExceeded`][agents.exceptions.MaxTurnsExceeded]：当智能体运行超过传给 `Runner.run`、`Runner.run_sync` 或 `Runner.run_streamed` 方法的 `max_turns` 限制时抛出。它表示智能体无法在指定交互轮次数内完成任务。
-   [`ModelBehaviorError`][agents.exceptions.ModelBehaviorError]：当底层模型（LLM）产生意外或无效输出时会出现此异常。包括：
    -   JSON 格式错误：当模型为工具调用或其直接输出提供了格式错误的 JSON 结构时，尤其是在定义了特定 `output_type` 的情况下。
    -   与工具相关的意外失败：当模型未按预期方式使用工具时
-   [`ToolTimeoutError`][agents.exceptions.ToolTimeoutError]：当工具调用超过其配置超时时间，且该工具使用 `timeout_behavior="raise_exception"` 时抛出此异常。
-   [`UserError`][agents.exceptions.UserError]：当你（使用 SDK 编写代码的人）在使用 SDK 时出现错误会抛出此异常。通常由代码实现错误、配置无效或误用 SDK API 导致。
-   [`InputGuardrailTripwireTriggered`][agents.exceptions.InputGuardrailTripwireTriggered], [`OutputGuardrailTripwireTriggered`][agents.exceptions.OutputGuardrailTripwireTriggered]：当输入安全防护措施或输出安全防护措施的触发条件分别满足时，会抛出此异常。输入安全防护措施在处理前检查传入消息，而输出安全防护措施在交付前检查智能体最终响应。

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
# 用量

Agents SDK 会自动跟踪每次运行的 token 用量。你可以从运行上下文中访问它，用于监控成本、实施限制或记录分析数据。

## 跟踪项

- **requests**: 发起的 LLM API 调用次数
- **input_tokens**: 发送的输入 token 总数
- **output_tokens**: 接收的输出 token 总数
- **total_tokens**: 输入 + 输出
- **request_usage_entries**: 每次请求的用量明细列表
- **details**:
  - `input_tokens_details.cached_tokens`
  - `output_tokens_details.reasoning_tokens`

## 运行用量访问

在执行 `Runner.run(...)` 之后，通过 `result.context_wrapper.usage` 访问用量。

```python
result = await Runner.run(agent, "What's the weather in Tokyo?")
usage = result.context_wrapper.usage

print("Requests:", usage.requests)
print("Input tokens:", usage.input_tokens)
print("Output tokens:", usage.output_tokens)
print("Total tokens:", usage.total_tokens)
```

用量会在该次运行期间的所有模型调用中聚合（包括工具调用和任务转移）。

### 在 LiteLLM 模型中启用用量统计

LiteLLM 提供商默认不报告用量指标。使用 [`LitellmModel`](models/litellm.md) 时，向你的智能体传入 `ModelSettings(include_usage=True)`，以便 LiteLLM 的响应填充 `result.context_wrapper.usage`。

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

## 按请求的用量跟踪

SDK 会在 `request_usage_entries` 中自动跟踪每个 API 请求的用量，便于进行细化的成本计算和监控上下文窗口的消耗。

```python
result = await Runner.run(agent, "What's the weather in Tokyo?")

for i, request in enumerate(result.context_wrapper.usage.request_usage_entries):
    print(f"Request {i + 1}: {request.input_tokens} in, {request.output_tokens} out")
```

## 使用会话访问用量

当你使用 `Session`（如 `SQLiteSession`）时，每次调用 `Runner.run(...)` 都会返回该次运行的用量。会话会维护用于上下文的对话历史，但每次运行的用量彼此独立。

```python
session = SQLiteSession("my_conversation")

first = await Runner.run(agent, "Hi!", session=session)
print(first.context_wrapper.usage.total_tokens)  # Usage for first run

second = await Runner.run(agent, "Can you elaborate?", session=session)
print(second.context_wrapper.usage.total_tokens)  # Usage for second run
```

请注意，尽管会话会在运行之间保留对话上下文，但每次 `Runner.run()` 返回的用量指标仅代表那一次执行。在会话中，之前的消息可能会作为输入重新注入到每次运行中，从而影响后续轮次的输入 token 数量。

## 在钩子中使用用量

如果你使用 `RunHooks`，传递给每个钩子的 `context` 对象包含 `usage`。这使你可以在关键生命周期时刻记录用量。

```python
class MyHooks(RunHooks):
    async def on_agent_end(self, context: RunContextWrapper, agent: Agent, output: Any) -> None:
        u = context.usage
        print(f"{agent.name} → {u.requests} requests, {u.total_tokens} total tokens")
```

## API 参考

详见：

- [`Usage`][agents.usage.Usage] - 用量跟踪数据结构
- [`RequestUsage`][agents.usage.RequestUsage] - 单次请求的用量详情
- [`RunContextWrapper`][agents.run.RunContextWrapper] - 从运行上下文访问用量
- [`RunHooks`][agents.run.RunHooks] - 挂接到用量跟踪生命周期

================
File: docs/zh/visualization.md
================
---
search:
  exclude: true
---
# 智能体可视化

智能体可视化可使用 **Graphviz** 生成智能体及其关系的结构化图形表示。这有助于理解智能体、工具与任务转移在应用中的交互方式。

## 安装

安装可选的 `viz` 依赖组：

```bash
pip install "openai-agents[viz]"
```

## 生成图

你可以使用 `draw_graph` 函数生成智能体可视化。该函数会创建一个有向图，其中：

- **智能体** 显示为黄色方框。
- **MCP 服务** 显示为灰色方框。
- **工具** 显示为绿色椭圆。
- **任务转移** 为从一个智能体到另一个智能体的有向边。

### 示例用法

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

![智能体图](../assets/images/graph.png)

这会生成一个图，直观展示 **分诊智能体** 的结构以及其与子智能体和工具的连接。


## 可视化解读

生成的图包含：

- 一个表示入口的 **起始节点**（`__start__`）。
- 用黄色填充、以**矩形**表示的智能体。
- 用绿色填充、以**椭圆**表示的工具。
- 用灰色填充、以**矩形**表示的 MCP 服务。
- 表示交互的有向边：
  - **实线箭头** 表示智能体之间的任务转移。
  - **点线箭头** 表示工具调用。
  - **虚线箭头** 表示 MCP 服务调用。
- 一个表示执行终止位置的 **结束节点**（`__end__`）。

**注意：** 在近期版本的 `agents` 包（已在 **v0.2.8** 验证）中会渲染 MCP 服务。如果你在可视化中没有看到 MCP 方框，请升级到最新版本。

## 图形自定义

### 显示图形
默认情况下，`draw_graph` 会内联显示图形。若要在单独窗口中显示，请编写以下内容：

```python
draw_graph(triage_agent).view()
```

### 保存图形
默认情况下，`draw_graph` 会内联显示图形。若要将其保存为文件，请指定文件名：

```python
draw_graph(triage_agent, filename="agent_graph")
```

这将在工作目录中生成 `agent_graph.png`。

================
File: docs/agents.md
================
# Agents

Agents are the core building block in your apps. An agent is a large language model (LLM), configured with instructions and tools.

## Basic configuration

The most common properties of an agent you'll configure are:

-   `name`: A required string that identifies your agent.
-   `instructions`: also known as a developer message or system prompt.
-   `model`: which LLM to use, and optional `model_settings` to configure model tuning parameters like temperature, top_p, etc.
-   `prompt`: Reference a prompt template by id (and variables) when using OpenAI's Responses API.
-   `tools`: Tools that the agent can use to achieve its tasks.
-   `mcp_servers`: MCP servers that provide tools to the agent. See the [MCP guide](mcp.md).
-   `reset_tool_choice`: Whether to reset `tool_choice` after a tool call (default: `True`) to avoid tool-use loops. See [Forcing tool use](#forcing-tool-use).

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

## Tool Use Behavior

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
For general context sharing between agents and tools, `RunContextWrapper` remains sufficient.

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
    -   Encrypted session storage
    -   OpenAI session storage

-   **[model_providers](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers):**
    Explore how to use non-OpenAI models with the SDK, including custom providers and LiteLLM integration.

-   **[realtime](https://github.com/openai/openai-agents-python/tree/main/examples/realtime):**
    Examples showing how to build real-time experiences using the SDK, including:

    -   Web applications
    -   Command-line interfaces
    -   Twilio integration
    -   Twilio SIP integration

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
- Tool guardrails apply only to function tools created with [`function_tool`][agents.function_tool]; hosted tools (`WebSearchTool`, `FileSearchTool`, `HostedMCPTool`, `CodeInterpreterTool`, `ImageGenerationTool`) and built-in execution tools (`ComputerTool`, `ShellTool`, `ApplyPatchTool`, `LocalShellTool`) do not use this guardrail pipeline.

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

### Basic Usage

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
-   `input_type`: The type of input expected by the handoff (optional).
-   `input_filter`: This lets you filter the input received by the next agent. See below for more.
-   `is_enabled`: Whether the handoff is enabled. This can be a boolean or a function that returns a boolean, allowing you to dynamically enable or disable the handoff at runtime.
-   `nest_handoff_history`: Optional per-call override for the RunConfig-level `nest_handoff_history` setting. If `None`, the value defined in the active run configuration is used instead.

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

## Input filters

When a handoff occurs, it's as though the new agent takes over the conversation, and gets to see the entire previous conversation history. If you want to change this, you can set an [`input_filter`][agents.handoffs.Handoff.input_filter]. An input filter is a function that receives the existing input via a [`HandoffInputData`][agents.handoffs.HandoffInputData], and must return a new `HandoffInputData`.

Nested handoffs are available as an opt-in beta and are disabled by default while we stabilize them. When you enable [`RunConfig.nest_handoff_history`][agents.run.RunConfig.nest_handoff_history], the runner collapses the prior transcript into a single assistant summary message and wraps it in a `<CONVERSATION HISTORY>` block that keeps appending new turns when multiple handoffs happen during the same run. You can provide your own mapping function via [`RunConfig.handoff_history_mapper`][agents.run.RunConfig.handoff_history_mapper] to replace the generated message without writing a full `input_filter`. The opt-in only applies when neither the handoff nor the run supplies an explicit `input_filter`, so existing code that already customizes the payload (including the examples in this repository) keeps its current behavior without changes. You can override the nesting behaviour for a single handoff by passing `nest_handoff_history=True` or `False` to [`handoff(...)`][agents.handoffs.handoff], which sets [`Handoff.nest_handoff_history`][agents.handoffs.Handoff.nest_handoff_history]. If you just need to change the wrapper text for the generated summary, call [`set_conversation_history_wrappers`][agents.handoffs.set_conversation_history_wrappers] (and optionally [`reset_conversation_history_wrappers`][agents.handoffs.reset_conversation_history_wrappers]) before running your agents.

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

1. When the model emits a tool call, the runner evaluates `needs_approval`.
2. If an approval decision for that tool call is already stored in the [`RunContextWrapper`][agents.run_context.RunContextWrapper] (for example, from `always_approve=True`), the runner proceeds without prompting. Per-call approvals are scoped to the specific call ID; use `always_approve=True` to allow future calls automatically.
3. Otherwise, execution pauses and `RunResult.interruptions` (or `RunResultStreaming.interruptions`) contains `ToolApprovalItem` entries with details such as `agent.name`, `name`, and `arguments`.
4. Convert the result to a `RunState` with `result.to_state()`, call `state.approve(...)` or `state.reject(...)` (optionally passing `always_approve` or `always_reject`), and then resume with `Runner.run(agent, state)` or `Runner.run_streamed(agent, state)`.
5. The resumed run continues where it left off and will re-enter this flow if new approvals are needed.

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
- **Agent as tool approvals**: `Agent.as_tool(..., needs_approval=...)` applies the same interruption flow when delegated agent tasks need review.
- **Shell and apply_patch tools**: `ShellTool` and `ApplyPatchTool` also support `needs_approval`. Use `state.approve(interruption, always_approve=True)` or `state.reject(..., always_reject=True)` to cache the decision for future calls. For automatic decisions, provide `on_approval` (see `examples/tools/shell.py`); for manual decisions, handle interruptions (see `examples/tools/shell_human_in_the_loop.py`).
- **Local MCP servers**: Use `require_approval` on `MCPServerStdio` / `MCPServerSse` / `MCPServerStreamableHttp` to gate MCP tool calls (see `examples/mcp/get_all_mcp_tools_example/main.py` and `examples/mcp/tool_filter_example/main.py`).
- **Hosted MCP servers**: Set `require_approval` to `"always"` on `HostedMCPTool` to force HITL, optionally providing `on_approval_request` to auto-approve or reject (see `examples/hosted_mcp/human_in_the_loop.py` and `examples/hosted_mcp/on_approval.py`). Use `"never"` for trusted servers (`examples/hosted_mcp/simple.py`).
- **Sessions and memory**: Pass a session to `Runner.run` so approvals and conversation history survive multiple turns. SQLite and OpenAI Conversations session variants are in `examples/memory/memory_session_hitl_example.py` and `examples/memory/openai_session_hitl_example.py`.
- **Realtime agents**: The realtime demo exposes WebSocket messages that approve or reject tool calls via `approve_tool_call` / `reject_tool_call` on the `RealtimeSession` (see `examples/realtime/app/server.py` for the server-side handlers).

## Long-running approvals

`RunState` is designed to be durable. Use `state.to_json()` or `state.to_string()` to store pending work in a database or queue and recreate it later with `RunState.from_json(...)` or `RunState.from_string(...)`.

Useful serialization options:

-   `context_serializer`: Customize how non-mapping context objects are serialized.
-   `strict_context=True`: Fail serialization or deserialization unless the context is already a
    mapping or you provide the appropriate serializer/deserializer.
-   `context_override`: Replace the serialized context when loading state. This is useful when you
    do not want to restore the original context object, but it does not remove that context from an
    already serialized payload.
-   `include_tracing_api_key=True`: Include the tracing API key in the serialized trace payload
    when you need resumed work to keep exporting traces with the same credentials.

`RunState` also preserves trace metadata and server-managed conversation settings, so a resumed run
can continue the same trace and the same `conversation_id` / `previous_response_id` chain.

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
| Build a low-latency voice agent | [Realtime agents quickstart](realtime/quickstart.md) |
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

When you call the `Runner.run` methods, you either get a:

-   [`RunResult`][agents.result.RunResult] if you call `run` or `run_sync`
-   [`RunResultStreaming`][agents.result.RunResultStreaming] if you call `run_streamed`

Both of these inherit from [`RunResultBase`][agents.result.RunResultBase], which is where most useful information is present.

## Which result property should I use?

Most applications only need a few result properties or helpers:

| Property or helper | Use it when you need... |
| --- | --- |
| `final_output` | The final answer to show the user. |
| `to_input_list()` | A full next-turn input list when you are manually carrying conversation history yourself. |
| `new_items` | Rich run items with agent, tool, and handoff metadata for logs, UIs, or audits. |
| `last_agent` | The agent that should usually handle the next turn. |
| `last_response_id` | Continuation with `previous_response_id` on the next OpenAI Responses turn. |
| `agent_tool_invocation` | Metadata about the outer tool call when this result came from `Agent.as_tool()`. |
| `interruptions` | Pending tool approvals you must resolve before resuming. |
| `to_state()` | A serializable snapshot for pause/resume or durable job workflows. |

## Final output

The [`final_output`][agents.result.RunResultBase.final_output] property contains the final output of the last agent that ran. This is either:

-   a `str`, if the last agent didn't have an `output_type` defined
-   an object of type `last_agent.output_type`, if the agent had an output type defined.

!!! note

    `final_output` is of type `Any`. We can't statically type this, because of handoffs. If handoffs occur, that means any Agent might be the last agent, so we don't statically know the set of possible output types.

## Inputs for the next turn

You can use [`result.to_input_list()`][agents.result.RunResultBase.to_input_list] to turn the result into an input list that concatenates the original input you provided, to the items generated during the agent run. This makes it convenient to take the outputs of one agent run and pass them into another run, or to run it in a loop and append new user inputs each time.

In practice:

-   Use `result.to_input_list()` when your application manually carries the entire conversation transcript.
-   Use [`session=...`](sessions/index.md) when you want the SDK to load and save history for you.
-   If you are using OpenAI server-managed state with `conversation_id` or `previous_response_id`, usually pass only the new user input and reuse the stored ID instead of resending `result.to_input_list()`.

## Last agent

The [`last_agent`][agents.result.RunResultBase.last_agent] property contains the last agent that ran. Depending on your application, this is often useful for the next time the user inputs something. For example, if you have a frontline triage agent that hands off to a language-specific agent, you can store the last agent, and re-use it the next time the user messages the agent.

In streaming mode, [`RunResultStreaming.current_agent`][agents.result.RunResultStreaming.current_agent] updates as the run progresses, so you can observe handoffs as they happen.

## New items

The [`new_items`][agents.result.RunResultBase.new_items] property contains the new items generated during the run. The items are [`RunItem`][agents.items.RunItem]s. A run item wraps the raw item generated by the LLM.

-   [`MessageOutputItem`][agents.items.MessageOutputItem] indicates a message from the LLM. The raw item is the message generated.
-   [`HandoffCallItem`][agents.items.HandoffCallItem] indicates that the LLM called the handoff tool. The raw item is the tool call item from the LLM.
-   [`HandoffOutputItem`][agents.items.HandoffOutputItem] indicates that a handoff occurred. The raw item is the tool response to the handoff tool call. You can also access the source/target agents from the item.
-   [`ToolCallItem`][agents.items.ToolCallItem] indicates that the LLM invoked a tool.
-   [`ToolCallOutputItem`][agents.items.ToolCallOutputItem] indicates that a tool was called. The raw item is the tool response. You can also access the tool output from the item.
-   [`ReasoningItem`][agents.items.ReasoningItem] indicates a reasoning item from the LLM. The raw item is the reasoning generated.

## Run state

Call [`result.to_state()`][agents.result.RunResult.to_state] when you need a serializable snapshot of the run. This is the bridge between a finished or paused run and a later resume, especially for approval flows or durable worker systems.

## Agent-as-tool metadata

When a result comes from a nested [`Agent.as_tool()`][agents.agent.Agent.as_tool] run, [`agent_tool_invocation`][agents.result.RunResultBase.agent_tool_invocation] exposes immutable metadata about the outer tool call:

-   `tool_name`
-   `tool_call_id`
-   `tool_arguments`

For ordinary top-level runs, `agent_tool_invocation` is `None`.

## Other information

### Guardrail results

The [`input_guardrail_results`][agents.result.RunResultBase.input_guardrail_results] and [`output_guardrail_results`][agents.result.RunResultBase.output_guardrail_results] properties contain the results of the guardrails, if any. Guardrail results can sometimes contain useful information you want to log or store, so we make these available to you.

Tool guardrail results are available separately as [`tool_input_guardrail_results`][agents.result.RunResultBase.tool_input_guardrail_results] and [`tool_output_guardrail_results`][agents.result.RunResultBase.tool_output_guardrail_results]. These guardrails can be attached to tools, and those tool calls execute the guardrails during the agent workflow.

### Raw responses

The [`raw_responses`][agents.result.RunResultBase.raw_responses] property contains the [`ModelResponse`][agents.items.ModelResponse]s generated by the LLM.

### Original input

The [`input`][agents.result.RunResultBase.input] property contains the original input you provided to the `run` method. In most cases you won't need this, but it's available in case you do.

### Interruptions and resuming runs

If a run pauses for tool approval, pending approvals are exposed in
[`RunResult.interruptions`][agents.result.RunResult.interruptions] or
[`RunResultStreaming.interruptions`][agents.result.RunResultStreaming.interruptions]. Convert the
result into a [`RunState`][agents.run_state.RunState] with `to_state()`, approve or reject the
interruption(s), and resume with `Runner.run(...)` or `Runner.run_streamed(...)`.

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

Both [`RunResult`][agents.result.RunResult] and
[`RunResultStreaming`][agents.result.RunResultStreaming] support `to_state()`. For durable
approval workflows, see the [human-in-the-loop guide](human_in_the_loop.md).

### Convenience helpers

`RunResultBase` includes a few helper methods/properties that are useful in production flows:

- [`final_output_as(...)`][agents.result.RunResultBase.final_output_as] casts final output to a specific type (optionally with runtime type checking).
- [`last_response_id`][agents.result.RunResultBase.last_response_id] returns the latest model response ID. Pass this back as `previous_response_id` when you want to continue an OpenAI Responses API chain on the next turn.
- [`agent_tool_invocation`][agents.result.RunResultBase.agent_tool_invocation] returns metadata about the outer tool call when the result comes from `Agent.as_tool()`.
- [`release_agents(...)`][agents.result.RunResultBase.release_agents] drops strong references to agents when you want to reduce memory pressure after inspecting results.

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

#### Automatic conversation management with Sessions

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

## API Reference

For detailed API documentation, see:

-   [`Usage`][agents.usage.Usage] - Usage tracking data structure
-   [`RequestUsage`][agents.usage.RequestUsage] - Per-request usage details
-   [`RunContextWrapper`][agents.run.RunContextWrapper] - Access usage from run context
-   [`RunHooks`][agents.run.RunHooks] - Hook into usage tracking lifecycle

================
File: docs/visualization.md
================
# Agent Visualization

Agent visualization allows you to generate a structured graphical representation of agents and their relationships using **Graphviz**. This is useful for understanding how agents, tools, and handoffs interact within an application.

## Installation

Install the optional `viz` dependency group:

```bash
pip install "openai-agents[viz]"
```

## Generating a Graph

You can generate an agent visualization using the `draw_graph` function. This function creates a directed graph where:

- **Agents** are represented as yellow boxes.
- **MCP Servers** are represented as grey boxes.
- **Tools** are represented as green ellipses.
- **Handoffs** are directed edges from one agent to another.

### Example Usage

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


## Understanding the Visualization

The generated graph includes:

- A **start node** (`__start__`) indicating the entry point.
- Agents represented as **rectangles** with yellow fill.
- Tools represented as **ellipses** with green fill.
- MCP Servers represented as **rectangles** with grey fill.
- Directed edges indicating interactions:
  - **Solid arrows** for agent-to-agent handoffs.
  - **Dotted arrows** for tool invocations.
  - **Dashed arrows** for MCP server invocations.
- An **end node** (`__end__`) indicating where execution terminates.

**Note:** MCP servers are rendered in recent versions of the
`agents` package (verified in **v0.2.8**). If you don’t see MCP boxes
in your visualization, upgrade to the latest release.

## Customizing the Graph

### Showing the Graph
By default, `draw_graph` displays the graph inline. To show the graph in a separate window, write the following:

```python
draw_graph(triage_agent).view()
```

### Saving the Graph
By default, `draw_graph` displays the graph inline. To save it as a file, specify a filename:

```python
draw_graph(triage_agent, filename="agent_graph")
```

This will generate `agent_graph.png` in the working directory.




================================================================
End of Codebase
================================================================
