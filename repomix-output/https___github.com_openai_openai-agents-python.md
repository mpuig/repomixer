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

Agents SDK 는 OpenAI 모델을 두 가지 형태로 기본 지원합니다:

-   **권장**: 새로운 [Responses API](https://platform.openai.com/docs/api-reference/responses) 를 사용해 OpenAI API 를 호출하는 [`OpenAIResponsesModel`][agents.models.openai_responses.OpenAIResponsesModel]
-   [Chat Completions API](https://platform.openai.com/docs/api-reference/chat) 를 사용해 OpenAI API 를 호출하는 [`OpenAIChatCompletionsModel`][agents.models.openai_chatcompletions.OpenAIChatCompletionsModel]

## OpenAI 모델

`Agent` 를 초기화할 때 모델을 지정하지 않으면 기본 모델이 사용됩니다. 현재 기본값은 호환성과 낮은 지연 시간을 위해 [`gpt-4.1`](https://platform.openai.com/docs/models/gpt-4.1) 입니다. 접근 권한이 있다면, 명시적인 `model_settings` 를 유지하면서 더 높은 품질을 위해 에이전트를 [`gpt-5.2`](https://platform.openai.com/docs/models/gpt-5.2) 로 설정하는 것을 권장합니다.

[`gpt-5.2`](https://platform.openai.com/docs/models/gpt-5.2) 같은 다른 모델로 전환하려면, 에이전트를 구성하는 방법이 두 가지 있습니다.

### 기본 모델

첫째, 커스텀 모델을 설정하지 않은 모든 에이전트에서 특정 모델을 일관되게 사용하려면, 에이전트를 실행하기 전에 `OPENAI_DEFAULT_MODEL` 환경 변수를 설정하세요.

```bash
export OPENAI_DEFAULT_MODEL=gpt-5.2
python3 my_awesome_agent.py
```

둘째, `RunConfig` 를 통해 실행(run) 단위의 기본 모델을 설정할 수 있습니다. 에이전트에 모델을 설정하지 않으면 이 실행의 모델이 사용됩니다.

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

이 방식으로 [`gpt-5.2`](https://platform.openai.com/docs/models/gpt-5.2) 같은 GPT-5.x 모델을 사용하면, SDK 가 기본 `ModelSettings` 를 적용합니다. 대부분의 사용 사례에서 가장 잘 동작하는 설정을 사용합니다. 기본 모델의 추론 노력(reasoning effort)을 조정하려면, 자체 `ModelSettings` 를 전달하세요:

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

더 낮은 지연 시간을 위해 `gpt-5.2` 와 함께 `reasoning.effort="none"` 을 사용하는 것을 권장합니다. gpt-4.1 계열( mini 및 nano 변형 포함)도 인터랙티브 에이전트 앱을 구축하는 데 여전히 견고한 선택지입니다.

#### 비 GPT-5 모델

커스텀 `model_settings` 없이 비 GPT-5 모델 이름을 전달하면, SDK 는 어떤 모델과도 호환되는 일반 `ModelSettings` 로 되돌아갑니다.

## 비 OpenAI 모델

[LiteLLM 통합](./litellm.md) 을 통해 대부분의 다른 비 OpenAI 모델을 사용할 수 있습니다. 먼저 litellm 의존성 그룹을 설치하세요:

```bash
pip install "openai-agents[litellm]"
```

그다음 `litellm/` 접두사를 사용해 [지원되는 모델](https://docs.litellm.ai/docs/providers) 중 아무 것이나 사용하세요:

```python
claude_agent = Agent(model="litellm/anthropic/claude-3-5-sonnet-20240620", ...)
gemini_agent = Agent(model="litellm/gemini/gemini-2.5-flash-preview-04-17", ...)
```

### 비 OpenAI 모델을 사용하는 다른 방법

다른 LLM 제공자를 3가지 추가 방식으로 통합할 수 있습니다(예시는 [여기](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/) 참고):

1. [`set_default_openai_client`][agents.set_default_openai_client] 는 `AsyncOpenAI` 인스턴스를 LLM 클라이언트로 전역에서 사용하려는 경우에 유용합니다. 이는 LLM 제공자가 OpenAI 호환 API 엔드포인트를 제공하고, `base_url` 과 `api_key` 를 설정할 수 있는 경우를 위한 것입니다. [examples/model_providers/custom_example_global.py](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/custom_example_global.py) 에서 구성 가능한 예시를 참고하세요.
2. [`ModelProvider`][agents.models.interface.ModelProvider] 는 `Runner.run` 레벨에 있습니다. 이를 통해 “이 실행에서 모든 에이전트에 대해 커스텀 모델 제공자를 사용”이라고 지정할 수 있습니다. [examples/model_providers/custom_example_provider.py](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/custom_example_provider.py) 에서 구성 가능한 예시를 참고하세요.
3. [`Agent.model`][agents.agent.Agent.model] 은 특정 Agent 인스턴스에서 모델을 지정할 수 있게 해줍니다. 이를 통해 서로 다른 에이전트에 대해 서로 다른 제공자를 혼합해 사용할 수 있습니다. [examples/model_providers/custom_example_agent.py](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/custom_example_agent.py) 에서 구성 가능한 예시를 참고하세요. 대부분의 사용 가능한 모델을 사용하는 쉬운 방법은 [LiteLLM 통합](./litellm.md) 입니다.

`platform.openai.com` 의 API 키가 없는 경우, `set_tracing_disabled()` 로 트레이싱을 비활성화하거나, [다른 트레이싱 프로세서](../tracing.md) 를 설정하는 것을 권장합니다.

!!! note

    이 예시들에서는 Chat Completions API/모델을 사용합니다. 대부분의 LLM 제공자가 아직 Responses API 를 지원하지 않기 때문입니다. LLM 제공자가 이를 지원한다면 Responses 를 사용하는 것을 권장합니다.

## 모델 혼합 사용

단일 워크플로 내에서 각 에이전트에 서로 다른 모델을 사용하고 싶을 수 있습니다. 예를 들어 트리아지에는 더 작고 빠른 모델을, 복잡한 작업에는 더 크고 더 유능한 모델을 사용할 수 있습니다. [`Agent`][agents.Agent] 를 구성할 때, 다음 중 하나로 특정 모델을 선택할 수 있습니다:

1. 모델 이름을 전달
2. 모델 이름 + 해당 이름을 Model 인스턴스로 매핑할 수 있는 [`ModelProvider`][agents.models.interface.ModelProvider] 를 전달
3. [`Model`][agents.models.interface.Model] 구현을 직접 제공

!!!note

    SDK 는 [`OpenAIResponsesModel`][agents.models.openai_responses.OpenAIResponsesModel] 과 [`OpenAIChatCompletionsModel`][agents.models.openai_chatcompletions.OpenAIChatCompletionsModel] 형태를 모두 지원하지만, 두 형태는 지원하는 기능과 도구 집합이 서로 다르므로 각 워크플로에서는 하나의 모델 형태만 사용하는 것을 권장합니다. 워크플로에서 모델 형태를 혼합해야 한다면, 사용 중인 모든 기능이 양쪽 모두에서 사용 가능한지 확인하세요.

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

1.  OpenAI 모델 이름을 직접 설정합니다.
2.  [`Model`][agents.models.interface.Model] 구현을 제공합니다.

에이전트에 사용되는 모델을 추가로 구성하려면, temperature 같은 선택적 모델 구성 매개변수를 제공하는 [`ModelSettings`][agents.models.interface.ModelSettings] 를 전달할 수 있습니다.

```python
from agents import Agent, ModelSettings

english_agent = Agent(
    name="English agent",
    instructions="You only speak English",
    model="gpt-4.1",
    model_settings=ModelSettings(temperature=0.1),
)
```

또한 OpenAI Responses API 를 사용할 때, [몇 가지 추가 선택 매개변수](https://platform.openai.com/docs/api-reference/responses/create) (예: `user`, `service_tier` 등)도 있습니다. 최상위 레벨에서 사용할 수 없다면 `extra_args` 를 사용해 함께 전달할 수 있습니다.

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

## 다른 LLM 제공자 사용 시 흔한 문제

### 트레이싱 클라이언트 오류 401

트레이싱 관련 오류가 발생한다면, 트레이스가 OpenAI 서버로 업로드되는데 OpenAI API 키가 없기 때문입니다. 이를 해결하는 방법은 세 가지입니다:

1. 트레이싱을 완전히 비활성화: [`set_tracing_disabled(True)`][agents.set_tracing_disabled]
2. 트레이싱용 OpenAI 키 설정: [`set_tracing_export_api_key(...)`][agents.set_tracing_export_api_key]. 이 API 키는 트레이스 업로드에만 사용되며, 반드시 [platform.openai.com](https://platform.openai.com/) 발급 키여야 합니다.
3. 비 OpenAI 트레이스 프로세서 사용. [트레이싱 문서](../tracing.md#custom-tracing-processors) 를 참고하세요.

### Responses API 지원

SDK 는 기본적으로 Responses API 를 사용하지만, 대부분의 다른 LLM 제공자는 아직 이를 지원하지 않습니다. 그 결과 404 같은 문제가 발생할 수 있습니다. 해결 방법은 두 가지입니다:

1. [`set_default_openai_api("chat_completions")`][agents.set_default_openai_api] 를 호출합니다. 이는 환경 변수로 `OPENAI_API_KEY` 와 `OPENAI_BASE_URL` 을 설정하는 경우에 동작합니다.
2. [`OpenAIChatCompletionsModel`][agents.models.openai_chatcompletions.OpenAIChatCompletionsModel] 을 사용합니다. 예시는 [여기](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/) 에 있습니다.

### structured outputs 지원

일부 모델 제공자는 [structured outputs](https://platform.openai.com/docs/guides/structured-outputs) 를 지원하지 않습니다. 이 경우 때때로 다음과 비슷한 오류가 발생합니다:

```

BadRequestError: Error code: 400 - {'error': {'message': "'response_format.type' : value is not one of the allowed values ['text','json_object']", 'type': 'invalid_request_error'}}

```

이는 일부 모델 제공자의 한계입니다. JSON 출력은 지원하지만, 출력에 사용할 `json_schema` 를 지정하는 것을 허용하지 않습니다. 이에 대한 수정 작업을 진행 중이지만, JSON schema 출력을 지원하는 제공자에 의존하는 것을 권장합니다. 그렇지 않으면 잘못된 형식의 JSON 때문에 앱이 자주 깨질 수 있습니다.

## 제공자 간 모델 혼합

모델 제공자 간 기능 차이를 인지해야 하며, 그렇지 않으면 오류가 발생할 수 있습니다. 예를 들어 OpenAI 는 structured outputs, 멀티모달 입력, 호스티드 파일 검색 및 웹 검색을 지원하지만, 많은 다른 제공자는 이러한 기능을 지원하지 않습니다. 다음 제한을 유의하세요:

-   이해하지 못하는 제공자에게 지원되지 않는 `tools` 를 보내지 마세요
-   텍스트 전용 모델을 호출하기 전에 멀티모달 입력을 필터링하세요
-   structured JSON 출력을 지원하지 않는 제공자는 때때로 유효하지 않은 JSON 을 생성할 수 있음을 유의하세요

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
# 가이드

이 가이드는 OpenAI Agents SDK의 실시간 기능을 사용하여 음성 지원 AI 에이전트를 구축하는 방법을 자세히 설명합니다.

!!! warning "Beta feature"
Realtime agents는 베타 상태입니다. 구현을 개선하는 과정에서 호환성 깨짐이 발생할 수 있습니다.

## 개요

실시간 에이전트는 오디오와 텍스트 입력을 실시간으로 처리하고 실시간 오디오로 응답하는 대화형 흐름을 제공합니다. OpenAI의 Realtime API와 지속적인 연결을 유지하여 낮은 지연의 자연스러운 음성 대화를 가능하게 하고, 인터럽션(중단 처리)도 우아하게 처리합니다.

## 아키텍처

### 핵심 구성 요소

실시간 시스템은 다음과 같은 주요 구성 요소로 이루어져 있습니다:

-   **RealtimeAgent**: instructions, tools, 핸드오프로 구성된 에이전트
-   **RealtimeRunner**: 구성을 관리합니다. `runner.run()`을 호출하여 세션을 얻을 수 있습니다
-   **RealtimeSession**: 단일 상호작용 세션입니다. 일반적으로 사용자가 대화를 시작할 때마다 하나를 생성하고 대화가 끝날 때까지 유지합니다
-   **RealtimeModel**: 기본 모델 인터페이스(일반적으로 OpenAI의 WebSocket 구현)

### 세션 흐름

일반적인 실시간 세션은 다음 흐름을 따릅니다:

1. instructions, tools, 핸드오프로 **RealtimeAgent 를 생성**합니다
2. 에이전트와 구성 옵션으로 **RealtimeRunner 를 설정**합니다
3. `await runner.run()`을 사용해 **세션을 시작**하고 RealtimeSession 을 반환받습니다
4. `send_audio()` 또는 `send_message()`를 사용해 **오디오 또는 텍스트 메시지**를 세션에 보냅니다
5. 세션을 반복(iterate)하며 **이벤트를 수신**합니다 - 오디오 출력, 전사, 도구 호출, 핸드오프, 에러 등의 이벤트가 포함됩니다
6. 사용자가 에이전트 말 중에 끼어들 때 **인터럽션(중단 처리)**을 처리합니다. 현재 오디오 생성이 자동으로 중지됩니다

세션은 대화 기록을 유지하고 실시간 모델과의 지속적인 연결을 관리합니다.

## 에이전트 구성

RealtimeAgent 는 일반적인 Agent 클래스와 유사하게 동작하지만 몇 가지 중요한 차이가 있습니다. 전체 API 세부 정보는 [`RealtimeAgent`][agents.realtime.agent.RealtimeAgent] API 레퍼런스를 참고하세요.

일반 에이전트와의 주요 차이점:

-   모델 선택은 에이전트 수준이 아닌 세션 수준에서 구성합니다
-   structured outputs 지원 없음 (`outputType`은 지원되지 않음)
-   음성은 에이전트별로 구성할 수 있지만 첫 번째 에이전트가 말하기 시작한 후에는 변경할 수 없음
-   도구, 핸드오프, instructions 등 다른 기능은 동일하게 동작

## 세션 구성

### 모델 설정

세션 구성으로 기본 실시간 모델 동작을 제어할 수 있습니다. 모델 이름(예: `gpt-realtime`), 음성 선택(alloy, echo, fable, onyx, nova, shimmer), 지원 모달리티(텍스트 및/또는 오디오)를 구성할 수 있습니다. 오디오 형식은 입력과 출력 모두에 대해 설정 가능하며, 기본값은 PCM16 입니다.

### 오디오 구성

오디오 설정은 세션이 음성 입력과 출력을 처리하는 방식을 제어합니다. Whisper 등의 모델을 사용한 입력 오디오 전사, 언어 기본값 설정, 도메인 특화 용어의 정확도를 높이기 위한 전사 프롬프트 제공이 가능합니다. 턴 감지 설정은 에이전트가 언제 응답을 시작/종료해야 하는지를 제어하며, 음성 활동 감지 임계값, 무음 지속 시간, 감지된 음성 주변 패딩 옵션을 제공합니다.

## 도구와 함수

### 도구 추가

일반 에이전트와 마찬가지로, 실시간 에이전트는 대화 중에 실행되는 함수 도구를 지원합니다:

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

핸드오프를 통해 특화된 에이전트 간에 대화를 전환할 수 있습니다.

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

## 이벤트 처리

세션은 세션 객체를 반복(iterate)하여 수신할 수 있는 이벤트를 스트리밍합니다. 이벤트에는 오디오 출력 청크, 전사 결과, 도구 실행 시작/종료, 에이전트 핸드오프, 에러가 포함됩니다. 처리해야 할 주요 이벤트는 다음과 같습니다:

-   **audio**: 에이전트 응답의 원문 오디오 데이터
-   **audio_end**: 에이전트 발화 종료
-   **audio_interrupted**: 사용자가 에이전트를 중단
-   **tool_start/tool_end**: 도구 실행 라이프사이클
-   **handoff**: 에이전트 핸드오프 발생
-   **error**: 처리 중 오류 발생

전체 이벤트 세부 정보는 [`RealtimeSessionEvent`][agents.realtime.events.RealtimeSessionEvent]를 참고하세요.

## 가드레일

실시간 에이전트는 출력 가드레일만 지원합니다. 성능 문제를 피하기 위해(매 단어마다가 아니라) 주기적으로 디바운스되어 실행됩니다. 기본 디바운스 길이는 100자이며, 이는 구성할 수 있습니다.

가드레일은 `RealtimeAgent` 에 직접 연결하거나 세션의 `run_config` 를 통해 제공할 수 있습니다. 두 소스의 가드레일은 함께 실행됩니다.

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

가드레일이 트리거되면 `guardrail_tripped` 이벤트를 생성하고 에이전트의 현재 응답을 인터럽트할 수 있습니다. 디바운스 동작은 안전성과 실시간 성능 요구 간의 균형을 맞추는 데 도움이 됩니다. 텍스트 에이전트와 달리, 실시간 에이전트는 가드레일이 트리거되어도 Exception 을 발생시키지 **않습니다**.

## 오디오 처리

[`session.send_audio(audio_bytes)`][agents.realtime.session.RealtimeSession.send_audio] 를 사용해 오디오를 세션으로 전송하거나, [`session.send_message()`][agents.realtime.session.RealtimeSession.send_message] 를 사용해 텍스트를 보냅니다.

오디오 출력의 경우 `audio` 이벤트를 수신하여 선호하는 오디오 라이브러리로 재생하세요. 사용자가 에이전트를 중단할 때 즉시 재생을 중지하고 대기 중인 오디오를 비우기 위해 `audio_interrupted` 이벤트를 반드시 수신하세요.

## SIP 연동

[Realtime Calls API](https://platform.openai.com/docs/guides/realtime-sip) 를 통해 들어오는 전화 통화에 실시간 에이전트를 연결할 수 있습니다. SDK는 SIP 상에서 미디어를 협상하면서 동일한 에이전트 흐름을 재사용하는 [`OpenAIRealtimeSIPModel`][agents.realtime.openai_realtime.OpenAIRealtimeSIPModel] 을 제공합니다.

이를 사용하려면 모델 인스턴스를 러너에 전달하고 세션 시작 시 SIP `call_id` 를 제공하세요. 콜 ID 는 수신 전화를 알리는 웹훅을 통해 전달됩니다.

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

발신자가 전화를 끊으면 SIP 세션이 종료되고 실시간 연결이 자동으로 닫힙니다. 완전한 전화 통신 code examples 는 [`examples/realtime/twilio_sip`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/twilio_sip) 를 참고하세요.

## 모델 직접 액세스

기저 모델에 접근하여 커스텀 리스너를 추가하거나 고급 작업을 수행할 수 있습니다:

```python
# Add a custom listener to the model
session.model.add_listener(my_custom_listener)
```

이를 통해 연결에 대한 더 낮은 수준의 제어가 필요한 고급 사용 사례를 위해 [`RealtimeModel`][agents.realtime.model.RealtimeModel] 인터페이스에 직접 접근할 수 있습니다.

## 코드 예제

완전한 동작 code examples 는 [examples/realtime 디렉터리](https://github.com/openai/openai-agents-python/tree/main/examples/realtime) 를 참고하세요. UI 구성 요소가 있는 데모와 없는 데모가 포함되어 있습니다.

================
File: docs/ko/realtime/quickstart.md
================
---
search:
  exclude: true
---
# 빠른 시작

실시간 에이전트는 OpenAI의 Realtime API를 사용하여 AI 에이전트와의 음성 대화를 가능하게 합니다. 이 가이드는 첫 실시간 음성 에이전트를 만드는 과정을 안내합니다.

!!! warning "베타 기능"
실시간 에이전트는 베타 상태입니다. 구현을 개선하는 과정에서 호환성에 영향을 주는 변경이 있을 수 있습니다.

## 사전 준비 사항

- Python 3.9 이상
- OpenAI API 키
- OpenAI Agents SDK 기본 지식

## 설치

아직 설치하지 않았다면 OpenAI Agents SDK를 설치하세요:

```bash
pip install openai-agents
```

## 첫 실시간 에이전트 만들기

### 1. 필수 컴포넌트 가져오기

```python
import asyncio
from agents.realtime import RealtimeAgent, RealtimeRunner
```

### 2. 실시간 에이전트 생성

```python
agent = RealtimeAgent(
    name="Assistant",
    instructions="You are a helpful voice assistant. Keep your responses conversational and friendly.",
)
```

### 3. 러너 설정

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

### 4. 세션 시작

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

## 전체 예제

전체 동작 예제는 다음과 같습니다:

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

## 구성 옵션

### 모델 설정

- `model_name`: 사용 가능한 실시간 모델에서 선택 (예: `gpt-realtime`)
- `voice`: 보이스 선택 (`alloy`, `echo`, `fable`, `onyx`, `nova`, `shimmer`)
- `modalities`: 텍스트 또는 오디오 활성화 (`["text"]` 또는 `["audio"]`)

### 오디오 설정

- `input_audio_format`: 입력 오디오 형식 (`pcm16`, `g711_ulaw`, `g711_alaw`)
- `output_audio_format`: 출력 오디오 형식
- `input_audio_transcription`: 전사 구성

### 턴 감지

- `type`: 감지 방식 (`server_vad`, `semantic_vad`)
- `threshold`: 음성 활동 임계값 (0.0-1.0)
- `silence_duration_ms`: 턴 종료를 감지하기 위한 무음 지속 시간
- `prefix_padding_ms`: 발화 전 오디오 패딩

## 다음 단계

- [실시간 에이전트 자세히 알아보기](guide.md)
- [examples/realtime](https://github.com/openai/openai-agents-python/tree/main/examples/realtime) 폴더의 동작하는 code examples 확인
- 에이전트에 도구 추가
- 에이전트 간 핸드오프 구현
- 안전을 위한 가드레일 설정

## 인증

환경에 OpenAI API 키가 설정되어 있는지 확인하세요:

```bash
export OPENAI_API_KEY="your-api-key-here"
```

또는 세션을 생성할 때 직접 전달하세요:

```python
session = await runner.run(model_config={"api_key": "your-api-key"})
```

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

Agents SDK 는 내장된 세션 메모리를 제공하여 여러 에이전트 실행에 걸쳐 대화 기록을 자동으로 유지하므로, 턴 사이에 `.to_input_list()` 를 수동으로 처리할 필요가 없습니다.

Sessions 는 특정 세션의 대화 기록을 저장하여, 에이전트가 명시적인 수동 메모리 관리 없이도 컨텍스트를 유지할 수 있게 합니다. 이는 이전 상호작용을 에이전트가 기억하도록 하고 싶은 채팅 애플리케이션이나 멀티턴 대화를 구축할 때 특히 유용합니다.

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

## 동작 방식

세션 메모리가 활성화되면:

1. **각 실행 전**: 러너가 해당 세션의 대화 기록을 자동으로 가져와 입력 항목 앞에 덧붙입니다
2. **각 실행 후**: 실행 중 생성된 모든 새 항목(사용자 입력, 어시스턴트 응답, 도구 호출 등)이 자동으로 세션에 저장됩니다
3. **컨텍스트 유지**: 동일한 세션으로 이후 실행할 때마다 전체 대화 기록이 포함되어, 에이전트가 컨텍스트를 유지할 수 있습니다

이로써 `.to_input_list()` 를 수동으로 호출하고 실행 간 대화 상태를 관리할 필요가 없어집니다.

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

### 수정에 pop_item 사용

`pop_item` 메서드는 대화에서 마지막 항목을 되돌리거나 수정하고 싶을 때 특히 유용합니다:

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

## 세션 유형

SDK 는 다양한 사용 사례를 위한 여러 세션 구현을 제공합니다:

### OpenAI Conversations API 세션

`OpenAIConversationsSession` 을 통해 [OpenAI's Conversations API](https://platform.openai.com/docs/api-reference/conversations) 를 사용합니다.

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

`OpenAIResponsesCompactionSession` 을 사용해 Responses API (`responses.compact`) 로 세션 기록을 압축합니다. 이는 기반 세션을 감싸며, `should_trigger_compaction` 에 따라 각 턴 이후 자동으로 압축할 수 있습니다.

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

기본적으로 후보 임계값에 도달하면 각 턴 이후 압축이 실행됩니다.

#### 자동 압축은 스트리밍을 차단할 수 있음

압축은 세션 기록을 지우고 다시 작성하므로, SDK 는 압축이 끝나야 실행이 완료된 것으로 간주합니다. 스트리밍 모드에서는 압축이 무거운 경우 마지막 출력 토큰 이후에도 `run.stream_events()` 가 몇 초 동안 열린 상태로 남을 수 있습니다.

낮은 지연의 스트리밍이나 빠른 턴 전환을 원한다면 자동 압축을 비활성화하고, 턴 사이(또는 유휴 시간)에 직접 `run_compaction()` 을 호출하세요. 자체 기준에 따라 언제 압축을 강제할지 결정할 수 있습니다.

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

SQLite 를 사용하는 기본 경량 세션 구현입니다:

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

### SQLAlchemy 세션

SQLAlchemy 가 지원하는 어떤 데이터베이스든 사용할 수 있는 프로덕션 준비 세션입니다:

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

자세한 문서는 [SQLAlchemy Sessions](sqlalchemy_session.md) 를 참고하세요.



### 고급 SQLite 세션

대화 브랜칭, 사용량 분석, structured 쿼리를 제공하는 강화된 SQLite 세션입니다:

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

자세한 문서는 [Advanced SQLite Sessions](advanced_sqlite_session.md) 를 참고하세요.

### 암호화 세션

어떤 세션 구현에도 적용할 수 있는 투명한 암호화 래퍼입니다:

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

자세한 문서는 [Encrypted Sessions](encrypted_session.md) 를 참고하세요.

### 기타 세션 유형

내장된 옵션이 몇 가지 더 있습니다. `examples/memory/` 및 `extensions/memory/` 아래의 소스 코드를 참고하세요.

## 세션 관리

### 세션 ID 네이밍

대화를 정리하는 데 도움이 되는 의미 있는 세션 ID 를 사용하세요:

-   사용자 기반: `"user_12345"`
-   스레드 기반: `"thread_abc123"`
-   컨텍스트 기반: `"support_ticket_456"`

### 메모리 영속성

-   임시 대화에는 인메모리 SQLite (`SQLiteSession("session_id")`) 를 사용하세요
-   영속적 대화에는 파일 기반 SQLite (`SQLiteSession("session_id", "path/to/db.sqlite")`) 를 사용하세요
-   SQLAlchemy 가 지원하는 기존 데이터베이스를 사용하는 프로덕션 시스템에는 SQLAlchemy 기반 세션 (`SQLAlchemySession("session_id", engine=engine, create_tables=True)`) 을 사용하세요
-   내장 텔레메트리, 트레이싱, 데이터 격리를 갖춘 30+ 데이터베이스 백엔드를 지원하는 프로덕션 클라우드 네이티브 배포에는 Dapr 상태 저장소 세션 (`DaprSession.from_address("session_id", state_store_name="statestore", dapr_address="localhost:50001")`) 을 사용하세요
-   기록을 OpenAI Conversations API 에 저장하고 싶다면 OpenAI 호스트하는 스토리지 (`OpenAIConversationsSession()`) 를 사용하세요
-   투명한 암호화 및 TTL 기반 만료를 위해 어떤 세션이든 감싸려면 암호화 세션 (`EncryptedSession(session_id, underlying_session, encryption_key)`) 을 사용하세요
-   더 고급 사용 사례를 위해 다른 프로덕션 시스템(Redis, Django 등)에 대한 커스텀 세션 백엔드를 구현하는 것도 고려하세요

### 여러 세션

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

다음은 세션 메모리가 실제로 동작하는 전체 예제입니다:

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

## 커스텀 세션 구현

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
| [openai-django-sessions](https://pypi.org/project/openai-django-sessions/) | Django 가 지원하는 어떤 데이터베이스(PostgreSQL, MySQL, SQLite 등)에도 사용할 수 있는 Django ORM 기반 세션 |

세션 구현을 만들었다면, 여기에 추가할 수 있도록 문서 PR 을 제출해 주세요!

## API Reference

자세한 API 문서는 다음을 참고하세요:

-   [`Session`][agents.memory.session.Session] - 프로토콜 인터페이스
-   [`OpenAIConversationsSession`][agents.memory.OpenAIConversationsSession] - OpenAI Conversations API 구현
-   [`OpenAIResponsesCompactionSession`][agents.memory.openai_responses_compaction_session.OpenAIResponsesCompactionSession] - Responses API 압축 래퍼
-   [`SQLiteSession`][agents.memory.sqlite_session.SQLiteSession] - 기본 SQLite 구현
-   [`SQLAlchemySession`][agents.extensions.memory.sqlalchemy_session.SQLAlchemySession] - SQLAlchemy 기반 구현
-   [`DaprSession`][agents.extensions.memory.dapr_session.DaprSession] - Dapr 상태 저장소 구현
-   [`AdvancedSQLiteSession`][agents.extensions.memory.advanced_sqlite_session.AdvancedSQLiteSession] - 브랜칭 및 분석을 포함한 강화된 SQLite
-   [`EncryptedSession`][agents.extensions.memory.encrypt_session.EncryptedSession] - 어떤 세션이든 적용 가능한 암호화 래퍼

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

[`VoicePipeline`][agents.voice.pipeline.VoicePipeline]은 에이전트 워크플로를 음성 앱으로 쉽게 전환할 수 있게 해주는 클래스입니다. 실행할 워크플로를 전달하면, 파이프라인이 입력 오디오의 음성 인식, 오디오 종료 시점 감지, 적절한 시점에 워크플로 호출, 워크플로 출력을 다시 오디오로 변환하는 작업을 처리합니다.

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

파이프라인을 생성할 때 다음을 설정할 수 있습니다:

1. [`workflow`][agents.voice.workflow.VoiceWorkflowBase]: 새 오디오가 음성 인식될 때마다 실행되는 코드
2. 사용되는 [`speech-to-text`][agents.voice.model.STTModel] 및 [`text-to-speech`][agents.voice.model.TTSModel] 모델
3. [`config`][agents.voice.pipeline_config.VoicePipelineConfig]: 다음과 같은 항목을 구성
    - 모델 공급자(모델 이름을 모델에 매핑)
    - 트레이싱(트레이싱 비활성화 여부, 오디오 파일 업로드 여부, 워크플로 이름, trace IDs 등)
    - TTS 및 STT 모델에 대한 설정(프롬프트, 언어, 사용되는 데이터 타입 등)

## 파이프라인 실행

[`run()`][agents.voice.pipeline.VoicePipeline.run] 메서드를 통해 파이프라인을 실행할 수 있으며, 두 가지 형태의 오디오 입력을 전달할 수 있습니다:

1. [`AudioInput`][agents.voice.input.AudioInput]: 전체 오디오 전사를 가지고 있고 그에 대한 결과만 생성하면 될 때 사용합니다. 이는 화자가 말을 마치는 시점을 감지할 필요가 없는 경우(예: 사전 녹음된 오디오, 사용자가 말하기를 마치는 시점이 명확한 푸시‑투‑토크 앱) 유용합니다
2. [`StreamedAudioInput`][agents.voice.input.StreamedAudioInput]: 사용자가 말을 마치는 시점을 감지해야 할 수 있을 때 사용합니다. 감지되는 대로 오디오 청크를 푸시할 수 있으며, 음성 파이프라인은 "activity detection(활동 감지)"이라고 하는 프로세스를 통해 적절한 시점에 에이전트 워크플로를 자동으로 실행합니다

## 결과

음성 파이프라인 실행 결과는 [`StreamedAudioResult`][agents.voice.result.StreamedAudioResult]입니다. 이는 발생하는 이벤트를 스트리밍할 수 있는 객체입니다. 다음과 같은 여러 종류의 [`VoiceStreamEvent`][agents.voice.events.VoiceStreamEvent]가 있습니다:

1. [`VoiceStreamEventAudio`][agents.voice.events.VoiceStreamEventAudio]: 오디오 청크를 포함
2. [`VoiceStreamEventLifecycle`][agents.voice.events.VoiceStreamEventLifecycle]: 턴 시작/종료 같은 라이프사이클 이벤트를 알림
3. [`VoiceStreamEventError`][agents.voice.events.VoiceStreamEventError]: 오류 이벤트

```python

result = await pipeline.run(input)

async for event in result.stream():
    if event.type == "voice_stream_event_audio":
        # play audio
    elif event.type == "voice_stream_event_lifecycle":
        # lifecycle
    elif event.type == "voice_stream_event_error"
        # error
    ...
```

## 모범 사례

### 인터럽션(중단 처리)

Agents SDK 는 현재 [`StreamedAudioInput`][agents.voice.input.StreamedAudioInput]에 대한 내장 인터럽션 지원을 제공하지 않습니다. 대신 감지된 각 턴마다 워크플로의 별도 실행을 트리거합니다. 애플리케이션 내부에서 인터럽션을 처리하려면 [`VoiceStreamEventLifecycle`][agents.voice.events.VoiceStreamEventLifecycle] 이벤트를 수신하면 됩니다. `turn_started`는 새 턴이 전사되어 처리가 시작되었음을 나타냅니다. `turn_ended`는 해당 턴에 대한 모든 오디오가 전송된 후에 트리거됩니다. 모델이 턴을 시작할 때 화자의 마이크를 음소거하고, 해당 턴의 관련 오디오를 모두 전송한 후 음소거를 해제하는 데 이러한 이벤트를 사용할 수 있습니다.

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

[에이전트 트레이싱](../tracing.md)과 마찬가지로, 보이스 파이프라인도 자동으로 트레이싱됩니다.

기본적인 트레이싱 정보는 위 문서를 참고하시고, 추가로 [`VoicePipelineConfig`][agents.voice.pipeline_config.VoicePipelineConfig]를 통해 파이프라인의 트레이싱을 구성할 수 있습니다.

주요 트레이싱 관련 필드는 다음과 같습니다:

-   [`tracing_disabled`][agents.voice.pipeline_config.VoicePipelineConfig.tracing_disabled]: 트레이싱 비활성화 여부를 제어합니다. 기본값은 트레이싱 활성화입니다
-   [`trace_include_sensitive_data`][agents.voice.pipeline_config.VoicePipelineConfig.trace_include_sensitive_data]: 오디오 전사와 같은 민감할 수 있는 데이터를 트레이스에 포함할지 제어합니다. 이는 보이스 파이프라인에만 적용되며, Workflow 내부에서 발생하는 내용에는 적용되지 않습니다
-   [`trace_include_sensitive_audio_data`][agents.voice.pipeline_config.VoicePipelineConfig.trace_include_sensitive_audio_data]: 트레이스에 오디오 데이터를 포함할지 제어합니다
-   [`workflow_name`][agents.voice.pipeline_config.VoicePipelineConfig.workflow_name]: 트레이스 워크플로 이름입니다
-   [`group_id`][agents.voice.pipeline_config.VoicePipelineConfig.group_id]: 트레이스의 `group_id`로, 여러 트레이스를 연결할 수 있게 합니다
-   [`trace_metadata`][agents.voice.pipeline_config.VoicePipelineConfig.tracing_disabled]: 트레이스에 포함할 추가 메타데이터입니다

================
File: docs/ko/agents.md
================
---
search:
  exclude: true
---
# 에이전트

에이전트는 앱의 핵심 구성 요소입니다. 에이전트는 instructions 및 tools로 구성된 대규모 언어 모델(LLM)입니다.

## 기본 구성

에이전트를 구성할 때 가장 흔히 설정하는 속성은 다음과 같습니다:

-   `name`: 에이전트를 식별하는 필수 문자열입니다
-   `instructions`: 개발자 메시지 또는 시스템 프롬프트로도 알려져 있습니다
-   `model`: 사용할 LLM, 그리고 temperature, top_p 등과 같은 모델 튜닝 매개변수를 구성하기 위한 선택적 `model_settings`
-   `prompt`: OpenAI의 Responses API를 사용할 때 id(및 변수)로 프롬프트 템플릿을 참조합니다
-   `tools`: 작업을 달성하기 위해 에이전트가 사용할 수 있는 도구입니다
-   `mcp_servers`: 에이전트에 도구를 제공하는 MCP 서버입니다. [MCP 가이드](mcp.md)를 참고하세요
-   `reset_tool_choice`: 도구 호출 이후 `tool_choice`를 재설정할지 여부(기본값: `True`)로, 도구 사용 루프를 방지합니다. [도구 사용 강제](#forcing-tool-use)를 참고하세요

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

`prompt`를 설정하면 OpenAI 플랫폼에서 생성한 프롬프트 템플릿을 참조할 수 있습니다. 이는 Responses API를 사용하는 OpenAI 모델에서 동작합니다.

사용하려면 다음을 수행하세요:

1. https://platform.openai.com/playground/prompts 로 이동합니다
2. 새 프롬프트 변수 `poem_style`을 생성합니다
3. 다음 내용을 가진 시스템 프롬프트를 생성합니다:

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

실행 시점에 프롬프트를 동적으로 생성할 수도 있습니다:

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

에이전트는 `context` 타입에 대해 제네릭합니다. 컨텍스트는 의존성 주입 도구입니다. 즉, `Runner.run()`에 생성해 전달하는 객체이며, 모든 에이전트, 도구, 핸드오프 등에 전달되고, 에이전트 실행을 위한 의존성과 상태를 담는 잡동사니 가방 역할을 합니다. 컨텍스트로는 어떤 Python 객체든 제공할 수 있습니다.

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

기본적으로 에이전트는 일반 텍스트(즉 `str`) 출력을 생성합니다. 에이전트가 특정 타입의 출력을 생성하게 하려면 `output_type` 매개변수를 사용할 수 있습니다. 흔한 선택은 [Pydantic](https://docs.pydantic.dev/) 객체이지만, Pydantic의 [TypeAdapter](https://docs.pydantic.dev/latest/api/type_adapter/)로 감쌀 수 있는 타입이라면 무엇이든 지원합니다. 예: dataclasses, lists, TypedDict 등

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

    `output_type`을 전달하면, 모델이 일반적인 평문 응답 대신 [structured outputs](https://platform.openai.com/docs/guides/structured-outputs)를 사용하도록 지시하게 됩니다.

## 멀티 에이전트 시스템 설계 패턴

멀티‑에이전트 시스템을 설계하는 방법은 많지만, 일반적으로 다음의 두 가지 폭넓게 적용 가능한 패턴을 자주 봅니다:

1. Manager (agents as tools): 중앙 관리자/오케스트레이터가 전문화된 하위 에이전트를 도구로 호출하고 대화의 제어권을 유지합니다
2. handoffs: 동등한 에이전트들이 전문화된 에이전트에게 제어권을 핸드오프하여, 그 에이전트가 대화를 이어받습니다. 이는 분산형입니다

자세한 내용은 [에이전트 구축 실전 가이드](https://cdn.openai.com/business-guides-and-resources/a-practical-guide-to-building-agents.pdf)를 참고하세요.

### Manager (agents as tools)

`customer_facing_agent`는 모든 사용자 상호작용을 처리하고, 도구로 노출된 전문화된 하위 에이전트를 호출합니다. 자세한 내용은 [tools](tools.md#agents-as-tools) 문서를 참고하세요.

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

### handoffs

핸드오프는 에이전트가 위임할 수 있는 하위 에이전트입니다. 핸드오프가 발생하면, 위임된 에이전트가 대화 기록을 받고 대화를 이어받습니다. 이 패턴은 단일 작업에 뛰어난 모듈식 전문 에이전트를 가능하게 합니다. 자세한 내용은 [handoffs](handoffs.md) 문서를 참고하세요.

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

대부분의 경우 에이전트를 생성할 때 instructions를 제공할 수 있습니다. 하지만 함수로 동적 instructions를 제공할 수도 있습니다. 이 함수는 에이전트와 컨텍스트를 입력으로 받아 프롬프트를 반환해야 합니다. 일반 함수와 `async` 함수 모두 허용됩니다.

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

## 라이프사이클 이벤트(hooks)

때로는 에이전트의 라이프사이클을 관찰하고 싶을 수 있습니다. 예를 들어 이벤트를 로깅하거나, 특정 이벤트가 발생했을 때 데이터를 미리 가져오고 싶을 수 있습니다. `hooks` 속성으로 에이전트 라이프사이클에 후킹할 수 있습니다. [`AgentHooks`][agents.lifecycle.AgentHooks] 클래스를 서브클래싱하고, 관심 있는 메서드를 오버라이드하세요.

## 가드레일

가드레일은 에이전트가 실행되는 동안 사용자 입력에 대한 검사/검증을 병렬로 수행하고, 출력이 생성된 후에는 에이전트 출력에 대해서도 검사/검증을 수행할 수 있게 합니다. 예를 들어 사용자의 입력과 에이전트의 출력이 관련성이 있는지 스크리닝할 수 있습니다. 자세한 내용은 [guardrails](guardrails.md) 문서를 참고하세요.

## 에이전트 복제/복사

에이전트의 `clone()` 메서드를 사용하면 Agent를 복제할 수 있으며, 원하는 속성을 선택적으로 변경할 수도 있습니다.

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

tools 목록을 제공한다고 해서 LLM이 항상 도구를 사용한다는 뜻은 아닙니다. [`ModelSettings.tool_choice`][agents.model_settings.ModelSettings.tool_choice]를 설정하여 도구 사용을 강제할 수 있습니다. 유효한 값은 다음과 같습니다:

1. `auto`: LLM이 도구 사용 여부를 결정하도록 허용합니다
2. `required`: LLM이 도구를 사용하도록 요구합니다(하지만 어떤 도구를 사용할지는 지능적으로 결정할 수 있습니다)
3. `none`: LLM이 도구를 _사용하지 않도록_ 요구합니다
4. 예: `my_tool`처럼 특정 문자열을 설정: LLM이 해당 특정 도구를 사용하도록 요구합니다

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
- `"stop_on_first_tool"`: 첫 번째 도구 호출의 출력을 추가적인 LLM 처리 없이 최종 응답으로 사용합니다

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

- `StopAtTools(stop_at_tool_names=[...])`: 지정된 도구 중 하나라도 호출되면, 해당 출력으로 최종 응답을 사용하고 중지합니다

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

- `ToolsToFinalOutputFunction`: 도구 결과를 처리하고 LLM을 중지할지 계속할지 결정하는 사용자 정의 함수입니다

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

    무한 루프를 방지하기 위해, 프레임워크는 도구 호출 이후 `tool_choice`를 자동으로 "auto"로 재설정합니다. 이 동작은 [`agent.reset_tool_choice`][agents.agent.Agent.reset_tool_choice]를 통해 구성할 수 있습니다. 무한 루프는 도구 결과가 LLM에 전송되고, LLM이 `tool_choice` 때문에 다시 도구 호출을 생성하는 일이 무한히 반복되면서 발생합니다.

================
File: docs/ko/config.md
================
---
search:
  exclude: true
---
# SDK 구성

## API 키 및 클라이언트

기본적으로 SDK 는 가져오는 즉시 LLM 요청과 트레이싱을 위해 `OPENAI_API_KEY` 환경 변수를 찾습니다. 앱이 시작되기 전에 해당 환경 변수를 설정할 수 없는 경우, [set_default_openai_key()][agents.set_default_openai_key] 함수를 사용해 키를 설정할 수 있습니다.

```python
from agents import set_default_openai_key

set_default_openai_key("sk-...")
```

또는 사용할 OpenAI 클라이언트를 구성할 수도 있습니다. 기본적으로 SDK 는 환경 변수의 API 키 또는 위에서 설정한 기본 키를 사용해 `AsyncOpenAI` 인스턴스를 생성합니다. [set_default_openai_client()][agents.set_default_openai_client] 함수를 사용해 이를 변경할 수 있습니다.

```python
from openai import AsyncOpenAI
from agents import set_default_openai_client

custom_client = AsyncOpenAI(base_url="...", api_key="...")
set_default_openai_client(custom_client)
```

마지막으로, 사용되는 OpenAI API 도 커스터마이즈할 수 있습니다. 기본적으로는 OpenAI Responses API 를 사용합니다. [set_default_openai_api()][agents.set_default_openai_api] 함수를 사용해 이를 재정의하여 Chat Completions API 를 사용하도록 할 수 있습니다.

```python
from agents import set_default_openai_api

set_default_openai_api("chat_completions")
```

## 트레이싱

트레이싱은 기본적으로 활성화되어 있습니다. 기본적으로 위 섹션의 OpenAI API 키(즉, 환경 변수 또는 설정한 기본 키)를 사용합니다. [`set_tracing_export_api_key`][agents.set_tracing_export_api_key] 함수를 사용해 트레이싱에 사용되는 API 키를 별도로 설정할 수 있습니다.

```python
from agents import set_tracing_export_api_key

set_tracing_export_api_key("sk-...")
```

기본 exporter 를 사용할 때 트레이스를 특정 조직 또는 프로젝트로 귀속시키려면, 앱이 시작되기 전에 다음 환경 변수를 설정하세요.

```bash
export OPENAI_ORG_ID="org_..."
export OPENAI_PROJECT_ID="proj_..."
```

전역 exporter 를 변경하지 않고도 실행(run) 단위로 트레이싱 API 키를 설정할 수도 있습니다.

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

## 디버그 로깅

SDK 에는 핸들러가 설정되지 않은 두 개의 Python 로거가 있습니다. 기본적으로 경고와 오류는 `stdout` 으로 전송되지만, 다른 로그는 억제됩니다.

자세한 로깅을 활성화하려면 [`enable_verbose_stdout_logging()`][agents.enable_verbose_stdout_logging] 함수를 사용하세요.

```python
from agents import enable_verbose_stdout_logging

enable_verbose_stdout_logging()
```

또는 핸들러, 필터, 포매터 등을 추가해 로그를 커스터마이즈할 수 있습니다. 자세한 내용은 [Python 로깅 가이드](https://docs.python.org/3/howto/logging.html)를 참고하세요.

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

### 로그의 민감한 데이터

일부 로그에는 민감한 데이터(예: 사용자 데이터)가 포함될 수 있습니다. 이 데이터가 로깅되지 않도록 하려면 다음 환경 변수를 설정하세요.

LLM 입력과 출력을 로깅하지 않으려면:

```bash
export OPENAI_AGENTS_DONT_LOG_MODEL_DATA=1
```

도구 입력과 출력을 로깅하지 않으려면:

```bash
export OPENAI_AGENTS_DONT_LOG_TOOL_DATA=1
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

[저장소](https://github.com/openai/openai-agents-python/tree/main/examples)의 examples 섹션에서 SDK의 다양한 샘플 구현을 확인하세요. 예제는 여러 카테고리로 구성되어 서로 다른 패턴과 기능을 보여줍니다.

## 카테고리

-   **[agent_patterns](https://github.com/openai/openai-agents-python/tree/main/examples/agent_patterns):**
    이 카테고리의 예제는 다음과 같은 일반적인 에이전트 설계 패턴을 보여줍니다

    -   결정적 워크플로
    -   도구로서의 에이전트
    -   에이전트 병렬 실행
    -   조건부 도구 사용
    -   입력/출력 가드레일
    -   심사자로서의 LLM
    -   라우팅
    -   스트리밍 가드레일

-   **[basic](https://github.com/openai/openai-agents-python/tree/main/examples/basic):**
    이 예제들은 SDK의 기초 기능을 보여줍니다

    -   Hello world 코드 예제 (기본 모델, GPT-5, 오픈 가중치 모델)
    -   에이전트 수명주기 관리
    -   동적 시스템 프롬프트
    -   스트리밍 출력(텍스트, 항목, 함수 호출 인자)
    -   프롬프트 템플릿
    -   파일 처리(로컬 및 원격, 이미지와 PDF)
    -   사용량 추적
    -   비엄격 출력 타입
    -   이전 응답 ID 사용

-   **[customer_service](https://github.com/openai/openai-agents-python/tree/main/examples/customer_service):**
    항공사용 고객 서비스 시스템 예제

-   **[financial_research_agent](https://github.com/openai/openai-agents-python/tree/main/examples/financial_research_agent):**
    금융 데이터 분석을 위한 에이전트와 도구로 구조화된 리서치 워크플로를 보여주는 금융 리서치 에이전트

-   **[handoffs](https://github.com/openai/openai-agents-python/tree/main/examples/handoffs):**
    메시지 필터링을 포함한 에이전트 핸드오프의 실용 예시

-   **[hosted_mcp](https://github.com/openai/openai-agents-python/tree/main/examples/hosted_mcp):**
    호스티드 MCP (Model Context Protocol) 커넥터와 승인 사용 방법을 보여주는 예제

-   **[mcp](https://github.com/openai/openai-agents-python/tree/main/examples/mcp):**
    MCP (Model Context Protocol)로 에이전트를 만드는 방법을 배우세요. 다음을 포함합니다

    -   파일시스템 코드 예제
    -   Git 코드 예제
    -   MCP 프롬프트 서버 코드 예제
    -   SSE (Server-Sent Events) 코드 예제
    -   스트리밍 가능한 HTTP 코드 예제

-   **[memory](https://github.com/openai/openai-agents-python/tree/main/examples/memory):**
    에이전트를 위한 다양한 메모리 구현 예제

    -   SQLite 세션 스토리지
    -   고급 SQLite 세션 스토리지
    -   Redis 세션 스토리지
    -   SQLAlchemy 세션 스토리지
    -   암호화된 세션 스토리지
    -   OpenAI 세션 스토리지

-   **[model_providers](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers):**
    커스텀 제공자와 LiteLLM 통합을 포함해 비 OpenAI 모델을 SDK에서 사용하는 방법을 살펴보세요

-   **[realtime](https://github.com/openai/openai-agents-python/tree/main/examples/realtime):**
    SDK를 사용해 실시간 경험을 구축하는 방법을 보여주는 예제

    -   웹 애플리케이션
    -   커맨드라인 인터페이스
    -   Twilio 통합

-   **[reasoning_content](https://github.com/openai/openai-agents-python/tree/main/examples/reasoning_content):**
    추론 콘텐츠와 structured outputs를 다루는 방법을 보여주는 예제

-   **[research_bot](https://github.com/openai/openai-agents-python/tree/main/examples/research_bot):**
    복잡한 멀티 에이전트 리서치 워크플로를 보여주는 단순한 딥 리서치 클론

-   **[tools](https://github.com/openai/openai-agents-python/tree/main/examples/tools):**
    다음과 같은 OpenAI 호스트하는 도구를 구현하는 방법을 배우세요

    -   웹 검색 및 필터가 있는 웹 검색
    -   파일 검색
    -   Code interpreter
    -   컴퓨터 사용
    -   이미지 생성

-   **[voice](https://github.com/openai/openai-agents-python/tree/main/examples/voice):**
    TTS 및 STT 모델을 사용하는 음성 에이전트 예제와 스트리밍 음성 코드 예제를 확인하세요

================
File: docs/ko/guardrails.md
================
---
search:
  exclude: true
---
# 가드레일

가드레일은 사용자 입력과 에이전트 출력에 대한 확인 및 검증을 가능하게 합니다. 예를 들어, 매우 똑똑한(따라서 느리고/비싼) 모델을 사용해 고객 요청을 돕는 에이전트가 있다고 가정해 보겠습니다. 악의적인 사용자가 수학 숙제를 도와 달라고 모델에 요청하는 것을 원치 않을 것입니다. 이때 빠르고/저렴한 모델로 가드레일을 실행할 수 있습니다. 가드레일이 악성 사용을 감지하면 즉시 오류를 발생시켜 비싼 모델 실행을 막아 시간과 비용을 절약할 수 있습니다(**차단형 가드레일 사용 시에 한함. 병렬 가드레일의 경우, 가드레일이 완료되기 전에 비싼 모델이 이미 실행을 시작했을 수 있습니다. 자세한 내용은 아래의 "실행 모드"를 참고하세요**).

가드레일에는 두 가지 종류가 있습니다:

1. 입력 가드레일은 최초 사용자 입력에서 실행됨
2. 출력 가드레일은 최종 에이전트 출력에서 실행됨

## 입력 가드레일

입력 가드레일은 3단계로 실행됩니다:

1. 먼저, 가드레일이 에이전트에 전달된 것과 동일한 입력을 받습니다.
2. 다음으로, 가드레일 함수가 실행되어 [`GuardrailFunctionOutput`][agents.guardrail.GuardrailFunctionOutput]을 생성하고, 이는 [`InputGuardrailResult`][agents.guardrail.InputGuardrailResult]로 래핑됩니다
3. 마지막으로 [`.tripwire_triggered`][agents.guardrail.GuardrailFunctionOutput.tripwire_triggered]가 true인지 확인합니다. true이면 [`InputGuardrailTripwireTriggered`][agents.exceptions.InputGuardrailTripwireTriggered] 예외가 발생하며, 이를 통해 사용자에게 적절히 응답하거나 예외를 처리할 수 있습니다.

!!! Note

    입력 가드레일은 사용자 입력에서 실행되도록 설계되었으므로, 해당 에이전트가 *첫 번째* 에이전트일 때만 에이전트의 가드레일이 실행됩니다. 왜 `guardrails` 속성이 에이전트에 있고 `Runner.run`에 전달하지 않는지 궁금할 수 있습니다. 가드레일은 실제 에이전트와 밀접하게 연관되는 경향이 있기 때문입니다. 에이전트마다 서로 다른 가드레일을 실행하게 되므로, 코드를 같은 위치에 두면 가독성에 도움이 됩니다.

### 실행 모드

입력 가드레일은 두 가지 실행 모드를 지원합니다:

- **병렬 실행**(기본값, `run_in_parallel=True`): 가드레일이 에이전트 실행과 동시에 실행됩니다. 둘이 동시에 시작되므로 지연 시간이 가장 좋습니다. 다만, 가드레일이 실패할 경우, 에이전트가 취소되기 전에 이미 토큰을 소비하고 도구를 실행했을 수 있습니다.

- **차단 실행**(`run_in_parallel=False`): 가드레일이 에이전트 시작 *이전* 에 실행되어 완료됩니다. 가드레일 트립와이어가 트리거되면 에이전트는 절대 실행되지 않으므로 토큰 소비와 도구 실행을 방지할 수 있습니다. 비용 최적화와 도구 호출에 따른 잠재적 부작용을 피하고 싶을 때 이상적입니다.

## 출력 가드레일

출력 가드레일은 3단계로 실행됩니다:

1. 먼저, 가드레일이 에이전트가 생성한 출력을 받습니다.
2. 다음으로, 가드레일 함수가 실행되어 [`GuardrailFunctionOutput`][agents.guardrail.GuardrailFunctionOutput]을 생성하고, 이는 [`OutputGuardrailResult`][agents.guardrail.OutputGuardrailResult]로 래핑됩니다
3. 마지막으로 [`.tripwire_triggered`][agents.guardrail.GuardrailFunctionOutput.tripwire_triggered]가 true인지 확인합니다. true이면 [`OutputGuardrailTripwireTriggered`][agents.exceptions.OutputGuardrailTripwireTriggered] 예외가 발생하며, 이를 통해 사용자에게 적절히 응답하거나 예외를 처리할 수 있습니다.

!!! Note

    출력 가드레일은 최종 에이전트 출력에서 실행되도록 설계되었으므로, 해당 에이전트가 *마지막* 에이전트일 때만 에이전트의 가드레일이 실행됩니다. 입력 가드레일과 마찬가지로, 가드레일은 실제 에이전트와 밀접하게 연관되므로 코드를 같은 위치에 두면 가독성에 도움이 됩니다.

    출력 가드레일은 항상 에이전트 완료 후에 실행되므로 `run_in_parallel` 매개변수를 지원하지 않습니다.

## 도구 가드레일

도구 가드레일은 **함수 도구** 를 래핑하고, 실행 전후로 도구 호출을 검증하거나 차단할 수 있게 해줍니다. 이는 도구 자체에서 구성되며 해당 도구가 호출될 때마다 실행됩니다.

- 입력 도구 가드레일은 도구가 실행되기 전에 동작하며, 호출을 건너뛰거나, 메시지로 출력을 대체하거나, 트립와이어를 발생시킬 수 있습니다
- 출력 도구 가드레일은 도구가 실행된 후 동작하며, 출력을 대체하거나 트립와이어를 발생시킬 수 있습니다
- 도구 가드레일은 [`function_tool`][agents.function_tool]로 생성된 함수 도구에만 적용됩니다. 호스티드 툴(`WebSearchTool`, `FileSearchTool`, `HostedMCPTool`, `CodeInterpreterTool`, `ImageGenerationTool`)과 로컬 런타임 도구(`ComputerTool`, `ShellTool`, `ApplyPatchTool`, `LocalShellTool`)는 이 가드레일 파이프라인을 사용하지 않습니다

자세한 내용은 아래 코드 스니펫을 참고하세요.

## 트립와이어

입력 또는 출력이 가드레일을 통과하지 못하면, 가드레일은 트립와이어로 이를 신호할 수 있습니다. 트립와이어가 트리거된 가드레일을 확인하는 즉시 `{Input,Output}GuardrailTripwireTriggered` 예외를 발생시키고 에이전트 실행을 중단합니다.

## 가드레일 구현

입력을 받아 [`GuardrailFunctionOutput`][agents.guardrail.GuardrailFunctionOutput]을 반환하는 함수를 제공해야 합니다. 이 예시에서는 내부적으로 에이전트를 실행하여 이를 수행합니다.

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

1. 이 에이전트를 가드레일 함수에서 사용합니다
2. 이것이 에이전트의 입력/컨텍스트를 받아 결과를 반환하는 가드레일 함수입니다
3. 가드레일 결과에 추가 정보를 포함할 수 있습니다
4. 이것이 워크플로를 정의하는 실제 에이전트입니다

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

1. 이것이 실제 에이전트의 출력 타입입니다
2. 이것이 가드레일의 출력 타입입니다
3. 이것이 에이전트의 출력을 받아 결과를 반환하는 가드레일 함수입니다
4. 이것이 워크플로를 정의하는 실제 에이전트입니다

마지막으로, 도구 가드레일의 예시입니다.

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

핸드오프를 사용하면 에이전트가 다른 에이전트에게 작업을 위임할 수 있습니다. 이는 서로 다른 에이전트가 각기 다른 영역에 특화된 시나리오에서 특히 유용합니다. 예를 들어 고객 지원 앱에는 주문 상태, 환불, FAQ 등과 같은 작업을 각각 전담하는 에이전트가 있을 수 있습니다.

핸드오프는 LLM에 도구로 표현됩니다. 따라서 `Refund Agent`라는 에이전트로 핸드오프가 있다면, 도구 이름은 `transfer_to_refund_agent`가 됩니다.

## 핸드오프 생성

모든 에이전트에는 [`handoffs`][agents.agent.Agent.handoffs] 매개변수가 있으며, 여기에 `Agent`를 직접 전달하거나 핸드오프를 커스터마이즈하는 `Handoff` 객체를 전달할 수 있습니다.

일반 `Agent` 인스턴스를 전달하면, 해당 에이전트의 [`handoff_description`][agents.agent.Agent.handoff_description](설정된 경우)이 기본 도구 설명에 추가됩니다. 전체 `handoff()` 객체를 작성하지 않고도, 모델이 언제 해당 핸드오프를 선택해야 하는지 힌트를 주는 데 사용할 수 있습니다.

Agents SDK에서 제공하는 [`handoff()`][agents.handoffs.handoff] 함수를 사용해 핸드오프를 생성할 수 있습니다. 이 함수로 핸드오프 대상 에이전트를 지정하고, 선택적으로 오버라이드와 입력 필터를 지정할 수 있습니다.

### 기본 사용법

다음은 간단한 핸드오프를 만드는 방법입니다:

```python
from agents import Agent, handoff

billing_agent = Agent(name="Billing agent")
refund_agent = Agent(name="Refund agent")

# (1)!
triage_agent = Agent(name="Triage agent", handoffs=[billing_agent, handoff(refund_agent)])
```

1. 에이전트를 직접 사용할 수도 있고(`billing_agent`처럼), `handoff()` 함수를 사용할 수도 있습니다.

### `handoff()` 함수를 통한 핸드오프 커스터마이즈

[`handoff()`][agents.handoffs.handoff] 함수로 다양한 항목을 커스터마이즈할 수 있습니다.

-   `agent`: 작업이 핸드오프될 대상 에이전트입니다.
-   `tool_name_override`: 기본값으로 `Handoff.default_tool_name()` 함수가 사용되며, 이는 `transfer_to_<agent_name>`으로 해석됩니다. 이를 오버라이드할 수 있습니다.
-   `tool_description_override`: `Handoff.default_tool_description()`의 기본 도구 설명을 오버라이드합니다
-   `on_handoff`: 핸드오프가 호출될 때 실행되는 콜백 함수입니다. 핸드오프가 호출된다는 사실을 알자마자 데이터 페칭을 시작하는 등의 용도에 유용합니다. 이 함수는 에이전트 컨텍스트를 받으며, 선택적으로 LLM이 생성한 입력도 받을 수 있습니다. 입력 데이터는 `input_type` 매개변수로 제어됩니다.
-   `input_type`: 핸드오프가 기대하는 입력 타입(선택 사항)입니다.
-   `input_filter`: 다음 에이전트가 받는 입력을 필터링할 수 있습니다. 자세한 내용은 아래를 참고하세요.
-   `is_enabled`: 핸드오프 활성화 여부입니다. boolean 또는 boolean을 반환하는 함수가 될 수 있어, 런타임에 동적으로 핸드오프를 활성화/비활성화할 수 있습니다.

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

일부 상황에서는 LLM이 핸드오프를 호출할 때 특정 데이터를 제공하길 원할 수 있습니다. 예를 들어 "Escalation agent"로 핸드오프하는 상황을 생각해 보세요. 로그를 남길 수 있도록 사유가 함께 제공되길 원할 수 있습니다.

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

핸드오프가 발생하면 새 에이전트가 대화를 이어받아 이전의 전체 대화 기록을 볼 수 있는 것과 같습니다. 이를 변경하고 싶다면 [`input_filter`][agents.handoffs.Handoff.input_filter]를 설정할 수 있습니다. 입력 필터는 [`HandoffInputData`][agents.handoffs.HandoffInputData]를 통해 기존 입력을 받아, 새로운 `HandoffInputData`를 반환해야 하는 함수입니다.

중첩 핸드오프는 옵트인 베타로 제공되며, 안정화하는 동안 기본적으로 비활성화되어 있습니다. [`RunConfig.nest_handoff_history`][agents.run.RunConfig.nest_handoff_history]를 활성화하면, 러너가 이전 대화 기록을 단일 어시스턴트 요약 메시지로 축약하고 `<CONVERSATION HISTORY>` 블록으로 감싸며, 동일한 실행 중 여러 핸드오프가 발생할 때 새로운 턴을 계속 덧붙입니다. 전체 `input_filter`를 작성하지 않고도 생성된 메시지를 대체하려면 [`RunConfig.handoff_history_mapper`][agents.run.RunConfig.handoff_history_mapper]를 통해 자체 매핑 함수를 제공할 수 있습니다. 이 옵트인은 핸드오프나 실행에서 명시적인 `input_filter`를 제공하지 않는 경우에만 적용되므로, 이미 페이로드를 커스터마이즈하는 기존 코드(이 저장소의 예제 포함)는 변경 없이 현재 동작을 유지합니다. 단일 핸드오프에 대해 중첩 동작을 오버라이드하려면 [`handoff(...)`][agents.handoffs.handoff]에 `nest_handoff_history=True` 또는 `False`를 전달하면 되며, 이는 [`Handoff.nest_handoff_history`][agents.handoffs.Handoff.nest_handoff_history]를 설정합니다. 생성된 요약의 래퍼 텍스트만 변경하면 된다면, 에이전트를 실행하기 전에 [`set_conversation_history_wrappers`][agents.handoffs.set_conversation_history_wrappers](그리고 선택적으로 [`reset_conversation_history_wrappers`][agents.handoffs.reset_conversation_history_wrappers])를 호출하세요.

일부 공통 패턴(예: 기록에서 모든 도구 호출 제거)은 [`agents.extensions.handoff_filters`][]에 이미 구현되어 있습니다

```python
from agents import Agent, handoff
from agents.extensions import handoff_filters

agent = Agent(name="FAQ agent")

handoff_obj = handoff(
    agent=agent,
    input_filter=handoff_filters.remove_all_tools, # (1)!
)
```

1. 이는 `FAQ agent`가 호출될 때 기록에서 모든 도구를 자동으로 제거합니다.

## 권장 프롬프트

LLM이 핸드오프를 올바르게 이해하도록 하려면, 에이전트에 핸드오프 관련 정보를 포함하는 것을 권장합니다. [`agents.extensions.handoff_prompt.RECOMMENDED_PROMPT_PREFIX`][]에 권장 프리픽스가 있으며, 또는 [`agents.extensions.handoff_prompt.prompt_with_handoff_instructions`][]를 호출해 권장 데이터를 프롬프트에 자동으로 추가할 수 있습니다.

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
File: docs/ko/index.md
================
---
search:
  exclude: true
---
# OpenAI Agents SDK

[OpenAI Agents SDK](https://github.com/openai/openai-agents-python)를 사용하면 추상화가 거의 없는 가볍고 사용하기 쉬운 패키지로 에이전트형 AI 앱을 만들 수 있습니다. 이는 에이전트를 위한 이전 실험인 [Swarm](https://github.com/openai/swarm/tree/main)의 프로덕션 준비 완료 업그레이드 버전입니다. Agents SDK에는 매우 작은 기본 구성 요소(primitives) 집합이 있습니다:

-   **에이전트**, 즉 instructions 와 tools 를 갖춘 LLM
-   **Agents as tools / 핸드오프**, 특정 작업을 위해 에이전트가 다른 에이전트에게 위임할 수 있게 해주는 기능
-   **가드레일**, 에이전트 입력과 출력의 검증을 가능하게 하는 기능

이러한 기본 구성 요소는 Python과 결합될 때 도구와 에이전트 간의 복잡한 관계를 표현하기에 충분히 강력하며, 가파른 학습 곡선 없이 실제 애플리케이션을 만들 수 있게 해줍니다. 또한 SDK에는 내장된 **트레이싱**이 포함되어 있어 에이전트형 플로우를 시각화하고 디버그할 수 있으며, 이를 평가하고 애플리케이션을 위해 모델을 미세 조정하는 것까지 가능합니다.

## Agents SDK 사용 이유

SDK에는 두 가지 핵심 설계 원칙이 있습니다:

1. 사용할 가치가 있을 만큼 충분한 기능을 제공하되, 빠르게 학습할 수 있도록 기본 구성 요소는 충분히 적게 유지합니다
2. 기본 설정만으로도 훌륭하게 동작하지만, 정확히 어떤 일이 일어나는지 원하는 대로 커스터마이즈할 수 있습니다

다음은 SDK의 주요 기능입니다:

-   **에이전트 루프**: 도구 호출을 처리하고 결과를 LLM에 다시 전달한 뒤 작업이 완료될 때까지 계속하는 내장 에이전트 루프입니다
-   **파이썬 우선**: 새로운 추상화를 배울 필요 없이 내장 언어 기능을 사용해 에이전트를 오케스트레이션하고 체이닝합니다
-   **Agents as tools / 핸드오프**: 여러 에이전트에 걸친 작업의 조정과 위임을 위한 강력한 메커니즘입니다
-   **가드레일**: 에이전트 실행과 병렬로 입력 검증과 안전성 체크를 수행하며, 체크를 통과하지 못하면 즉시 실패 처리합니다
-   **함수 도구**: 자동 스키마 생성과 Pydantic 기반 검증을 통해 어떤 Python 함수든 도구로 전환합니다
-   **MCP 서버 도구 호출**: 함수 도구와 동일한 방식으로 동작하는 내장 MCP 서버 도구 통합입니다
-   **세션**: 에이전트 루프 내에서 작업 컨텍스트를 유지하기 위한 영속 메모리 레이어입니다
-   **휴먼인더루프 (HITL)**: 에이전트 실행 전반에 걸쳐 사람을 참여시키기 위한 내장 메커니즘입니다
-   **트레이싱**: 워크플로를 시각화, 디버깅, 모니터링하기 위한 내장 트레이싱으로, OpenAI 평가, 미세 조정, 디스틸레이션 도구 제품군을 지원합니다
-   **실시간 에이전트**: 자동 인터럽션(중단 처리) 감지, 컨텍스트 관리, 가드레일 등 기능을 갖춘 강력한 음성 에이전트를 구축합니다

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

================
File: docs/ko/mcp.md
================
---
search:
  exclude: true
---
# Model context protocol (MCP)

[Model context protocol](https://modelcontextprotocol.io/introduction)(MCP)은 애플리케이션이 언어 모델에 도구와 컨텍스트를 노출하는 방식을 표준화합니다. 공식 문서에서 인용하면 다음과 같습니다:

> MCP는 애플리케이션이 LLM에 컨텍스트를 제공하는 방식을 표준화하는 오픈 프로토콜입니다. MCP를 AI 애플리케이션을 위한 USB-C 포트라고 생각해 보세요
> USB-C가 다양한 주변기기와 액세서리에 디바이스를 연결하는 표준화된 방법을 제공하듯이, MCP는 AI 모델을 서로 다른 데이터 소스와 도구에 연결하는 표준화된 방법을 제공합니다

Agents Python SDK는 여러 MCP 전송 방식을 이해합니다. 이를 통해 기존 MCP 서버를 재사용하거나, 파일 시스템, HTTP 또는 커넥터 기반 도구를 에이전트에 노출하기 위한 자체 서버를 구축할 수 있습니다.

## MCP 통합 선택

MCP 서버를 에이전트에 연결하기 전에, 도구 호출이 어디에서 실행되어야 하는지와 도달 가능한 전송 방식이 무엇인지 결정하세요. 아래 매트릭스는 Python SDK가 지원하는 옵션을 요약합니다.

| What you need                                                                        | Recommended option                                    |
| ------------------------------------------------------------------------------------ | ----------------------------------------------------- |
| OpenAI의 Responses API가 모델을 대신해 공개적으로 접근 가능한 MCP 서버를 호출하게 하기| [`HostedMCPTool`][agents.tool.HostedMCPTool]을 통한 **Hosted MCP server tools** |
| 로컬 또는 원격에서 직접 운영하는 Streamable HTTP 서버에 연결하기                    | [`MCPServerStreamableHttp`][agents.mcp.server.MCPServerStreamableHttp]을 통한 **Streamable HTTP MCP servers** |
| Server-Sent Events를 사용하는 HTTP를 구현한 서버와 통신하기                          | [`MCPServerSse`][agents.mcp.server.MCPServerSse]를 통한 **HTTP with SSE MCP servers** |
| 로컬 프로세스를 실행하고 stdin/stdout으로 통신하기                                   | [`MCPServerStdio`][agents.mcp.server.MCPServerStdio]를 통한 **stdio MCP servers** |

아래 섹션에서는 각 옵션, 구성 방법, 그리고 어떤 전송 방식을 언제 선호해야 하는지를 안내합니다.

## 1. Hosted MCP server tools

호스티드 툴은 전체 도구 왕복 과정을 OpenAI 인프라로 밀어 넣습니다. 코드에서 도구를 나열하고 호출하는 대신, [`HostedMCPTool`][agents.tool.HostedMCPTool]이 서버 레이블(및 선택적 커넥터 메타데이터)을 Responses API로 전달합니다. 그러면 모델이 원격 서버의 도구를 나열하고, Python 프로세스로 추가 콜백 없이 이를 호출합니다. 호스티드 툴은 현재 Responses API의 호스티드 MCP 통합을 지원하는 OpenAI 모델에서 동작합니다.

### 기본 호스티드 MCP 도구

에이전트의 `tools` 목록에 [`HostedMCPTool`][agents.tool.HostedMCPTool]을 추가하여 호스티드 도구를 생성합니다. `tool_config` dict는 REST API로 전송할 JSON을 그대로 반영합니다:

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

호스티드 서버는 자동으로 도구를 노출하므로, `mcp_servers`에 추가하지 않습니다.

### 호스티드 MCP 결과 스트리밍

호스티드 툴은 함수 도구와 정확히 동일한 방식으로 결과 스트리밍을 지원합니다. `Runner.run_streamed`에 `stream=True`를 전달하면, 모델이 작업 중인 동안 점진적으로 출력되는 MCP 결과를 소비할 수 있습니다:

```python
result = Runner.run_streamed(agent, "Summarise this repository's top languages")
async for event in result.stream_events():
    if event.type == "run_item_stream_event":
        print(f"Received: {event.item}")
print(result.final_output)
```

### 선택적 승인 흐름

서버가 민감한 작업을 수행할 수 있다면, 각 도구 실행 전에 사람 또는 프로그램에 의한 승인을 요구할 수 있습니다. `tool_config`에서 `require_approval`을 단일 정책(`"always"`, `"never"`) 또는 도구 이름을 정책에 매핑한 dict로 구성하세요. Python 내부에서 결정을 내리려면 `on_approval_request` 콜백을 제공합니다.

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

이 콜백은 동기 또는 비동기일 수 있으며, 모델이 계속 실행하기 위해 승인 데이터가 필요할 때마다 호출됩니다.

### 커넥터 기반 호스티드 서버

호스티드 MCP는 OpenAI 커넥터도 지원합니다. `server_url`을 지정하는 대신 `connector_id`와 액세스 토큰을 제공하세요. Responses API가 인증을 처리하며 호스티드 서버가 커넥터의 도구를 노출합니다.

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

스트리밍, 승인, 커넥터를 포함한 완전한 호스티드 도구 샘플은
[`examples/hosted_mcp`](https://github.com/openai/openai-agents-python/tree/main/examples/hosted_mcp)에 있습니다.

## 2. Streamable HTTP MCP servers

네트워크 연결을 직접 관리하려면 [`MCPServerStreamableHttp`][agents.mcp.server.MCPServerStreamableHttp]을 사용하세요. Streamable HTTP 서버는 전송을 제어할 수 있거나, 지연 시간을 낮게 유지하면서 자체 인프라 내부에서 서버를 실행하려는 경우에 이상적입니다.

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

생성자는 추가 옵션을 받습니다:

- `client_session_timeout_seconds`는 HTTP 읽기 타임아웃을 제어합니다
- `use_structured_content`는 텍스트 출력보다 `tool_result.structured_content`를 우선할지 전환합니다
- `max_retry_attempts` 및 `retry_backoff_seconds_base`는 `list_tools()`와 `call_tool()`에 대한 자동 재시도를 추가합니다
- `tool_filter`는 도구의 일부만 노출할 수 있게 합니다([Tool filtering](#tool-filtering) 참고)

## 3. HTTP with SSE MCP servers

!!! warning

    MCP 프로젝트는 Server-Sent Events 전송 방식을 더 이상 권장하지 않습니다. 새로운 통합에서는 Streamable HTTP 또는 stdio를 선호하고, SSE는 레거시 서버에만 유지하세요.

MCP 서버가 HTTP with SSE 전송 방식을 구현한다면, [`MCPServerSse`][agents.mcp.server.MCPServerSse]를 인스턴스화하세요. 전송 방식을 제외하면 API는 Streamable HTTP 서버와 동일합니다.

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

로컬 서브프로세스로 실행되는 MCP 서버에는 [`MCPServerStdio`][agents.mcp.server.MCPServerStdio]를 사용하세요. SDK가 프로세스를 생성하고 파이프를 열린 상태로 유지하며, 컨텍스트 매니저가 종료될 때 자동으로 닫습니다. 이 옵션은 빠른 PoC나 서버가 커맨드라인 엔트리 포인트만 노출하는 경우에 유용합니다.

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

## 5. MCP 서버 매니저

여러 MCP 서버가 있을 때는 `MCPServerManager`를 사용해 미리 연결하고, 연결된 하위 집합을 에이전트에 노출하세요.

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

주요 동작:

- `drop_failed_servers=True`(기본값)일 때 `active_servers`에는 성공적으로 연결된 서버만 포함됩니다
- 실패는 `failed_servers`와 `errors`에 추적됩니다
- 첫 번째 연결 실패에서 예외를 발생시키려면 `strict=True`로 설정합니다
- 실패한 서버만 재시도하려면 `reconnect(failed_only=True)`를, 모든 서버를 재시작하려면 `reconnect(failed_only=False)`를 호출합니다
- `connect_timeout_seconds`, `cleanup_timeout_seconds`, `connect_in_parallel`로 라이프사이클 동작을 조정합니다

## Tool filtering

각 MCP 서버는 도구 필터를 지원하므로, 에이전트에 필요한 함수만 노출할 수 있습니다. 필터링은 생성 시점 또는 실행(run)별로 동적으로 수행할 수 있습니다.

### 정적 도구 필터링

단순한 허용/차단 목록을 구성하려면 [`create_static_tool_filter`][agents.mcp.create_static_tool_filter]를 사용하세요:

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

`allowed_tool_names`와 `blocked_tool_names`를 모두 제공하면 SDK는 먼저 허용 목록을 적용한 다음, 남은 집합에서 차단된 도구를 제거합니다.

### 동적 도구 필터링

더 복잡한 로직을 위해 [`ToolFilterContext`][agents.mcp.ToolFilterContext]를 받는 callable을 전달하세요. callable은 동기 또는 비동기일 수 있으며, 도구를 노출해야 할 때 `True`를 반환합니다.

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

필터 컨텍스트는 활성 `run_context`, 도구를 요청하는 `agent`, 그리고 `server_name`을 노출합니다.

## Prompts

MCP 서버는 에이전트 instructions를 동적으로 생성하는 프롬프트도 제공할 수 있습니다. 프롬프트를 지원하는 서버는 두 가지 메서드를 노출합니다:

- `list_prompts()`는 사용 가능한 프롬프트 템플릿을 열거합니다
- `get_prompt(name, arguments)`는 선택적으로 매개변수를 포함해 구체적인 프롬프트를 가져옵니다

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

각 에이전트 실행은 각 MCP 서버에 대해 `list_tools()`를 호출합니다. 원격 서버는 눈에 띄는 지연 시간을 유발할 수 있으므로, 모든 MCP 서버 클래스는 `cache_tools_list` 옵션을 노출합니다. 도구 정의가 자주 바뀌지 않는다고 확신할 때만 `True`로 설정하세요. 나중에 최신 목록을 강제로 가져오려면 서버 인스턴스에서 `invalidate_tools_cache()`를 호출하세요.

## Tracing

[Tracing](./tracing.md)은 다음을 포함한 MCP 활동을 자동으로 캡처합니다:

1. 도구 목록을 나열하기 위한 MCP 서버 호출
2. 도구 호출의 MCP 관련 정보

![MCP Tracing Screenshot](../assets/images/mcp-tracing.jpg)

## 추가 읽을거리

- [Model Context Protocol](https://modelcontextprotocol.io/) – 사양 및 설계 가이드
- [examples/mcp](https://github.com/openai/openai-agents-python/tree/main/examples/mcp) – 실행 가능한 stdio, SSE, Streamable HTTP 샘플
- [examples/hosted_mcp](https://github.com/openai/openai-agents-python/tree/main/examples/hosted_mcp) – 승인과 커넥터를 포함한 완전한 호스티드 MCP 데모

================
File: docs/ko/multi_agent.md
================
---
search:
  exclude: true
---
# 멀티 에이전트 오케스트레이션

오케스트레이션은 앱에서 에이전트의 흐름을 의미합니다. 어떤 에이전트를 어떤 순서로 실행하고, 다음에 무엇을 할지 어떻게 결정할까요? 에이전트를 오케스트레이션하는 주요 방법은 두 가지입니다:

1. LLM이 의사결정을 하도록 허용: LLM의 지능을 활용해 계획하고 추론하여 그에 기반해 수행할 단계를 결정
2. 코드로 오케스트레이션: 코드로 에이전트의 흐름을 결정

이 패턴들은 혼합해서 사용할 수 있습니다. 각각의 트레이드오프는 아래에 설명합니다.

## LLM 기반 오케스트레이션

에이전트는 instructions, tools, 핸드오프로 장착된 LLM입니다. 즉, 개방형 과제가 주어지면 LLM은 도구를 사용해 행동하고 데이터를 획득하며, 핸드오프를 사용해 하위 에이전트에 작업을 위임하는 방식으로 과제를 자율적으로 계획할 수 있습니다. 예를 들어 연구 에이전트는 다음과 같은 도구로 구성될 수 있습니다:

- 웹 검색을 통한 온라인 정보 탐색
- 파일 검색 및 검색을 통한 사내 데이터와 연결 탐색
- 컴퓨터 사용을 통한 컴퓨터 상의 작업 수행
- 코드 실행을 통한 데이터 분석
- 기획, 보고서 작성 등에 특화된 에이전트로의 핸드오프

이 패턴은 과제가 개방형이고 LLM의 지능에 의존하고자 할 때 유용합니다. 여기서 가장 중요한 전술은 다음과 같습니다:

1. 좋은 프롬프트에 투자하세요. 사용 가능한 도구, 사용 방법, 운영해야 하는 매개변수 범위를 명확히 하세요.
2. 앱을 모니터링하고 반복 개선하세요. 문제가 생기는 지점을 파악하고 프롬프트를 개선하세요.
3. 에이전트가 자기 성찰하고 개선하도록 허용하세요. 예를 들어 루프로 실행해 스스로 비평하게 하거나, 오류 메시지를 제공해 개선하게 하세요.
4. 범용 에이전트 하나가 모든 것을 잘하도록 기대하기보다, 하나의 작업에 특화된 에이전트를 두세요.
5. [evals](https://platform.openai.com/docs/guides/evals)에 투자하세요. 이를 통해 에이전트를 훈련하고 과제 수행 능력을 향상시킬 수 있습니다.

## 코드 기반 오케스트레이션

LLM 기반 오케스트레이션이 강력하긴 하지만, 코드 기반 오케스트레이션은 속도, 비용, 성능 측면에서 작업을 더 결정적이고 예측 가능하게 만듭니다. 여기에서 일반적인 패턴은 다음과 같습니다:

- [structured outputs](https://platform.openai.com/docs/guides/structured-outputs)를 사용해 코드로 검사할 수 있는 적절한 형식의 데이터를 생성. 예를 들어 에이전트에게 작업을 몇 가지 카테고리로 분류하도록 요청하고, 그 카테고리에 따라 다음 에이전트를 선택할 수 있습니다.
- 한 에이전트의 출력을 다음 에이전트의 입력으로 변환하여 여러 에이전트를 체이닝. 블로그 글쓰기 같은 작업을 조사, 개요 작성, 본문 작성, 비평, 개선의 단계로 분해할 수 있습니다.
- 작업을 수행하는 에이전트와 평가 및 피드백을 제공하는 에이전트를 `while` 루프로 함께 실행하고, 평가자가 출력이 특정 기준을 통과했다고 말할 때까지 반복
- 여러 에이전트를 병렬로 실행, 예: 파이썬 기본 구성요소 `asyncio.gather` 사용. 서로 의존하지 않는 여러 작업이 있을 때 속도 향상에 유용합니다.

[`examples/agent_patterns`](https://github.com/openai/openai-agents-python/tree/main/examples/agent_patterns)에 여러 개의 code examples가 있습니다.

================
File: docs/ko/quickstart.md
================
---
search:
  exclude: true
---
# 빠른 시작

## 프로젝트 및 가상 환경 생성

한 번만 설정하면 됩니다.

```bash
mkdir my_project
cd my_project
python -m venv .venv
```

### 가상 환경 활성화

새 터미널 세션을 시작할 때마다 수행하세요.

```bash
source .venv/bin/activate
```

### Agents SDK 설치

```bash
pip install openai-agents # or `uv add openai-agents`, etc
```

### OpenAI API 키 설정

키가 없다면 OpenAI API 키를 생성하려면 [이 지침](https://platform.openai.com/docs/quickstart#create-and-export-an-api-key)을 따르세요.

```bash
export OPENAI_API_KEY=sk-...
```

## 첫 에이전트 생성

에이전트는 instructions, 이름, 그리고 선택적 구성(예: `model_config`)으로 정의합니다

```python
from agents import Agent

agent = Agent(
    name="Math Tutor",
    instructions="You provide help with math problems. Explain your reasoning at each step and include examples",
)
```

## 에이전트 추가

추가 에이전트도 동일한 방식으로 정의할 수 있습니다. `handoff_descriptions`는 핸드오프 라우팅을 결정하는 데 추가 컨텍스트를 제공합니다

```python
from agents import Agent

history_tutor_agent = Agent(
    name="History Tutor",
    handoff_description="Specialist agent for historical questions",
    instructions="You provide assistance with historical queries. Explain important events and context clearly.",
)

math_tutor_agent = Agent(
    name="Math Tutor",
    handoff_description="Specialist agent for math questions",
    instructions="You provide help with math problems. Explain your reasoning at each step and include examples",
)
```

## 핸드오프 정의

각 에이전트에서, 작업을 진행하는 방법을 결정하기 위해 선택할 수 있는 아웃바운드 핸드오프 옵션 목록을 정의할 수 있습니다.

```python
triage_agent = Agent(
    name="Triage Agent",
    instructions="You determine which agent to use based on the user's homework question",
    handoffs=[history_tutor_agent, math_tutor_agent]
)
```

## 에이전트 오케스트레이션 실행

워크플로가 실행되고 분류 에이전트가 두 전문 에이전트 간에 올바르게 라우팅하는지 확인해 봅시다.

```python
from agents import Runner

async def main():
    result = await Runner.run(triage_agent, "who was the first president of the united states?")
    print(result.final_output)
```

## 가드레일 추가

입력 또는 출력에 대해 실행할 사용자 정의 가드레일을 정의할 수 있습니다.

```python
from agents import GuardrailFunctionOutput, Agent, Runner
from pydantic import BaseModel


class HomeworkOutput(BaseModel):
    is_homework: bool
    reasoning: str

guardrail_agent = Agent(
    name="Guardrail check",
    instructions="Check if the user is asking about homework.",
    output_type=HomeworkOutput,
)

async def homework_guardrail(ctx, agent, input_data):
    result = await Runner.run(guardrail_agent, input_data, context=ctx.context)
    final_output = result.final_output_as(HomeworkOutput)
    return GuardrailFunctionOutput(
        output_info=final_output,
        tripwire_triggered=not final_output.is_homework,
    )
```

## 전체 통합

핸드오프와 입력 가드레일을 사용해 전체 워크플로를 실행해 봅시다.

```python
from agents import Agent, InputGuardrail, GuardrailFunctionOutput, Runner
from agents.exceptions import InputGuardrailTripwireTriggered
from pydantic import BaseModel
import asyncio

class HomeworkOutput(BaseModel):
    is_homework: bool
    reasoning: str

guardrail_agent = Agent(
    name="Guardrail check",
    instructions="Check if the user is asking about homework.",
    output_type=HomeworkOutput,
)

math_tutor_agent = Agent(
    name="Math Tutor",
    handoff_description="Specialist agent for math questions",
    instructions="You provide help with math problems. Explain your reasoning at each step and include examples",
)

history_tutor_agent = Agent(
    name="History Tutor",
    handoff_description="Specialist agent for historical questions",
    instructions="You provide assistance with historical queries. Explain important events and context clearly.",
)


async def homework_guardrail(ctx, agent, input_data):
    result = await Runner.run(guardrail_agent, input_data, context=ctx.context)
    final_output = result.final_output_as(HomeworkOutput)
    return GuardrailFunctionOutput(
        output_info=final_output,
        tripwire_triggered=not final_output.is_homework,
    )

triage_agent = Agent(
    name="Triage Agent",
    instructions="You determine which agent to use based on the user's homework question",
    handoffs=[history_tutor_agent, math_tutor_agent],
    input_guardrails=[
        InputGuardrail(guardrail_function=homework_guardrail),
    ],
)

async def main():
    # Example 1: History question
    try:
        result = await Runner.run(triage_agent, "who was the first president of the united states?")
        print(result.final_output)
    except InputGuardrailTripwireTriggered as e:
        print("Guardrail blocked this input:", e)

    # Example 2: General/philosophical question
    try:
        result = await Runner.run(triage_agent, "What is the meaning of life?")
        print(result.final_output)
    except InputGuardrailTripwireTriggered as e:
        print("Guardrail blocked this input:", e)

if __name__ == "__main__":
    asyncio.run(main())
```

## 트레이스 확인

에이전트 실행 중 발생한 내용을 검토하려면 OpenAI Dashboard의 [Trace viewer](https://platform.openai.com/traces)로 이동하여 실행 트레이스를 확인하세요.

## 다음 단계

더 복잡한 에이전트 플로우를 구축하는 방법 알아보기:

- [에이전트](agents.md) 구성 방법 알아보기
- [에이전트 실행](running_agents.md) 알아보기
- [도구](tools.md), [가드레일](guardrails.md), [모델](models/index.md) 알아보기

================
File: docs/ko/release.md
================
---
search:
  exclude: true
---
# 릴리스 프로세스/변경 로그

이 프로젝트는 `0.Y.Z` 형식의 의미 버전 관리(semantic versioning)를 약간 수정한 방식을 따릅니다. 앞의 `0`은 SDK가 아직 빠르게 발전 중임을 나타냅니다. 각 구성 요소는 다음과 같이 증가합니다:

## 마이너(`Y`) 버전

베타로 표시되지 않은 모든 공개 인터페이스에 **호환성 파괴 변경**이 있을 경우 마이너 버전 `Y`를 올립니다. 예를 들어 `0.0.x`에서 `0.1.x`로 올라갈 때 호환성 파괴 변경이 포함될 수 있습니다.

호환성 파괴 변경을 피하려면, 프로젝트에서 `0.0.x` 버전에 고정할 것을 권장합니다.

## 패치(`Z`) 버전

호환성에 영향을 주지 않는 변경에 대해 `Z`를 증가시킵니다:

-   버그 수정
-   새로운 기능
-   비공개 인터페이스 변경
-   베타 기능 업데이트

## 호환성 파괴 변경 로그

### 0.6.0

이 버전에서는 기본 핸드오프 히스토리가 원문 사용자/assistant 턴을 노출하는 대신 단일 assistant 메시지로 패키징되어, 하위 에이전트가 간결하고 예측 가능한 요약을 받도록 변경되었습니다
- 기존의 단일 메시지 핸드오프 기록은 이제 기본적으로 `<CONVERSATION HISTORY>` 블록 앞에 "For context, here is the conversation so far between the user and the previous agent:"로 시작하여, 하위 에이전트가 명확하게 라벨링된 요약을 받도록 합니다

### 0.5.0

이 버전은 눈에 보이는 호환성 파괴 변경을 도입하지 않지만, 새로운 기능과 내부적으로 몇 가지 중요한 업데이트를 포함합니다:

- [SIP protocol connections](https://platform.openai.com/docs/guides/realtime-sip)을 처리하기 위한 `RealtimeRunner` 지원 추가
- Python 3.14와의 호환성을 위해 `Runner#run_sync`의 내부 로직을 대폭 수정

### 0.4.0

이 버전부터는 [openai](https://pypi.org/project/openai/) 패키지 v1.x 버전을 더 이상 지원하지 않습니다. 이 SDK와 함께 openai v2.x를 사용해 주세요.

### 0.3.0

이 버전에서는 Realtime API 지원이 gpt-realtime 모델과 해당 API 인터페이스(GA 버전)로 마이그레이션되었습니다.

### 0.2.0

이 버전에서는 일부 위치에서 `Agent`를 인수로 받던 것이 이제 `AgentBase`를 인수로 받도록 변경되었습니다. 예: MCP 서버의 `list_tools()` 호출. 이는 타입 변경에 불과하므로 여전히 `Agent` 객체를 받게 됩니다. 업데이트하려면 `Agent`를 `AgentBase`로 바꿔 타입 오류만 수정하면 됩니다.

### 0.1.0

이 버전에서는 [`MCPServer.list_tools()`][agents.mcp.server.MCPServer]에 `run_context`와 `agent`라는 두 개의 새로운 매개변수가 추가되었습니다. `MCPServer`를 상속하는 모든 클래스에 이 매개변수를 추가해야 합니다.

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

`Runner.run` 메서드를 호출하면 다음 중 하나를 받습니다:

- [`RunResult`][agents.result.RunResult] (`run` 또는 `run_sync` 호출 시)
- [`RunResultStreaming`][agents.result.RunResultStreaming] (`run_streamed` 호출 시)

이 둘은 모두 [`RunResultBase`][agents.result.RunResultBase]를 상속하며, 대부분의 유용한 정보가 여기에 담겨 있습니다.

## 최종 출력

[`final_output`][agents.result.RunResultBase.final_output] 프로퍼티에는 마지막으로 실행된 에이전트의 최종 출력이 담겨 있습니다. 이는 다음 중 하나입니다:

- 마지막 에이전트에 `output_type`이 정의되지 않은 경우 `str`
- 에이전트에 출력 타입이 정의된 경우 `last_agent.output_type` 타입의 객체

!!! note

    `final_output`의 타입은 `Any`입니다. 핸드오프 때문에 정적으로 타입을 지정할 수 없습니다. 핸드오프가 발생할 수 있으므로, 어떤 에이전트든 마지막 에이전트가 될 수 있고, 가능한 출력 타입 집합을 정적으로 알 수 없습니다.

## 다음 턴 입력

[`result.to_input_list()`][agents.result.RunResultBase.to_input_list]를 사용하여 결과를 입력 리스트로 변환하고, 제공한 원래 입력과 에이전트 실행 중 생성된 항목을 이어 붙일 수 있습니다. 이를 통해 한 번의 에이전트 실행 결과를 다른 실행에 전달하거나, 루프로 실행하면서 매번 새로운 사용자 입력을 덧붙이기 편리합니다.

## 마지막 에이전트

[`last_agent`][agents.result.RunResultBase.last_agent] 프로퍼티에는 마지막으로 실행된 에이전트가 담겨 있습니다. 애플리케이션에 따라, 다음에 사용자가 무언가를 입력할 때 유용한 경우가 많습니다. 예를 들어, 프런트라인 분류 에이전트가 언어별 에이전트로 핸드오프하는 경우, 마지막 에이전트를 저장해 두었다가 사용자가 다음에 메시지를 보낼 때 재사용할 수 있습니다.

## 새 항목

[`new_items`][agents.result.RunResultBase.new_items] 프로퍼티에는 실행 중 생성된 새 항목이 담겨 있습니다. 항목은 [`RunItem`][agents.items.RunItem]s입니다. 실행 항목은 LLM이 생성한 원문 항목을 래핑합니다.

- [`MessageOutputItem`][agents.items.MessageOutputItem]은 LLM의 메시지를 나타냅니다. 원문 항목은 생성된 메시지입니다.
- [`HandoffCallItem`][agents.items.HandoffCallItem]은 LLM이 핸드오프 도구를 호출했음을 나타냅니다. 원문 항목은 LLM의 도구 호출 항목입니다.
- [`HandoffOutputItem`][agents.items.HandoffOutputItem]은 핸드오프가 발생했음을 나타냅니다. 원문 항목은 핸드오프 도구 호출에 대한 도구 응답입니다. 항목에서 소스/타깃 에이전트에도 접근할 수 있습니다.
- [`ToolCallItem`][agents.items.ToolCallItem]은 LLM이 도구를 호출했음을 나타냅니다.
- [`ToolCallOutputItem`][agents.items.ToolCallOutputItem]은 도구가 호출되었음을 나타냅니다. 원문 항목은 도구 응답입니다. 항목에서 도구 출력에도 접근할 수 있습니다.
- [`ReasoningItem`][agents.items.ReasoningItem]은 LLM의 추론 항목을 나타냅니다. 원문 항목은 생성된 추론입니다.

## 기타 정보

### 가드레일 결과

[`input_guardrail_results`][agents.result.RunResultBase.input_guardrail_results]와 [`output_guardrail_results`][agents.result.RunResultBase.output_guardrail_results] 프로퍼티에는 (있는 경우) 가드레일 결과가 담겨 있습니다. 가드레일 결과에는 로깅하거나 저장하기 좋은 유용한 정보가 포함될 수 있으므로, 이를 제공해 드립니다.

도구 가드레일 결과는 [`tool_input_guardrail_results`][agents.result.RunResultBase.tool_input_guardrail_results]와 [`tool_output_guardrail_results`][agents.result.RunResultBase.tool_output_guardrail_results]로 별도 제공됩니다. 이 가드레일은 도구에 부착될 수 있으며, 해당 도구 호출은 에이전트 워크플로우 중에 가드레일을 실행합니다.

### 원문 응답

[`raw_responses`][agents.result.RunResultBase.raw_responses] 프로퍼티에는 LLM이 생성한 [`ModelResponse`][agents.items.ModelResponse]s가 담겨 있습니다.

### 원본 입력

[`input`][agents.result.RunResultBase.input] 프로퍼티에는 `run` 메서드에 제공한 원본 입력이 담겨 있습니다. 대부분의 경우 필요하지 않지만, 필요한 경우를 대비해 제공됩니다.

================
File: docs/ko/running_agents.md
================
---
search:
  exclude: true
---
# 에이전트 실행

[`Runner`][agents.run.Runner] 클래스를 통해 에이전트를 실행할 수 있습니다. 3가지 옵션이 있습니다:

1. [`Runner.run()`][agents.run.Runner.run]: 비동기로 실행되며 [`RunResult`][agents.result.RunResult]를 반환합니다
2. [`Runner.run_sync()`][agents.run.Runner.run_sync]: 동기 메서드이며 내부적으로 `.run()`을 실행합니다
3. [`Runner.run_streamed()`][agents.run.Runner.run_streamed]: 비동기로 실행되며 [`RunResultStreaming`][agents.result.RunResultStreaming]을 반환합니다. LLM을 스트리밍 모드로 호출하고, 수신되는 대로 이벤트를 스트리밍해 제공합니다

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

자세한 내용은 [results 가이드](results.md)를 참고하세요.

## 에이전트 루프

`Runner`에서 run 메서드를 사용할 때, 시작 에이전트와 입력을 전달합니다. 입력은 문자열(사용자 메시지로 간주)일 수도 있고, OpenAI Responses API의 항목들인 입력 아이템 리스트일 수도 있습니다.

그다음 runner는 루프를 실행합니다:

1. 현재 입력으로 현재 에이전트에 대해 LLM을 호출합니다
2. LLM이 출력을 생성합니다
    1. LLM이 `final_output`을 반환하면 루프를 종료하고 결과를 반환합니다
    2. LLM이 핸드오프를 수행하면 현재 에이전트와 입력을 업데이트하고 루프를 다시 실행합니다
    3. LLM이 도구 호출을 생성하면 해당 도구 호출을 실행하고 결과를 추가한 뒤 루프를 다시 실행합니다
3. 전달된 `max_turns`를 초과하면 [`MaxTurnsExceeded`][agents.exceptions.MaxTurnsExceeded] 예외를 발생시킵니다

!!! note

    LLM 출력이 "최종 출력(final output)"으로 간주되는 규칙은, 원하는 타입의 텍스트 출력을 생성하고 도구 호출이 없어야 한다는 점입니다.

## 스트리밍

스트리밍을 사용하면 LLM이 실행되는 동안 스트리밍 이벤트도 추가로 받을 수 있습니다. 스트림이 끝나면 [`RunResultStreaming`][agents.result.RunResultStreaming]에 실행에 대한 완전한 정보(생성된 모든 새 출력 포함)가 담깁니다. 스트리밍 이벤트는 `.stream_events()`로 받을 수 있습니다. 자세한 내용은 [streaming 가이드](streaming.md)를 참고하세요.

## 실행 구성

`run_config` 매개변수로 에이전트 실행에 대한 일부 전역 설정을 구성할 수 있습니다:

-   [`model`][agents.run.RunConfig.model]: 각 Agent가 가진 `model`과 무관하게 사용할 전역 LLM 모델을 설정할 수 있습니다
-   [`model_provider`][agents.run.RunConfig.model_provider]: 모델 이름을 조회하기 위한 모델 provider이며, 기본값은 OpenAI입니다
-   [`model_settings`][agents.run.RunConfig.model_settings]: 에이전트별 설정을 덮어씁니다. 예를 들어 전역 `temperature` 또는 `top_p`를 설정할 수 있습니다
-   [`input_guardrails`][agents.run.RunConfig.input_guardrails], [`output_guardrails`][agents.run.RunConfig.output_guardrails]: 모든 실행에 포함할 입력 또는 출력 가드레일 목록입니다
-   [`handoff_input_filter`][agents.run.RunConfig.handoff_input_filter]: 핸드오프에 입력 필터가 이미 있지 않은 경우, 모든 핸드오프에 적용할 전역 입력 필터입니다. 입력 필터를 사용하면 새 에이전트로 전송되는 입력을 편집할 수 있습니다. 자세한 내용은 [`Handoff.input_filter`][agents.handoffs.Handoff.input_filter] 문서를 참고하세요
-   [`nest_handoff_history`][agents.run.RunConfig.nest_handoff_history]: 다음 에이전트를 호출하기 전에 이전 대화를 단일 assistant 메시지로 접어 넣는 옵트인 베타 기능입니다. 중첩 핸드오프를 안정화하는 동안 기본값은 비활성화이며, 활성화하려면 `True`로 설정하거나 원문 대화를 그대로 전달하려면 `False`로 두세요. 모든 [`Runner` 메서드](agents.run.Runner)는 `RunConfig`를 전달하지 않으면 자동으로 생성하므로, 퀵스타트와 예제는 기본값(비활성)을 유지하며, 명시적인 [`Handoff.input_filter`][agents.handoffs.Handoff.input_filter] 콜백은 계속해서 이를 덮어씁니다. 개별 핸드오프는 [`Handoff.nest_handoff_history`][agents.handoffs.Handoff.nest_handoff_history]를 통해 이 설정을 재정의할 수 있습니다
-   [`handoff_history_mapper`][agents.run.RunConfig.handoff_history_mapper]: `nest_handoff_history`에 옵트인할 때마다 정규화된 대화 기록(히스토리 + 핸드오프 아이템)을 받는 선택적 callable입니다. 다음 에이전트로 전달할 입력 아이템의 정확한 리스트를 반환해야 하며, 전체 핸드오프 필터를 작성하지 않고도 내장 요약을 교체할 수 있습니다
-   [`tracing_disabled`][agents.run.RunConfig.tracing_disabled]: 전체 실행에 대해 [tracing](tracing.md)을 비활성화할 수 있습니다
-   [`tracing`][agents.run.RunConfig.tracing]: 이 실행의 exporter, 프로세서, 또는 트레이싱 메타데이터를 재정의하기 위해 [`TracingConfig`][agents.tracing.TracingConfig]를 전달합니다
-   [`trace_include_sensitive_data`][agents.run.RunConfig.trace_include_sensitive_data]: 트레이스에 LLM 및 도구 호출 입력/출력 같은 잠재적으로 민감한 데이터가 포함될지 여부를 구성합니다
-   [`workflow_name`][agents.run.RunConfig.workflow_name], [`trace_id`][agents.run.RunConfig.trace_id], [`group_id`][agents.run.RunConfig.group_id]: 실행의 트레이싱 워크플로 이름, trace ID, trace group ID를 설정합니다. 최소한 `workflow_name` 설정을 권장합니다. group ID는 여러 실행에 걸쳐 트레이스를 연결할 수 있게 해주는 선택적 필드입니다
-   [`trace_metadata`][agents.run.RunConfig.trace_metadata]: 모든 트레이스에 포함할 메타데이터입니다
-   [`session_input_callback`][agents.run.RunConfig.session_input_callback]: Sessions를 사용할 때 각 턴 전에 새 사용자 입력이 세션 히스토리와 어떻게 병합되는지 커스터마이즈합니다
-   [`call_model_input_filter`][agents.run.RunConfig.call_model_input_filter]: 모델 호출 직전에 완전히 준비된 모델 입력(instructions 및 입력 아이템)을 편집하는 훅입니다. 예: 히스토리 트리밍 또는 시스템 프롬프트 주입

중첩 핸드오프는 옵트인 베타로 제공됩니다. `RunConfig(nest_handoff_history=True)`를 전달하거나 특정 핸드오프에 대해 `handoff(..., nest_handoff_history=True)`를 설정해 접힌 대화 기록 동작을 활성화하세요. 원문 대화(기본값)를 유지하고 싶다면 플래그를 설정하지 않거나, 대화를 필요한 방식 그대로 전달하는 `handoff_input_filter`(또는 `handoff_history_mapper`)를 제공하세요. 커스텀 mapper를 작성하지 않고 생성된 요약에서 사용하는 래퍼 텍스트를 변경하려면 [`set_conversation_history_wrappers`][agents.handoffs.set_conversation_history_wrappers]를 호출하세요(기본값 복원은 [`reset_conversation_history_wrappers`][agents.handoffs.reset_conversation_history_wrappers]).

## 대화/채팅 스레드

어떤 run 메서드를 호출하든 하나 이상의 에이전트가 실행될 수 있으며(따라서 하나 이상의 LLM 호출이 발생), 이는 채팅 대화에서 단일 논리적 턴을 나타냅니다. 예를 들어:

1. 사용자 턴: 사용자가 텍스트를 입력
2. Runner 실행: 첫 번째 에이전트가 LLM을 호출하고 도구를 실행한 뒤 두 번째 에이전트로 핸드오프하며, 두 번째 에이전트가 더 많은 도구를 실행하고 출력을 생성

에이전트 실행이 끝나면 사용자에게 무엇을 보여줄지 선택할 수 있습니다. 예를 들어 에이전트들이 생성한 모든 새 아이템을 사용자에게 보여줄 수도 있고, 최종 출력만 보여줄 수도 있습니다. 어느 쪽이든 사용자가 후속 질문을 하면 run 메서드를 다시 호출할 수 있습니다.

### 수동 대화 관리

[`RunResultBase.to_input_list()`][agents.result.RunResultBase.to_input_list] 메서드를 사용해 다음 턴의 입력을 가져오며 대화 히스토리를 수동으로 관리할 수 있습니다:

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

### Sessions를 사용한 자동 대화 관리

더 간단한 접근으로, [Sessions](sessions/index.md)를 사용해 `.to_input_list()`를 수동으로 호출하지 않고도 대화 히스토리를 자동으로 처리할 수 있습니다:

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
-   서로 다른 session ID에 대해 별도의 대화 유지

자세한 내용은 [Sessions 문서](sessions/index.md)를 참고하세요.

### 서버 관리 대화

`to_input_list()` 또는 `Sessions`로 로컬에서 처리하는 대신, OpenAI 대화 상태 기능이 서버 측에서 대화 상태를 관리하도록 할 수도 있습니다. 이렇게 하면 과거 메시지를 모두 수동으로 다시 전송하지 않고도 대화 히스토리를 보존할 수 있습니다. 자세한 내용은 [OpenAI Conversation state 가이드](https://platform.openai.com/docs/guides/conversation-state?api-mode=responses)를 참고하세요.

OpenAI는 턴 간 상태를 추적하는 두 가지 방법을 제공합니다:

#### 1. `conversation_id` 사용

먼저 OpenAI Conversations API를 사용해 대화를 생성한 다음, 이후 모든 호출에서 해당 ID를 재사용합니다:

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

#### 2. `previous_response_id` 사용

또 다른 옵션은 **응답 체이닝(response chaining)**으로, 각 턴이 이전 턴의 response ID에 명시적으로 연결됩니다.

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

## Call model input filter

`call_model_input_filter`를 사용해 모델 호출 직전에 모델 입력을 편집하세요. 이 훅은 현재 에이전트, 컨텍스트, 그리고 결합된 입력 아이템(세션 히스토리가 있는 경우 포함)을 받고, 새 `ModelInputData`를 반환합니다.

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

`run_config`를 통해 실행별로 훅을 설정하거나 `Runner`의 기본값으로 설정해 민감한 데이터를 마스킹하고, 긴 히스토리를 트리밍하거나, 추가 시스템 가이던스를 주입할 수 있습니다.

## 장기 실행 에이전트 & Human in the loop

### Temporal

Agents SDK의 [Temporal](https://temporal.io/) 통합을 사용하면 휴먼인더루프 (HITL) 작업을 포함한 내구성 있는 장기 실행 워크플로를 실행할 수 있습니다. Temporal과 Agents SDK가 함께 장기 실행 작업을 완료하는 데모는 [이 비디오](https://www.youtube.com/watch?v=fFBZqzT4DD8)에서 확인할 수 있으며, 문서는 [여기](https://github.com/temporalio/sdk-python/tree/main/temporalio/contrib/openai_agents)에서 볼 수 있습니다. 

### Restate

Agents SDK의 [Restate](https://restate.dev/) 통합을 사용하면 사람 승인, 핸드오프, 세션 관리 등을 포함한 경량의 내구성 있는 에이전트를 사용할 수 있습니다. 이 통합은 Restate의 단일 바이너리 런타임을 의존성으로 필요로 하며, 프로세스/컨테이너 또는 서버리스 함수로 에이전트를 실행하는 것을 지원합니다.
자세한 내용은 [개요](https://www.restate.dev/blog/durable-orchestration-for-ai-agents-with-restate-and-openai-sdk)를 읽거나 [문서](https://docs.restate.dev/ai)를 확인하세요.

## 예외

SDK는 특정 경우에 예외를 발생시킵니다. 전체 목록은 [`agents.exceptions`][]에 있습니다. 개요는 다음과 같습니다:

-   [`AgentsException`][agents.exceptions.AgentsException]: SDK 내에서 발생하는 모든 예외의 베이스 클래스입니다. 다른 모든 구체적인 예외가 파생되는 일반 타입으로 사용됩니다
-   [`MaxTurnsExceeded`][agents.exceptions.MaxTurnsExceeded]: 에이전트 실행이 `Runner.run`, `Runner.run_sync`, 또는 `Runner.run_streamed` 메서드에 전달된 `max_turns` 제한을 초과할 때 발생합니다. 지정된 상호작용 턴 수 내에 에이전트가 작업을 완료하지 못했음을 나타냅니다
-   [`ModelBehaviorError`][agents.exceptions.ModelBehaviorError]: 기반 모델(LLM)이 예상치 못하거나 유효하지 않은 출력을 생성할 때 발생합니다. 예를 들면 다음이 포함됩니다:
    -   잘못된 형식의 JSON: 특히 특정 `output_type`이 정의된 경우, 모델이 도구 호출 또는 직접 출력에 대해 잘못된 JSON 구조를 제공할 때
    -   예상치 못한 도구 관련 실패: 모델이 예상되는 방식으로 도구를 사용하지 못할 때
-   [`UserError`][agents.exceptions.UserError]: SDK를 사용하는 코드 작성자(사용자)가 SDK 사용 중 오류를 만들었을 때 발생합니다. 일반적으로 잘못된 코드 구현, 유효하지 않은 구성, 또는 SDK API의 오용에서 비롯됩니다
-   [`InputGuardrailTripwireTriggered`][agents.exceptions.InputGuardrailTripwireTriggered], [`OutputGuardrailTripwireTriggered`][agents.exceptions.OutputGuardrailTripwireTriggered]: 각각 입력 가드레일 또는 출력 가드레일의 조건이 충족되었을 때 발생합니다. 입력 가드레일은 처리 전에 들어오는 메시지를 확인하고, 출력 가드레일은 전달 전에 에이전트의 최종 응답을 확인합니다

================
File: docs/ko/streaming.md
================
---
search:
  exclude: true
---
# 스트리밍

스트리밍을 사용하면 에이전트 실행이 진행되는 동안 업데이트를 구독할 수 있습니다. 이는 최종 사용자에게 진행 상태 업데이트와 부분 응답을 보여주는 데 유용합니다.

스트리밍을 사용하려면 [`Runner.run_streamed()`][agents.run.Runner.run_streamed]를 호출해 [`RunResultStreaming`][agents.result.RunResultStreaming]을 받으면 됩니다. `result.stream_events()`를 호출하면 아래에서 설명하는 [`StreamEvent`][agents.stream_events.StreamEvent] 객체의 비동기 스트림을 가져올 수 있습니다.

## 원문 응답 이벤트

[`RawResponsesStreamEvent`][agents.stream_events.RawResponsesStreamEvent]는 LLM에서 직접 전달되는 원문 이벤트입니다. 이들은 OpenAI Responses API 형식이며, 각 이벤트에는 유형(예: `response.created`, `response.output_text.delta` 등)과 데이터가 있습니다. 생성된 응답 메시지를 즉시 사용자에게 스트리밍하려는 경우 유용합니다.

예를 들어, 다음은 LLM이 생성하는 텍스트를 토큰 단위로 출력합니다.

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

## 실행 항목 이벤트와 에이전트 이벤트

[`RunItemStreamEvent`][agents.stream_events.RunItemStreamEvent]는 상위 수준의 이벤트입니다. 항목이 완전히 생성되었을 때를 알려줍니다. 이를 통해 각 토큰이 아니라 "메시지 생성됨", "도구 실행됨" 등의 수준에서 진행 상태 업데이트를 전달할 수 있습니다. 유사하게, [`AgentUpdatedStreamEvent`][agents.stream_events.AgentUpdatedStreamEvent]는 현재 에이전트가 변경될 때(예: 핸드오프 결과) 업데이트를 제공합니다.

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
# Tools

Tools 는 에이전트가 작업을 수행할 수 있게 해줍니다. 예를 들어 데이터를 가져오거나, 코드를 실행하거나, 외부 API 를 호출하거나, 심지어 컴퓨터를 사용하는 것까지 포함합니다. SDK 는 다섯 가지 카테고리를 지원합니다:

-   OpenAI 호스트하는 도구: OpenAI 서버에서 모델과 함께 실행됩니다
-   로컬 런타임 도구: 사용자의 환경에서 실행됩니다(컴퓨터 사용, shell, apply patch)
-   함수 호출: 어떤 Python 함수든 도구로 래핑합니다
-   Agents as tools: 전체 핸드오프 없이 에이전트를 호출 가능한 도구로 노출합니다
-   실험적: Codex tool: 도구 호출로 워크스페이스 범위의 Codex 작업을 실행합니다

## 호스티드 툴

OpenAI 는 [`OpenAIResponsesModel`][agents.models.openai_responses.OpenAIResponsesModel] 을 사용할 때 몇 가지 내장 도구를 제공합니다:

-   [`WebSearchTool`][agents.tool.WebSearchTool] 은 에이전트가 웹 검색을 할 수 있게 해줍니다
-   [`FileSearchTool`][agents.tool.FileSearchTool] 은 OpenAI 벡터 스토어에서 정보를 가져올 수 있게 해줍니다
-   [`CodeInterpreterTool`][agents.tool.CodeInterpreterTool] 은 LLM 이 샌드박스 환경에서 코드를 실행할 수 있게 해줍니다
-   [`HostedMCPTool`][agents.tool.HostedMCPTool] 은 원격 MCP 서버의 도구를 모델에 노출합니다
-   [`ImageGenerationTool`][agents.tool.ImageGenerationTool] 은 프롬프트로부터 이미지를 생성합니다

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

## 로컬 런타임 도구

로컬 런타임 도구는 사용자의 환경에서 실행되며, 사용자가 구현을 제공해야 합니다:

-   [`ComputerTool`][agents.tool.ComputerTool]: GUI/브라우저 자동화를 활성화하려면 [`Computer`][agents.computer.Computer] 또는 [`AsyncComputer`][agents.computer.AsyncComputer] 인터페이스를 구현합니다
-   [`ShellTool`][agents.tool.ShellTool] 또는 [`LocalShellTool`][agents.tool.LocalShellTool]: 명령을 실행할 수 있도록 셸 실행기를 제공합니다
-   [`ApplyPatchTool`][agents.tool.ApplyPatchTool]: 로컬에서 diff 를 적용하려면 [`ApplyPatchEditor`][agents.editor.ApplyPatchEditor] 를 구현합니다

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

어떤 Python 함수든 도구로 사용할 수 있습니다. Agents SDK 가 도구를 자동으로 설정합니다:

-   도구 이름은 Python 함수의 이름이 됩니다(또는 이름을 제공할 수 있습니다)
-   도구 설명은 함수의 docstring 에서 가져옵니다(또는 설명을 제공할 수 있습니다)
-   함수 입력에 대한 스키마는 함수의 인자에서 자동으로 생성됩니다
-   각 입력에 대한 설명은 비활성화하지 않는 한 함수의 docstring 에서 가져옵니다

함수 시그니처를 추출하기 위해 Python 의 `inspect` 모듈을 사용하며, docstring 파싱에는 [`griffe`](https://mkdocstrings.github.io/griffe/) 를, 스키마 생성에는 `pydantic` 를 사용합니다.

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

1.  함수 인자에는 어떤 Python 타입이든 사용할 수 있으며, 함수는 sync 또는 async 일 수 있습니다
2.  docstring 이 존재하면, 설명과 인자 설명을 캡처하는 데 사용됩니다
3.  함수는 선택적으로 `context` 를 받을 수 있습니다(반드시 첫 번째 인자여야 합니다). 또한 도구 이름, 설명, 사용할 docstring 스타일 등과 같은 오버라이드를 설정할 수 있습니다
4.  데코레이트된 함수를 tools 목록에 전달할 수 있습니다

??? note "출력 보기로 확장"

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

텍스트 출력 외에도, 함수 도구의 출력으로 하나 또는 여러 개의 이미지나 파일을 반환할 수 있습니다. 이를 위해 다음 중 무엇이든 반환할 수 있습니다:

-   이미지: [`ToolOutputImage`][agents.tool.ToolOutputImage] (또는 TypedDict 버전인 [`ToolOutputImageDict`][agents.tool.ToolOutputImageDict])
-   파일: [`ToolOutputFileContent`][agents.tool.ToolOutputFileContent] (또는 TypedDict 버전인 [`ToolOutputFileContentDict`][agents.tool.ToolOutputFileContentDict])
-   텍스트: 문자열 또는 문자열로 변환 가능한 객체, 또는 [`ToolOutputText`][agents.tool.ToolOutputText] (또는 TypedDict 버전인 [`ToolOutputTextDict`][agents.tool.ToolOutputTextDict])

### 커스텀 함수 도구

때로는 Python 함수를 도구로 사용하고 싶지 않을 수 있습니다. 원한다면 [`FunctionTool`][agents.tool.FunctionTool] 을 직접 만들 수 있습니다. 다음을 제공해야 합니다:

-   `name`
-   `description`
-   `params_json_schema`: 인자에 대한 JSON schema
-   `on_invoke_tool`: [`ToolContext`][agents.tool_context.ToolContext] 와 인자를 JSON 문자열로 받아, 도구 출력을 문자열로 반환해야 하는 async 함수

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

### 자동 인자 및 docstring 파싱

앞서 언급했듯이, 도구의 스키마를 추출하기 위해 함수 시그니처를 자동으로 파싱하고, 도구와 개별 인자의 설명을 추출하기 위해 docstring 을 파싱합니다. 참고 사항은 다음과 같습니다:

1. 시그니처 파싱은 `inspect` 모듈로 수행됩니다. 인자의 타입을 이해하기 위해 타입 어노테이션을 사용하고, 전체 스키마를 표현하기 위한 Pydantic 모델을 동적으로 빌드합니다. Python 기본 타입, Pydantic 모델, TypedDict 등 대부분의 타입을 지원합니다
2. docstring 파싱에는 `griffe` 를 사용합니다. 지원하는 docstring 형식은 `google`, `sphinx`, `numpy` 입니다. docstring 형식을 자동으로 감지하려고 시도하지만 best-effort 이며, `function_tool` 호출 시 명시적으로 설정할 수 있습니다. `use_docstring_info` 를 `False` 로 설정해 docstring 파싱을 비활성화할 수도 있습니다

스키마 추출 코드는 [`agents.function_schema`][] 에 있습니다.

## Agents as tools

일부 워크플로에서는 제어를 핸드오프하는 대신, 중앙 에이전트가 전문화된 에이전트 네트워크를 멀티 에이전트 오케스트레이션 하도록 하고 싶을 수 있습니다. 이를 위해 에이전트를 도구로 모델링할 수 있습니다.

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

`agent.as_tool` 함수는 에이전트를 도구로 쉽게 바꾸기 위한 편의 메서드입니다. 다만 모든 구성을 지원하지는 않습니다. 예를 들어 `max_turns` 를 설정할 수 없습니다. 고급 사용 사례에서는 도구 구현에서 `Runner.run` 을 직접 사용하세요:

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

### 커스텀 출력 추출

특정 경우에는 도구-에이전트의 출력을 중앙 에이전트에 반환하기 전에 수정하고 싶을 수 있습니다. 이는 다음과 같은 경우에 유용할 수 있습니다:

-   서브 에이전트의 채팅 기록에서 특정 정보(예: JSON 페이로드)를 추출하는 경우
-   에이전트의 최종 답변을 변환하거나 재포맷하는 경우(예: Markdown 을 일반 텍스트 또는 CSV 로 변환)
-   출력의 유효성을 검사하거나, 에이전트 응답이 누락되었거나 형식이 잘못된 경우 대체 값을 제공하는 경우

`as_tool` 메서드에 `custom_output_extractor` 인자를 제공하면 이를 수행할 수 있습니다:

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

### 중첩 에이전트 실행 스트리밍

`as_tool` 에 `on_stream` 콜백을 전달하면, 스트림이 완료된 후 최종 출력을 반환하면서도 중첩된 에이전트가 내보내는 스트리밍 이벤트를 수신할 수 있습니다.

```python
from agents import AgentToolStreamEvent


async def handle_stream(event: AgentToolStreamEvent) -> None:
    # Inspect the underlying StreamEvent along with agent metadata.
    print(f"[stream] {event['agent']['name']} :: {event['event'].type}")


billing_agent_tool = billing_agent.as_tool(
    tool_name="billing_helper",
    tool_description="Answer billing questions.",
    on_stream=handle_stream,  # Can be sync or async.
)
```

기대할 사항:

- 이벤트 타입은 `StreamEvent["type"]` 와 동일합니다: `raw_response_event`, `run_item_stream_event`, `agent_updated_stream_event`
- `on_stream` 을 제공하면 중첩 에이전트는 자동으로 스트리밍 모드로 실행되며, 최종 출력을 반환하기 전에 스트림을 모두 소비합니다
- 핸들러는 동기 또는 비동기일 수 있으며, 각 이벤트는 도착하는 순서대로 전달됩니다
- `tool_call_id` 는 모델 도구 호출을 통해 도구가 호출될 때 존재합니다. 직접 호출에서는 `None` 일 수 있습니다
- 전체 실행 가능한 샘플은 `examples/agent_patterns/agents_as_tools_streaming.py` 를 참고하세요

### 조건부 도구 활성화

`is_enabled` 매개변수를 사용하면 런타임에 에이전트 도구를 조건부로 활성화하거나 비활성화할 수 있습니다. 이를 통해 컨텍스트, 사용자 선호도, 런타임 조건에 따라 LLM 에서 사용 가능한 도구를 동적으로 필터링할 수 있습니다.

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

-   **불리언 값**: `True` (항상 활성화) 또는 `False` (항상 비활성화)
-   **호출 가능한 함수**: `(context, agent)` 를 받아 불리언을 반환하는 함수
-   **비동기 함수**: 복잡한 조건부 로직을 위한 async 함수

비활성화된 도구는 런타임에서 LLM 에 완전히 숨겨지므로, 다음과 같은 용도에 유용합니다:

-   사용자 권한에 따른 기능 게이팅
-   환경별 도구 가용성(dev vs prod)
-   서로 다른 도구 구성을 A/B 테스트
-   런타임 상태에 따른 동적 도구 필터링

## 실험적: Codex tool

`codex_tool` 은 Codex CLI 를 래핑하여 에이전트가 도구 호출 중에 워크스페이스 범위의 작업(shell, 파일 편집, MCP 도구)을 실행할 수 있게 합니다.
이 표면은 실험적이며 변경될 수 있습니다.

```python
from agents import Agent
from agents.extensions.experimental.codex import ThreadOptions, codex_tool

agent = Agent(
    name="Codex Agent",
    instructions="Use the codex tool to inspect the workspace and answer the question.",
    tools=[
        codex_tool(
            sandbox_mode="workspace-write",
            working_directory="/path/to/repo",
            default_thread_options=ThreadOptions(
                model="gpt-5.2-codex",
                network_access_enabled=True,
                web_search_enabled=False,
            ),
            persist_session=True,
        )
    ],
)
```

알아둘 사항:

-   인증: `CODEX_API_KEY` (권장) 또는 `OPENAI_API_KEY` 를 설정하거나, `codex_options={"api_key": "..."}` 를 전달하세요
-   런타임: `codex_options.base_url` 이 CLI base URL 을 오버라이드하며, `codex_options.codex_path_override` (또는 `CODEX_PATH`) 가 바이너리를 선택합니다
-   환경: `codex_options.env` 가 서브프로세스 환경을 완전히 제어합니다. 제공되면 서브프로세스는 `os.environ` 을 상속하지 않습니다
-   입력: 도구 호출에는 `inputs` 에 최소 1개 항목이 포함되어야 하며, `{ "type": "text", "text": ... }` 또는 `{ "type": "local_image", "path": ... }` 여야 합니다
-   안전: `sandbox_mode` 를 `working_directory` 와 함께 사용하세요. Git repo 밖에서는 `skip_git_repo_check=True` 를 설정하세요
-   동작: `persist_session=True` 는 단일 Codex 스레드를 재사용하고 `thread_id` 를 반환합니다
-   스트리밍: `on_stream` 은 Codex 이벤트(reasoning, 명령 실행, MCP 도구 호출, 파일 변경, 웹 검색)를 수신합니다
-   출력: 결과에는 `response`, `usage`, `thread_id` 가 포함되며, usage 는 `RunContextWrapper.usage` 에 추가됩니다
-   구조: `output_schema` 는 typed 출력이 필요할 때 구조화된 Codex 응답을 강제합니다
-   전체 실행 가능한 샘플은 `examples/tools/codex.py` 를 참고하세요

## 함수 도구에서 오류 처리

`@function_tool` 로 함수 도구를 만들 때 `failure_error_function` 을 전달할 수 있습니다. 이는 도구 호출이 크래시했을 때 LLM 에 오류 응답을 제공하는 함수입니다.

-   기본값(즉, 아무것도 전달하지 않으면)으로는 오류가 발생했음을 LLM 에 알리는 `default_tool_error_function` 을 실행합니다
-   자체 오류 함수를 전달하면, 대신 그것을 실행하고 응답을 LLM 에 보냅니다
-   명시적으로 `None` 을 전달하면, 모든 도구 호출 오류가 사용자가 처리할 수 있도록 다시 raise 됩니다. 이는 모델이 잘못된 JSON 을 생성한 경우 `ModelBehaviorError` 일 수도 있고, 코드가 크래시한 경우 `UserError` 일 수도 있습니다

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

`FunctionTool` 객체를 수동으로 만드는 경우에는 `on_invoke_tool` 함수 내부에서 오류를 처리해야 합니다.

================
File: docs/ko/tracing.md
================
---
search:
  exclude: true
---
# 트레이싱

Agents SDK에는 내장 트레이싱이 포함되어 있으며, 에이전트 실행 중 발생하는 이벤트에 대한 포괄적인 기록을 수집합니다. LLM 생성, 도구 호출, 핸드오프, 가드레일, 그리고 발생하는 사용자 정의 이벤트까지 포함됩니다. [Traces 대시보드](https://platform.openai.com/traces)를 사용하면 개발 및 프로덕션 환경에서 워크플로를 디버그하고, 시각화하고, 모니터링할 수 있습니다.

!!!note

    트레이싱은 기본적으로 활성화되어 있습니다. 트레이싱을 비활성화하는 방법은 두 가지가 있습니다:

    1. env var `OPENAI_AGENTS_DISABLE_TRACING=1`을 설정하여 전역적으로 트레이싱을 비활성화할 수 있습니다
    2. [`agents.run.RunConfig.tracing_disabled`][]를 `True`로 설정하여 단일 실행에 대해 트레이싱을 비활성화할 수 있습니다

***OpenAI의 API를 사용하는 Zero Data Retention (ZDR) 정책 하에서 운영되는 조직의 경우 트레이싱을 사용할 수 없습니다.***

## Traces 및 spans

-   **Traces**는 “workflow”의 단일 엔드투엔드 작업을 나타냅니다. Traces는 Spans로 구성됩니다. Traces에는 다음 속성이 있습니다:
    -   `workflow_name`: 논리적 워크플로 또는 앱입니다. 예: "Code generation" 또는 "Customer service"
    -   `trace_id`: trace의 고유 ID입니다. 전달하지 않으면 자동으로 생성됩니다. 형식은 `trace_<32_alphanumeric>`이어야 합니다
    -   `group_id`: 동일한 대화에서 나온 여러 trace를 연결하기 위한 선택적 그룹 ID입니다. 예: 채팅 스레드 ID를 사용할 수 있습니다
    -   `disabled`: True이면 trace가 기록되지 않습니다
    -   `metadata`: trace를 위한 선택적 메타데이터입니다
-   **Spans**는 시작 및 종료 시간이 있는 작업을 나타냅니다. Spans에는 다음이 포함됩니다:
    -   `started_at` 및 `ended_at` 타임스탬프
    -   소속 trace를 나타내는 `trace_id`
    -   이 Span의 상위 Span을 가리키는 `parent_id`(있는 경우)
    -   Span에 대한 정보인 `span_data` 예: `AgentSpanData`에는 Agent에 대한 정보가, `GenerationSpanData`에는 LLM 생성에 대한 정보가 포함되는 등

## 기본 트레이싱

기본적으로 SDK는 다음을 트레이싱합니다:

-   전체 `Runner.{run, run_sync, run_streamed}()`는 `trace()`로 감싸집니다
-   에이전트가 실행될 때마다 `agent_span()`으로 감싸집니다
-   LLM 생성은 `generation_span()`으로 감싸집니다
-   함수 도구 호출은 각각 `function_span()`으로 감싸집니다
-   가드레일은 `guardrail_span()`으로 감싸집니다
-   핸드오프는 `handoff_span()`으로 감싸집니다
-   오디오 입력(음성-텍스트 변환)은 `transcription_span()`으로 감싸집니다
-   오디오 출력(텍스트-음성 변환)은 `speech_span()`으로 감싸집니다
-   관련 오디오 span은 `speech_group_span()` 아래에 부모-자식 관계로 연결될 수 있습니다

기본적으로 trace 이름은 "Agent workflow"입니다. `trace`를 사용하면 이 이름을 설정할 수 있으며, [`RunConfig`][agents.run.RunConfig]로 이름과 기타 속성을 구성할 수도 있습니다.

또한 [사용자 정의 trace 프로세서](#custom-tracing-processors)를 설정하여 trace를 다른 목적지로 푸시할 수 있습니다(대체 목적지 또는 보조 목적지로).

## 상위 수준 trace

때로는 `run()`을 여러 번 호출하더라도 하나의 trace에 포함시키고 싶을 수 있습니다. 이 경우 전체 코드를 `trace()`로 감싸면 됩니다.

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

1. `Runner.run`에 대한 두 호출이 `with trace()`로 감싸져 있으므로, 각각이 두 개의 trace를 생성하는 대신 전체 trace의 일부가 됩니다.

## trace 생성

[`trace()`][agents.tracing.trace] 함수를 사용하여 trace를 만들 수 있습니다. trace는 시작과 종료가 필요합니다. 이를 위한 방법은 두 가지가 있습니다:

1. **권장**: trace를 컨텍스트 매니저로 사용합니다. 즉, `with trace(...) as my_trace`처럼 사용합니다. 그러면 적절한 시점에 trace가 자동으로 시작되고 종료됩니다
2. [`trace.start()`][agents.tracing.Trace.start] 및 [`trace.finish()`][agents.tracing.Trace.finish]를 수동으로 호출할 수도 있습니다

현재 trace는 Python의 [`contextvar`](https://docs.python.org/3/library/contextvars.html)로 추적됩니다. 즉, 동시성 환경에서도 자동으로 동작합니다. trace를 수동으로 시작/종료하는 경우 현재 trace를 업데이트하기 위해 `start()`/`finish()`에 `mark_as_current` 및 `reset_current`를 전달해야 합니다.

## span 생성

다양한 [`*_span()`][agents.tracing.create] 메서드를 사용해 span을 만들 수 있습니다. 일반적으로 span을 수동으로 만들 필요는 없습니다. 사용자 정의 span 정보를 추적하기 위한 [`custom_span()`][agents.tracing.custom_span] 함수가 제공됩니다.

span은 자동으로 현재 trace의 일부가 되며, Python의 [`contextvar`](https://docs.python.org/3/library/contextvars.html)로 추적되는 가장 가까운 현재 span 아래에 중첩됩니다.

## 민감 데이터

일부 span은 잠재적으로 민감한 데이터를 캡처할 수 있습니다.

`generation_span()`은 LLM 생성의 입력/출력을 저장하며, `function_span()`은 함수 호출의 입력/출력을 저장합니다. 이는 민감한 데이터를 포함할 수 있으므로 [`RunConfig.trace_include_sensitive_data`][agents.run.RunConfig.trace_include_sensitive_data]를 통해 해당 데이터 캡처를 비활성화할 수 있습니다.

마찬가지로, Audio span은 기본적으로 입력 및 출력 오디오에 대한 base64 인코딩 PCM 데이터를 포함합니다. [`VoicePipelineConfig.trace_include_sensitive_audio_data`][agents.voice.pipeline_config.VoicePipelineConfig.trace_include_sensitive_audio_data]를 구성하여 이 오디오 데이터 캡처를 비활성화할 수 있습니다.

기본적으로 `trace_include_sensitive_data`는 `True`입니다. 앱 실행 전에 `OPENAI_AGENTS_TRACE_INCLUDE_SENSITIVE_DATA` 환경 변수를 `true/1` 또는 `false/0`로 내보내 코드 없이 기본값을 설정할 수 있습니다.

## 사용자 정의 트레이싱 프로세서

트레이싱의 상위 수준 아키텍처는 다음과 같습니다:

-   초기화 시 trace 생성을 담당하는 전역 [`TraceProvider`][agents.tracing.setup.TraceProvider]를 생성합니다
-   `TraceProvider`를 [`BatchTraceProcessor`][agents.tracing.processors.BatchTraceProcessor]로 구성합니다. 이 프로세서는 trace/span을 배치로 [`BackendSpanExporter`][agents.tracing.processors.BackendSpanExporter]에 전송하며, 이 exporter는 span과 trace를 배치로 OpenAI 백엔드에 내보냅니다

이 기본 설정을 사용자 정의하여 trace를 대체/추가 백엔드로 전송하거나 exporter 동작을 수정하려면 두 가지 옵션이 있습니다:

1. [`add_trace_processor()`][agents.tracing.add_trace_processor]를 사용하면 준비되는 즉시 trace와 span을 수신하는 **추가** trace 프로세서를 추가할 수 있습니다. 이를 통해 OpenAI 백엔드로 trace를 전송하는 것 외에 자체 처리를 수행할 수 있습니다
2. [`set_trace_processors()`][agents.tracing.set_trace_processors]를 사용하면 기본 프로세서를 사용자 정의 trace 프로세서로 **대체**할 수 있습니다. 즉, 이를 수행하는 `TracingProcessor`를 포함하지 않으면 trace는 OpenAI 백엔드로 전송되지 않습니다

## OpenAI가 아닌 모델로 트레이싱

OpenAI API 키를 OpenAI가 아닌 모델과 함께 사용하면 트레이싱을 비활성화하지 않고도 OpenAI Traces 대시보드에서 무료 트레이싱을 활성화할 수 있습니다.

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

단일 실행에 대해서만 다른 트레이싱 키가 필요하다면 전역 exporter를 변경하는 대신 `RunConfig`로 전달하세요.

```python
from agents import Runner, RunConfig

await Runner.run(
    agent,
    input="Hello",
    run_config=RunConfig(tracing={"api_key": "sk-tracing-123"}),
)
```

## 참고
- Openai Traces 대시보드에서 무료 trace를 확인하세요

## 외부 트레이싱 프로세서 목록

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

## Mixing and matching models

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

## Common issues with using other LLM providers

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
# Guide

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

## Event handling

The session streams events that you can listen to by iterating over the session object. Events include audio output chunks, transcription results, tool execution start and end, agent handoffs, and errors. Key events to handle include:

-   **audio**: Raw audio data from the agent's response
-   **audio_end**: Agent finished speaking
-   **audio_interrupted**: User interrupted the agent
-   **tool_start/tool_end**: Tool execution lifecycle
-   **handoff**: Agent handoff occurred
-   **error**: Error occurred during processing

For complete event details, see [`RealtimeSessionEvent`][agents.realtime.events.RealtimeSessionEvent].

## Guardrails

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

## Audio processing

Send audio to the session using [`session.send_audio(audio_bytes)`][agents.realtime.session.RealtimeSession.send_audio] or send text using [`session.send_message()`][agents.realtime.session.RealtimeSession.send_message].

For audio output, listen for `audio` events and play the audio data through your preferred audio library. Make sure to listen for `audio_interrupted` events to stop playback immediately and clear any queued audio when the user interrupts the agent.

## SIP integration

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

## Direct model access

You can access the underlying model to add custom listeners or perform advanced operations:

```python
# Add a custom listener to the model
session.model.add_listener(my_custom_listener)
```

This gives you direct access to the [`RealtimeModel`][agents.realtime.model.RealtimeModel] interface for advanced use cases where you need lower-level control over the connection.

## Examples

For complete working examples, check out the [examples/realtime directory](https://github.com/openai/openai-agents-python/tree/main/examples/realtime) which includes demos with and without UI components.

================
File: docs/realtime/quickstart.md
================
# Quickstart

Realtime agents enable voice conversations with your AI agents using OpenAI's Realtime API. This guide walks you through creating your first realtime voice agent.

!!! warning "Beta feature"
Realtime agents are in beta. Expect some breaking changes as we improve the implementation.

## Prerequisites

-   Python 3.9 or higher
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

## Complete example

Here's a complete working example:

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

## Configuration options

### Model settings

-   `model_name`: Choose from available realtime models (e.g., `gpt-realtime`)
-   `voice`: Select voice (`alloy`, `echo`, `fable`, `onyx`, `nova`, `shimmer`)
-   `modalities`: Enable text or audio (`["text"]` or `["audio"]`)

### Audio settings

-   `input_audio_format`: Format for input audio (`pcm16`, `g711_ulaw`, `g711_alaw`)
-   `output_audio_format`: Format for output audio
-   `input_audio_transcription`: Transcription configuration

### Turn detection

-   `type`: Detection method (`server_vad`, `semantic_vad`)
-   `threshold`: Voice activity threshold (0.0-1.0)
-   `silence_duration_ms`: Silence duration to detect turn end
-   `prefix_padding_ms`: Audio padding before speech

## Next steps

-   [Learn more about realtime agents](guide.md)
-   Check out working examples in the [examples/realtime](https://github.com/openai/openai-agents-python/tree/main/examples/realtime) folder
-   Add tools to your agent
-   Implement handoffs between agents
-   Set up guardrails for safety

## Authentication

Make sure your OpenAI API key is set in your environment:

```bash
export OPENAI_API_KEY="your-api-key-here"
```

Or pass it directly when creating the session:

```python
session = await runner.run(model_config={"api_key": "your-api-key"})
```

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
File: docs/ref/tracing/config.md
================
# `Config`

::: agents.tracing.config

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
File: docs/ref/result.md
================
# `Results`

::: agents.result

================
File: docs/ref/run_context.md
================
# `Run context`

::: agents.run_context

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

## How it works

When session memory is enabled:

1. **Before each run**: The runner automatically retrieves the conversation history for the session and prepends it to the input items.
2. **After each run**: All new items generated during the run (user input, assistant responses, tool calls, etc.) are automatically stored in the session.
3. **Context preservation**: Each subsequent run with the same session includes the full conversation history, allowing the agent to maintain context.

This eliminates the need to manually call `.to_input_list()` and manage conversation state between runs.

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

## Session types

The SDK provides several session implementations for different use cases:

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

Use `OpenAIResponsesCompactionSession` to compact session history with the Responses API (`responses.compact`). It wraps an underlying session and can automatically compact after each turn based on `should_trigger_compaction`.

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

## Session management

### Session ID naming

Use meaningful session IDs that help you organize conversations:

-   User-based: `"user_12345"`
-   Thread-based: `"thread_abc123"`
-   Context-based: `"support_ticket_456"`

### Memory persistence

-   Use in-memory SQLite (`SQLiteSession("session_id")`) for temporary conversations
-   Use file-based SQLite (`SQLiteSession("session_id", "path/to/db.sqlite")`) for persistent conversations
-   Use SQLAlchemy-powered sessions (`SQLAlchemySession("session_id", engine=engine, create_tables=True)`) for production systems with existing databases supported by SQLAlchemy
-   Use Dapr state store sessions (`DaprSession.from_address("session_id", state_store_name="statestore", dapr_address="localhost:50001")`) for production cloud-native deployments with support for 
30+ database backends with built-in telemetry, tracing, and data isolation
-   Use OpenAI-hosted storage (`OpenAIConversationsSession()`) when you prefer to store history in the OpenAI Conversations API
-   Use encrypted sessions (`EncryptedSession(session_id, underlying_session, encryption_key)`) to wrap any session with transparent encryption and TTL-based expiration
-   Consider implementing custom session backends for other production systems (Redis, Django, etc.) for more advanced use cases

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
    elif event.type == "voice_stream_event_error"
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
-   [`trace_metadata`][agents.voice.pipeline_config.VoicePipelineConfig.tracing_disabled]: Additional metadata to include with the trace.

================
File: docs/zh/models/index.md
================
---
search:
  exclude: true
---
# 模型

Agents SDK 提供对 OpenAI 模型的开箱即用支持，分为两种形式：

-   **推荐**：[`OpenAIResponsesModel`][agents.models.openai_responses.OpenAIResponsesModel]，使用新的 [Responses API](https://platform.openai.com/docs/api-reference/responses) 调用 OpenAI API。
-   [`OpenAIChatCompletionsModel`][agents.models.openai_chatcompletions.OpenAIChatCompletionsModel]，使用 [Chat Completions API](https://platform.openai.com/docs/api-reference/chat) 调用 OpenAI API。

## OpenAI 模型

当你在初始化 `Agent` 时未指定模型，将使用默认模型。当前默认是 [`gpt-4.1`](https://platform.openai.com/docs/models/gpt-4.1)，以兼容性与低延迟为目标。如果你有权限，我们推荐将智能体设置为 [`gpt-5.2`](https://platform.openai.com/docs/models/gpt-5.2) 以获得更高质量，同时保持显式的 `model_settings`。

如果你想切换到诸如 [`gpt-5.2`](https://platform.openai.com/docs/models/gpt-5.2) 等其他模型，有两种方式来配置你的智能体。

### 默认模型

首先，如果你希望对所有未设置自定义模型的智能体一致使用某个特定模型，请在运行智能体之前设置 `OPENAI_DEFAULT_MODEL` 环境变量。

```bash
export OPENAI_DEFAULT_MODEL=gpt-5.2
python3 my_awesome_agent.py
```

其次，你可以通过 `RunConfig` 为一次运行设置默认模型。如果你未为某个智能体设置模型，将使用该次运行的模型。

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

当你以这种方式使用任意 GPT-5.x 模型（例如 [`gpt-5.2`](https://platform.openai.com/docs/models/gpt-5.2)）时，SDK 会应用默认的 `ModelSettings`。它会设置对大多数用例效果最佳的选项。要调整默认模型的推理努力（reasoning effort），请传入你自己的 `ModelSettings`：

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

为了更低延迟，建议在 `gpt-5.2` 上使用 `reasoning.effort="none"`。gpt-4.1 系列（包括 mini 与 nano 变体）也仍然是构建交互式智能体应用的稳健选择。

#### 非 GPT-5 模型

如果你传入非 GPT-5 的模型名称且未提供自定义 `model_settings`，SDK 会回退到与任何模型兼容的通用 `ModelSettings`。

## 非 OpenAI 模型

你可以通过 [LiteLLM 集成](./litellm.md) 使用大多数其他非 OpenAI 模型。首先，安装 litellm 依赖组：

```bash
pip install "openai-agents[litellm]"
```

然后，使用带有 `litellm/` 前缀的任意[受支持模型](https://docs.litellm.ai/docs/providers)：

```python
claude_agent = Agent(model="litellm/anthropic/claude-3-5-sonnet-20240620", ...)
gemini_agent = Agent(model="litellm/gemini/gemini-2.5-flash-preview-04-17", ...)
```

### 使用非 OpenAI 模型的其他方式

你还可以通过另外 3 种方式集成其他 LLM 提供商（示例见[此处](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/)）：

1. [`set_default_openai_client`][agents.set_default_openai_client] 适用于你希望全局使用 `AsyncOpenAI` 实例作为 LLM 客户端的场景。这适用于 LLM 提供商提供 OpenAI 兼容 API 端点的情况，你可以设置 `base_url` 与 `api_key`。参见可配置示例：[examples/model_providers/custom_example_global.py](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/custom_example_global.py)。
2. [`ModelProvider`][agents.models.interface.ModelProvider] 位于 `Runner.run` 层级。这让你可以指定“本次运行中所有智能体都使用自定义模型提供商”。参见可配置示例：[examples/model_providers/custom_example_provider.py](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/custom_example_provider.py)。
3. [`Agent.model`][agents.agent.Agent.model] 允许你在特定 `Agent` 实例上指定模型。这使你可以为不同智能体混用不同提供商。参见可配置示例：[examples/model_providers/custom_example_agent.py](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/custom_example_agent.py)。使用大多数可用模型的一个简单方式是通过 [LiteLLM 集成](./litellm.md)。

在你没有来自 `platform.openai.com` 的 API key 的情况下，我们建议通过 `set_tracing_disabled()` 禁用追踪，或设置一个[不同的追踪进程](../tracing.md)。

!!! note

    在这些示例中，我们使用 Chat Completions API/模型，因为大多数 LLM 提供商尚不支持 Responses API。如果你的 LLM 提供商支持它，我们建议使用 Responses。

## 模型混合与匹配

在单个工作流中，你可能希望为每个智能体使用不同模型。例如，你可以用更小、更快的模型做分流（triage），同时用更大、更强的模型处理复杂任务。在配置 [`Agent`][agents.Agent] 时，你可以通过以下方式选择特定模型：

1. 传入模型名称。
2. 传入任意模型名称 + 一个能将该名称映射到 Model 实例的 [`ModelProvider`][agents.models.interface.ModelProvider]。
3. 直接提供一个 [`Model`][agents.models.interface.Model] 实现。

!!!note

    虽然我们的 SDK 同时支持 [`OpenAIResponsesModel`][agents.models.openai_responses.OpenAIResponsesModel] 与 [`OpenAIChatCompletionsModel`][agents.models.openai_chatcompletions.OpenAIChatCompletionsModel] 这两种形态，但我们建议每个工作流使用单一模型形态，因为两种形态支持的功能与工具集合不同。如果你的工作流需要混用模型形态，请确保你使用的所有功能在两者上都可用。

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

1. 直接设置 OpenAI 模型名称。
2. 提供一个 [`Model`][agents.models.interface.Model] 实现。

当你想进一步配置智能体所用模型时，可以传入 [`ModelSettings`][agents.models.interface.ModelSettings]，它提供诸如 temperature 等可选的模型配置参数。

```python
from agents import Agent, ModelSettings

english_agent = Agent(
    name="English agent",
    instructions="You only speak English",
    model="gpt-4.1",
    model_settings=ModelSettings(temperature=0.1),
)
```

此外，当你使用 OpenAI 的 Responses API 时，[还有一些其他可选参数](https://platform.openai.com/docs/api-reference/responses/create)（例如 `user`、`service_tier` 等）。如果它们在顶层不可用，你也可以使用 `extra_args` 来传入。

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

## 使用其他 LLM 提供商的常见问题

### 追踪客户端错误 401

如果你遇到与追踪相关的错误，这是因为追踪会上传到 OpenAI 服务，而你没有 OpenAI API key。你有三种解决方案：

1. 完全禁用追踪：[`set_tracing_disabled(True)`][agents.set_tracing_disabled]。
2. 为追踪设置 OpenAI key：[`set_tracing_export_api_key(...)`][agents.set_tracing_export_api_key]。该 API key 仅用于上传追踪，并且必须来自 [platform.openai.com](https://platform.openai.com/)。
3. 使用非 OpenAI 的追踪处理器。参见[追踪文档](../tracing.md#custom-tracing-processors)。

### Responses API 支持

SDK 默认使用 Responses API，但大多数其他 LLM 提供商尚不支持它。因此你可能会看到 404 或类似问题。要解决此问题，你有两个选项：

1. 调用 [`set_default_openai_api("chat_completions")`][agents.set_default_openai_api]。当你通过环境变量设置 `OPENAI_API_KEY` 与 `OPENAI_BASE_URL` 时，这种方式可用。
2. 使用 [`OpenAIChatCompletionsModel`][agents.models.openai_chatcompletions.OpenAIChatCompletionsModel]。示例见[此处](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers/)。

### structured outputs 支持

一些模型提供商不支持 [structured outputs](https://platform.openai.com/docs/guides/structured-outputs)。这有时会导致类似如下的错误：

```

BadRequestError: Error code: 400 - {'error': {'message': "'response_format.type' : value is not one of the allowed values ['text','json_object']", 'type': 'invalid_request_error'}}

```

这是某些模型提供商的不足——它们支持 JSON 输出，但不允许你指定用于输出的 `json_schema`。我们正在修复这一问题，但我们建议依赖确实支持 JSON schema 输出的提供商，否则你的应用会经常因为 JSON 格式错误而中断。

## 跨提供商混用模型

你需要注意不同模型提供商之间的功能差异，否则可能会遇到错误。例如，OpenAI 支持 structured outputs、多模态输入，以及由OpenAI托管的工具文件检索与网络检索，但许多其他提供商不支持这些功能。请注意以下限制：

-   不要向不理解它们的提供商发送不受支持的 `tools`
-   在调用仅文本模型之前，过滤掉多模态输入
-   注意：不支持结构化 JSON 输出的提供商偶尔会生成无效 JSON。

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
# 指南

本指南深入介绍如何使用 OpenAI Agents SDK 的实时能力构建语音智能体。

!!! warning "测试版功能"
实时智能体处于测试阶段。随着实现的改进，可能会出现不兼容的变更。

## 概述

实时智能体支持对话式流程，能够实时处理音频和文本输入，并以实时音频进行响应。它们与 OpenAI 的 Realtime API 保持持久连接，从而实现低延迟的自然语音对话，并能优雅地处理打断。

## 架构

### 核心组件

实时系统由以下关键组件组成：

-   **RealtimeAgent**: 一个智能体，配置了指令（instructions）、工具（tools）和任务转移（handoffs）。
-   **RealtimeRunner**: 管理配置。你可以调用 `runner.run()` 获取一个会话。
-   **RealtimeSession**: 单次交互会话。通常在每次用户开始对话时创建一个，并保持到对话结束。
-   **RealtimeModel**: 底层模型接口（通常是 OpenAI 的 WebSocket 实现）

### 会话流程

典型的实时会话遵循如下流程：

1. **创建 RealtimeAgent**，并配置指令、工具和任务转移。
2. **设置 RealtimeRunner**，传入智能体和相关配置选项。
3. **启动会话**，使用 `await runner.run()`，它会返回一个 RealtimeSession。
4. **发送音频或文本消息** 到会话，使用 `send_audio()` 或 `send_message()`。
5. **监听事件**，通过遍历会话对象来接收事件——事件包括音频输出、转录文本、工具调用、任务转移和错误。
6. **处理打断**，当用户在智能体说话时插话，会自动停止当前音频生成。

会话会维护对话历史，并管理与实时模型的持久连接。

## 智能体配置

RealtimeAgent 的工作方式与常规 Agent 类似，但有一些关键差异。完整的 API 详情请参阅 [`RealtimeAgent`][agents.realtime.agent.RealtimeAgent] API 参考。

与常规智能体的关键差异：

-   模型选择在会话级配置，而非智能体级。
-   不支持 structured outputs（不支持 `outputType`）。
-   可为每个智能体配置语音，但在第一个智能体开始说话后不可再更改。
-   其他功能如工具、任务转移和指令的工作方式相同。

## 会话配置

### 模型设置

会话配置允许你控制底层实时模型的行为。你可以配置模型名称（例如 `gpt-realtime`）、语音选择（alloy、echo、fable、onyx、nova、shimmer）以及支持的模态（文本和/或音频）。音频格式可分别为输入与输出设置，默认是 PCM16。

### 音频配置

音频设置控制会话如何处理语音输入与输出。你可以使用如 Whisper 的模型配置输入音频转录，设置语言偏好，并提供转录提示以提高领域术语的准确性。回合检测设置用于控制智能体何时开始和结束响应，可配置语音活动检测阈值、静音时长以及检测语音前后的填充。

## 工具与函数

### 添加工具

与常规智能体相同，实时智能体支持在对话过程中执行的工具调用：

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

任务转移可在专用智能体之间传递会话。

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

## 事件处理

会话会流式传输事件，你可以通过遍历会话对象来监听。事件包括音频输出分片、转录结果、工具执行开始与结束、智能体任务转移以及错误。需要重点处理的事件包括：

-   **audio**: 智能体响应的原始音频数据
-   **audio_end**: 智能体完成发声
-   **audio_interrupted**: 用户打断了智能体
-   **tool_start/tool_end**: 工具执行生命周期
-   **handoff**: 发生智能体任务转移
-   **error**: 处理过程中出现错误

完整事件详情参见 [`RealtimeSessionEvent`][agents.realtime.events.RealtimeSessionEvent]。

## 安全防护措施

实时智能体仅支持输出安全防护措施。这些防护以防抖方式周期性运行（而非每个词都运行），以避免实时生成过程中的性能问题。默认防抖长度为 100 个字符，可配置。

安全防护措施可以直接附加到 `RealtimeAgent`，或通过会话的 `run_config` 提供。来自两处的安全防护会共同运行。

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

当安全防护被触发时，会生成 `guardrail_tripped` 事件，并可中断智能体当前的响应。防抖行为有助于在安全与实时性能之间取得平衡。与文本智能体不同，实时智能体在防护触发时不会抛出异常（Exception）。

## 音频处理

通过 [`session.send_audio(audio_bytes)`][agents.realtime.session.RealtimeSession.send_audio] 向会话发送音频，或通过 [`session.send_message()`][agents.realtime.session.RealtimeSession.send_message] 发送文本。

对于音频输出，监听 `audio` 事件，并使用你偏好的音频库播放音频数据。务必监听 `audio_interrupted` 事件，以在用户打断智能体时立即停止播放并清空任何已排队的音频。

## SIP 集成

你可以将实时智能体接入通过 [Realtime Calls API](https://platform.openai.com/docs/guides/realtime-sip) 到达的电话。SDK 提供了 [`OpenAIRealtimeSIPModel`][agents.realtime.openai_realtime.OpenAIRealtimeSIPModel]，它在通过 SIP 协商媒体的同时复用相同的智能体流程。

要使用它，将该模型实例传入 runner，并在启动会话时提供 SIP 的 `call_id`。该呼叫 ID 由指示来电的 webhook 传递。

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

当来电方挂断时，SIP 会话结束，实时连接会自动关闭。完整话音示例参见 [`examples/realtime/twilio_sip`](https://github.com/openai/openai-agents-python/tree/main/examples/realtime/twilio_sip)。

## 直接模型访问

你可以访问底层模型以添加自定义监听器或执行高级操作：

```python
# Add a custom listener to the model
session.model.add_listener(my_custom_listener)
```

这为你提供对 [`RealtimeModel`][agents.realtime.model.RealtimeModel] 接口的直接访问，适用于需要更底层连接控制的高级用例。

## 代码示例

要查看完整可运行的示例，请参阅 [examples/realtime 目录](https://github.com/openai/openai-agents-python/tree/main/examples/realtime)，其中包含带有和不带 UI 组件的演示。

================
File: docs/zh/realtime/quickstart.md
================
---
search:
  exclude: true
---
# 快速入门

实时智能体通过 OpenAI 的 Realtime API 让你的 AI 智能体具备语音对话能力。本指南将带你创建第一个实时语音智能体。

!!! warning "测试版功能"
实时智能体处于测试版。在我们改进实现的过程中，可能会有不兼容的变更。

## 先决条件

- Python 3.9 或更高版本
- OpenAI API key
- 对 OpenAI Agents SDK 的基本了解

## 安装

如果尚未安装，请安装 OpenAI Agents SDK：

```bash
pip install openai-agents
```

## 创建你的第一个实时智能体

### 1. 导入所需组件

```python
import asyncio
from agents.realtime import RealtimeAgent, RealtimeRunner
```

### 2. 创建一个实时智能体

```python
agent = RealtimeAgent(
    name="Assistant",
    instructions="You are a helpful voice assistant. Keep your responses conversational and friendly.",
)
```

### 3. 设置运行器

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

### 4. 启动会话

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

## 完整示例

下面是一个完整可运行示例：

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

## 配置选项

### 模型设置

- `model_name`: 从可用的实时模型中选择（例如，`gpt-realtime`）
- `voice`: 选择语音（`alloy`、`echo`、`fable`、`onyx`、`nova`、`shimmer`）
- `modalities`: 启用文本或音频（`["text"]` 或 `["audio"]`）

### 音频设置

- `input_audio_format`: 输入音频格式（`pcm16`、`g711_ulaw`、`g711_alaw`）
- `output_audio_format`: 输出音频格式
- `input_audio_transcription`: 转录配置

### 轮次检测

- `type`: 检测方法（`server_vad`、`semantic_vad`）
- `threshold`: 语音活动阈值（0.0-1.0）
- `silence_duration_ms`: 用于检测轮次结束的静音时长
- `prefix_padding_ms`: 语音前的音频填充

## 后续步骤

- [进一步了解实时智能体](guide.md)
- 查看 [examples/realtime](https://github.com/openai/openai-agents-python/tree/main/examples/realtime) 文件夹中的可运行示例
- 为你的智能体添加工具
- 实现智能体之间的任务转移
- 设置安全防护措施以确保安全

## 身份验证

确保在环境中设置了 OpenAI API key：

```bash
export OPENAI_API_KEY="your-api-key-here"
```

或在创建会话时直接传入：

```python
session = await runner.run(model_config={"api_key": "your-api-key"})
```

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

Agents SDK 提供内置的会话记忆，可在多次智能体运行之间自动维护对话历史，从而无需在回合之间手动处理 `.to_input_list()`。

Sessions 为特定会话存储对话历史，使智能体能够在无需显式手动记忆管理的情况下保持上下文。这对于构建聊天应用或多轮对话尤其有用——在这些场景中，你希望智能体记住先前的交互。

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

## 工作原理

启用会话记忆后：

1. **每次运行前**：runner 会自动检索该会话的对话历史，并将其前置到输入项中。
2. **每次运行后**：运行期间生成的所有新项（用户输入、助手回复、工具调用等）都会自动存入会话。
3. **上下文保留**：后续使用相同会话的每次运行都会包含完整对话历史，使智能体能够保持上下文。

这消除了手动调用 `.to_input_list()` 以及在多次运行之间管理对话状态的需要。

## 记忆操作

### 基本操作

Sessions 支持多种用于管理对话历史的操作：

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

### 使用 pop_item 进行更正

当你想要撤销或修改对话中的最后一项时，`pop_item` 方法特别有用：

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

## 会话类型

SDK 为不同用例提供了多种会话实现：

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

使用 `OpenAIResponsesCompactionSession` 通过 Responses API（`responses.compact`）压缩会话历史。它包装了一个底层会话，并可根据 `should_trigger_compaction` 在每个回合后自动压缩。

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

默认情况下，一旦达到候选阈值，压缩会在每个回合后运行。

#### 自动压缩可能会阻塞流式传输

压缩会清空并重写会话历史，因此 SDK 会等待压缩完成后才认为该次运行结束。在流式模式下，这意味着如果压缩开销较大，`run.stream_events()` 可能会在最后一个输出 token 之后仍保持打开几秒钟。

如果你希望低延迟的流式传输或更快的回合切换，请禁用自动压缩，并在回合之间（或空闲时间）自行调用 `run_compaction()`。你可以根据自己的标准决定何时强制压缩。

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

默认的轻量级会话实现，使用 SQLite：

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

### SQLAlchemy 会话

使用任意 SQLAlchemy 支持的数据库的生产级会话：

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

详见 [SQLAlchemy Sessions](sqlalchemy_session.md) 获取完整文档。

### 高级 SQLite 会话

增强版 SQLite 会话，支持对话分支、用量分析和结构化查询：

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

详见 [Advanced SQLite Sessions](advanced_sqlite_session.md) 获取完整文档。

### 加密会话

适用于任何会话实现的透明加密包装器：

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

详见 [Encrypted Sessions](encrypted_session.md) 获取完整文档。

### 其他会话类型

还有一些内置选项。请参考 `examples/memory/` 以及 `extensions/memory/` 下的源代码。

## 会话管理

### 会话 ID 命名

使用有意义的会话 ID，帮助你组织对话：

-   基于用户：`"user_12345"`
-   基于线程：`"thread_abc123"`
-   基于上下文：`"support_ticket_456"`

### 记忆持久化

-   对临时对话使用内存 SQLite（`SQLiteSession("session_id")`）
-   对持久化对话使用基于文件的 SQLite（`SQLiteSession("session_id", "path/to/db.sqlite")`）
-   对生产系统（使用 SQLAlchemy 支持的现有数据库）使用由 SQLAlchemy 驱动的会话（`SQLAlchemySession("session_id", engine=engine, create_tables=True)`）
-   对生产级云原生部署使用 Dapr 状态存储会话（`DaprSession.from_address("session_id", state_store_name="statestore", dapr_address="localhost:50001")`），支持 30+ 数据库后端，并内置遥测、追踪和数据隔离
-   当你更希望将历史存储在 OpenAI Conversations API 中时，使用由OpenAI托管的存储（`OpenAIConversationsSession()`）
-   使用加密会话（`EncryptedSession(session_id, underlying_session, encryption_key)`）以透明加密与基于 TTL 的过期机制包装任意会话
-   对更高级用例，考虑为其他生产系统（Redis、Django 等）实现自定义会话后端

### 多个会话

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

下面是一个展示会话记忆实际效果的完整示例：

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

你可以通过创建一个遵循 [`Session`][agents.memory.session.Session] 协议的类来实现自己的会话记忆：

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

社区开发了额外的会话实现：

| 包 | 描述 |
|---------|-------------|
| [openai-django-sessions](https://pypi.org/project/openai-django-sessions/) | 基于 Django ORM 的会话实现，适用于任何 Django 支持的数据库（PostgreSQL、MySQL、SQLite 等） |

如果你构建了一个会话实现，欢迎提交文档 PR 将其添加到这里！

## API 参考

如需详细的 API 文档，请参见：

-   [`Session`][agents.memory.session.Session] - 协议接口
-   [`OpenAIConversationsSession`][agents.memory.OpenAIConversationsSession] - OpenAI Conversations API 实现
-   [`OpenAIResponsesCompactionSession`][agents.memory.openai_responses_compaction_session.OpenAIResponsesCompactionSession] - Responses API 压缩包装器
-   [`SQLiteSession`][agents.memory.sqlite_session.SQLiteSession] - 基础 SQLite 实现
-   [`SQLAlchemySession`][agents.extensions.memory.sqlalchemy_session.SQLAlchemySession] - 由 SQLAlchemy 驱动的实现
-   [`DaprSession`][agents.extensions.memory.dapr_session.DaprSession] - Dapr 状态存储实现
-   [`AdvancedSQLiteSession`][agents.extensions.memory.advanced_sqlite_session.AdvancedSQLiteSession] - 带分支与分析能力的增强 SQLite
-   [`EncryptedSession`][agents.extensions.memory.encrypt_session.EncryptedSession] - 适用于任何会话的加密包装器

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
# 流水线与工作流

[`VoicePipeline`][agents.voice.pipeline.VoicePipeline] 是一个类，可将你的智能体工作流轻松转换为语音应用。你传入要运行的工作流，流水线会负责转录输入音频、检测音频结束时间、在正确时机调用你的工作流，并将工作流输出重新合成为音频。

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

## 配置流水线

创建流水线时，你可以设置以下内容：

1. [`workflow`][agents.voice.workflow.VoiceWorkflowBase]：每次有新音频被转录时运行的代码。
2. 使用的 [`speech-to-text`][agents.voice.model.STTModel] 与 [`text-to-speech`][agents.voice.model.TTSModel] 模型。
3. [`config`][agents.voice.pipeline_config.VoicePipelineConfig]：用于配置例如：
    - 模型提供方，可将模型名称映射到实际模型
    - 追踪，包括是否禁用追踪、是否上传音频文件、工作流名称、追踪 ID 等
    - TTS 与 STT 模型的设置，如提示词、语言与所用数据类型

## 运行流水线

你可以通过 [`run()`][agents.voice.pipeline.VoicePipeline.run] 方法运行流水线，该方法允许以两种形式传入音频输入：

1. [`AudioInput`][agents.voice.input.AudioInput]：当你已有完整音频并只需为其生成结果时使用。适用于无需检测说话者何时结束的场景；例如，使用预录音频，或在明确知道用户何时结束说话的按键说话应用中。
2. [`StreamedAudioInput`][agents.voice.input.StreamedAudioInput]：当你需要检测用户何时结束说话时使用。它允许你在检测到音频片段时持续推送，语音流水线会通过“活动检测（activity detection）”在正确时机自动运行智能体工作流。

## 结果

语音流水线运行的结果是 [`StreamedAudioResult`][agents.voice.result.StreamedAudioResult]。该对象允许你在事件发生时进行流式接收。包含几类 [`VoiceStreamEvent`][agents.voice.events.VoiceStreamEvent]：

1. [`VoiceStreamEventAudio`][agents.voice.events.VoiceStreamEventAudio]：包含一段音频数据。
2. [`VoiceStreamEventLifecycle`][agents.voice.events.VoiceStreamEventLifecycle]：通知诸如轮次开始或结束等生命周期事件。
3. [`VoiceStreamEventError`][agents.voice.events.VoiceStreamEventError]：错误事件。

```python

result = await pipeline.run(input)

async for event in result.stream():
    if event.type == "voice_stream_event_audio":
        # play audio
    elif event.type == "voice_stream_event_lifecycle":
        # lifecycle
    elif event.type == "voice_stream_event_error"
        # error
    ...
```

## 最佳实践

### 打断

Agents SDK 目前未对 [`StreamedAudioInput`][agents.voice.input.StreamedAudioInput] 提供任何内置的打断支持。相反，每检测到一个轮次，都会单独触发一次你的工作流运行。若你希望在应用内处理打断，可监听 [`VoiceStreamEventLifecycle`][agents.voice.events.VoiceStreamEventLifecycle] 事件。`turn_started` 表示新的轮次已被转录且开始处理；`turn_ended` 则在相应轮次的全部音频派发完毕后触发。你可以利用这些事件在模型开始一个轮次时静音说话者的麦克风，并在你为该轮次的相关音频全部输出后取消静音。

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

与[智能体的追踪方式](../tracing.md)相同，语音管线也会被自动追踪。

你可以阅读上面的追踪文档以了解基础信息，此外还可以通过[`VoicePipelineConfig`][agents.voice.pipeline_config.VoicePipelineConfig]对管线的追踪进行配置。

关键的追踪相关字段包括：

- [`tracing_disabled`][agents.voice.pipeline_config.VoicePipelineConfig.tracing_disabled]: 控制是否禁用追踪。默认启用追踪。
- [`trace_include_sensitive_data`][agents.voice.pipeline_config.VoicePipelineConfig.trace_include_sensitive_data]: 控制追踪是否包含潜在敏感数据，如音频转写。这仅适用于语音管线，不涉及你的工作流内部发生的任何内容。
- [`trace_include_sensitive_audio_data`][agents.voice.pipeline_config.VoicePipelineConfig.trace_include_sensitive_audio_data]: 控制追踪是否包含音频数据。
- [`workflow_name`][agents.voice.pipeline_config.VoicePipelineConfig.workflow_name]: 跟踪工作流的名称。
- [`group_id`][agents.voice.pipeline_config.VoicePipelineConfig.group_id]: 跟踪的`group_id`，可用于关联多个跟踪。
- [`trace_metadata`][agents.voice.pipeline_config.VoicePipelineConfig.tracing_disabled]: 要随跟踪一起包含的其他元数据。

================
File: docs/zh/agents.md
================
---
search:
  exclude: true
---
# 智能体

智能体是你应用中的核心构建块。智能体是一个大语言模型（LLM），并配置了 instructions 和 tools。

## 基本配置

你将配置的智能体最常见属性包括：

-   `name`: 必需的字符串，用于标识你的智能体。
-   `instructions`: 也称为开发者消息或系统提示词。
-   `model`: 使用哪个 LLM，以及可选的 `model_settings`，用于配置 temperature、top_p 等模型调优参数。
-   `prompt`: 使用 OpenAI 的 Responses API 时，通过 id（以及变量）引用一个提示词模板。
-   `tools`: 智能体可用于完成任务的工具。
-   `mcp_servers`: 为智能体提供工具的 MCP 服务。参见 [MCP 指南](mcp.md)。
-   `reset_tool_choice`: 是否在一次工具调用后重置 `tool_choice`（默认：`True`），以避免工具使用循环。参见[强制使用工具](#forcing-tool-use)。

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

请按以下步骤使用：

1. 前往 https://platform.openai.com/playground/prompts
2. 创建一个新的提示词变量 `poem_style`。
3. 创建一个系统提示词，内容为：

    ```
    Write a poem in {{poem_style}}
    ```

4. 使用 `--prompt-id` 标志运行该示例。

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

智能体对其 `context` 类型是泛型的。上下文是一种依赖注入工具：它是你创建并传入 `Runner.run()` 的对象，会被传递给每个智能体、工具、任务转移等，并作为本次智能体运行的依赖与状态集合。你可以提供任何 Python 对象作为上下文。

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

默认情况下，智能体产生纯文本（即 `str`）输出。如果你希望智能体产生特定类型的输出，可以使用 `output_type` 参数。一个常见选择是使用 [Pydantic](https://docs.pydantic.dev/) 对象，但我们支持任何可被 Pydantic 的 [TypeAdapter](https://docs.pydantic.dev/latest/api/type_adapter/) 包装的类型——dataclasses、lists、TypedDict 等。

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

    当你传入 `output_type` 时，这会告诉模型使用 [structured outputs](https://platform.openai.com/docs/guides/structured-outputs)，而不是常规的纯文本响应。

## 多智能体系统设计模式

构建多智能体系统的方法有很多，但我们通常看到两种广泛适用的模式：

1. 管理者（Agents as tools）：一个中央管理者/编排器将专门的子智能体作为工具来调用，并保留对对话的控制权。
2. 任务转移：对等智能体将控制权转移给一个专门的智能体，由其接管对话。这是去中心化的。

更多细节请参见[我们关于构建智能体的实用指南](https://cdn.openai.com/business-guides-and-resources/a-practical-guide-to-building-agents.pdf)。

### 管理者（Agents as tools）

`customer_facing_agent` 处理所有用户交互，并调用作为工具暴露的专门子智能体。更多内容请阅读 [tools](tools.md#agents-as-tools) 文档。

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

任务转移是智能体可以委派给的子智能体。当发生一次任务转移时，被委派的智能体会接收对话历史并接管对话。该模式支持模块化、专门化的智能体，使其在单一任务上表现出色。更多内容请阅读 [handoffs](handoffs.md) 文档。

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

在大多数情况下，你可以在创建智能体时提供 instructions。不过，你也可以通过一个函数提供动态 instructions。该函数会接收智能体和上下文，并且必须返回提示词。支持普通函数与 `async` 函数。

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

有时，你希望观察智能体的生命周期。例如，你可能希望记录事件，或在某些事件发生时预取数据。你可以通过 `hooks` 属性接入智能体生命周期。对 [`AgentHooks`][agents.lifecycle.AgentHooks] 类进行子类化，并重写你感兴趣的方法。

## 安全防护措施

安全防护措施允许你在智能体运行的同时，并行对用户输入执行检查/校验，并在智能体输出生成后对其进行检查。例如，你可以筛查用户输入和智能体输出的相关性。更多内容请阅读 [guardrails](guardrails.md) 文档。

## 克隆/复制智能体

通过调用智能体的 `clone()` 方法，你可以复制一个 Agent，并可选地更改任意属性。

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

提供一组工具并不总是意味着 LLM 会使用工具。你可以通过设置 [`ModelSettings.tool_choice`][agents.model_settings.ModelSettings.tool_choice] 来强制使用工具。有效取值为：

1. `auto`：允许 LLM 决定是否使用工具。
2. `required`：要求 LLM 使用工具（但它可以智能地决定使用哪个工具）。
3. `none`：要求 LLM _不_ 使用工具。
4. 设置为特定字符串，例如 `my_tool`：要求 LLM 使用该特定工具。

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
- `"stop_on_first_tool"`：将第一次工具调用的输出直接作为最终响应，不再进行后续的 LLM 处理。

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

- `StopAtTools(stop_at_tool_names=[...])`：如果调用了任意指定工具则停止，并将其输出作为最终响应。

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

- `ToolsToFinalOutputFunction`：一个自定义函数，用于处理工具结果并决定停止还是继续让 LLM 运行。

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

    为防止无限循环，框架会在一次工具调用后自动将 `tool_choice` 重置为 "auto"。该行为可通过 [`agent.reset_tool_choice`][agents.agent.Agent.reset_tool_choice] 配置。无限循环的原因是：工具结果会被发送给 LLM，而 LLM 又会因为 `tool_choice` 生成另一次工具调用，如此往复，无穷无尽。

================
File: docs/zh/config.md
================
---
search:
  exclude: true
---
# 配置 SDK

## API 密钥与客户端

默认情况下，SDK 在被导入后会立即查找 `OPENAI_API_KEY` 环境变量，用于 LLM 请求与追踪。如果你无法在应用启动前设置该环境变量，可以使用 [set_default_openai_key()][agents.set_default_openai_key] 函数来设置密钥。

```python
from agents import set_default_openai_key

set_default_openai_key("sk-...")
```

或者，你也可以配置要使用的 OpenAI 客户端。默认情况下，SDK 会创建一个 `AsyncOpenAI` 实例，使用来自环境变量的 API 密钥或上面设置的默认密钥。你可以通过 [set_default_openai_client()][agents.set_default_openai_client] 函数来更改这一点。

```python
from openai import AsyncOpenAI
from agents import set_default_openai_client

custom_client = AsyncOpenAI(base_url="...", api_key="...")
set_default_openai_client(custom_client)
```

最后，你还可以自定义所使用的 OpenAI API。默认情况下，我们使用 OpenAI Responses API。你可以通过 [set_default_openai_api()][agents.set_default_openai_api] 函数将其覆盖为使用 Chat Completions API。

```python
from agents import set_default_openai_api

set_default_openai_api("chat_completions")
```

## 追踪

追踪默认启用。默认情况下它使用上文部分中的 OpenAI API 密钥（即环境变量或你设置的默认密钥）。你可以使用 [`set_tracing_export_api_key`][agents.set_tracing_export_api_key] 函数专门设置用于追踪的 API 密钥。

```python
from agents import set_tracing_export_api_key

set_tracing_export_api_key("sk-...")
```

如果你在使用默认导出器时需要将追踪归因到特定组织或项目，请在应用启动前设置这些环境变量：

```bash
export OPENAI_ORG_ID="org_..."
export OPENAI_PROJECT_ID="proj_..."
```

你也可以在不更改全局导出器的情况下，为每次运行设置一个追踪 API 密钥。

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

## 调试日志

SDK 有两个 Python logger，且未设置任何 handler。默认情况下，这意味着警告和错误会发送到 `stdout`，而其他日志会被抑制。

要启用详细日志，请使用 [`enable_verbose_stdout_logging()`][agents.enable_verbose_stdout_logging] 函数。

```python
from agents import enable_verbose_stdout_logging

enable_verbose_stdout_logging()
```

或者，你也可以通过添加 handler、filter、formatter 等来自定义日志。你可以在 [Python logging guide](https://docs.python.org/3/howto/logging.html) 中了解更多。

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

某些日志可能包含敏感数据（例如，用户数据）。如果你希望禁止记录这些数据，请设置以下环境变量。

要禁用记录 LLM 输入与输出：

```bash
export OPENAI_AGENTS_DONT_LOG_MODEL_DATA=1
```

要禁用记录工具输入与输出：

```bash
export OPENAI_AGENTS_DONT_LOG_TOOL_DATA=1
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

请在[仓库](https://github.com/openai/openai-agents-python/tree/main/examples)的 examples 部分查看该 SDK 的多种示例实现。这些示例被组织为若干目录，用于展示不同的模式与能力。

## 目录

-   **[agent_patterns](https://github.com/openai/openai-agents-python/tree/main/examples/agent_patterns):**
    本目录中的示例展示常见的智能体设计模式，例如

    -   确定性工作流
    -   将智能体作为工具
    -   并行智能体执行
    -   条件式工具使用
    -   输入/输出安全防护措施
    -   以 LLM 作为评审
    -   路由
    -   流式传输安全防护措施

-   **[basic](https://github.com/openai/openai-agents-python/tree/main/examples/basic):**
    这些代码示例展示 SDK 的基础能力，例如

    -   Hello world 示例（默认模型、GPT-5、开放权重模型）
    -   智能体生命周期管理
    -   动态系统提示词
    -   流式传输输出（文本、条目、函数调用参数）
    -   提示词模板
    -   文件处理（本地与远程、图像与 PDF）
    -   用量追踪
    -   非严格输出类型
    -   先前响应 ID 的使用

-   **[customer_service](https://github.com/openai/openai-agents-python/tree/main/examples/customer_service):**
    航空公司的客户服务系统示例。

-   **[financial_research_agent](https://github.com/openai/openai-agents-python/tree/main/examples/financial_research_agent):**
    金融研究智能体，展示了用于金融数据分析的智能体与工具的结构化研究工作流。

-   **[handoffs](https://github.com/openai/openai-agents-python/tree/main/examples/handoffs):**
    查看带消息过滤的智能体任务转移的实用示例。

-   **[hosted_mcp](https://github.com/openai/openai-agents-python/tree/main/examples/hosted_mcp):**
    展示如何使用托管的 MCP（Model Context Protocol）连接器与审批。

-   **[mcp](https://github.com/openai/openai-agents-python/tree/main/examples/mcp):**
    学习如何使用 MCP（Model Context Protocol）构建智能体，包括：

    -   文件系统示例代码
    -   Git 示例代码
    -   MCP 提示词服务示例代码
    -   SSE（Server-Sent Events）示例代码
    -   可流式传输的 HTTP 示例代码

-   **[memory](https://github.com/openai/openai-agents-python/tree/main/examples/memory):**
    不同的智能体记忆实现示例，包括：

    -   SQLite 会话存储
    -   高级 SQLite 会话存储
    -   Redis 会话存储
    -   SQLAlchemy 会话存储
    -   加密的会话存储
    -   OpenAI 会话存储

-   **[model_providers](https://github.com/openai/openai-agents-python/tree/main/examples/model_providers):**
    了解如何在 SDK 中使用非 OpenAI 模型，包括自定义提供方与 LiteLLM 集成。

-   **[realtime](https://github.com/openai/openai-agents-python/tree/main/examples/realtime):**
    展示如何使用 SDK 构建实时体验的示例，包括：

    -   Web 应用
    -   命令行界面
    -   Twilio 集成

-   **[reasoning_content](https://github.com/openai/openai-agents-python/tree/main/examples/reasoning_content):**
    展示如何处理推理内容与 structured outputs 的示例。

-   **[research_bot](https://github.com/openai/openai-agents-python/tree/main/examples/research_bot):**
    简易的深度研究克隆，展示复杂的多智能体研究工作流。

-   **[tools](https://github.com/openai/openai-agents-python/tree/main/examples/tools):**
    学习如何实现由OpenAI托管的工具，例如：

    -   网络检索与带过滤器的网络检索
    -   文件检索
    -   Code interpreter
    -   计算机操作
    -   图像生成

-   **[voice](https://github.com/openai/openai-agents-python/tree/main/examples/voice):**
    查看语音智能体示例，使用我们的 TTS 与 STT 模型，包括流式语音示例。

================
File: docs/zh/guardrails.md
================
---
search:
  exclude: true
---
# 安全防护措施

安全防护措施可用于检查和验证用户输入与智能体输出。比如，假设你有一个智能体使用非常智能（因此也很慢/昂贵）的模型来处理客户请求。你不希望恶意用户让该模型帮他们做数学作业。因此，你可以用一个快速/廉价的模型先运行一层安全防护措施。如果检测到恶意使用，它可以立刻抛出错误并阻止昂贵模型的运行，从而节省时间和成本（使用阻塞式安全防护措施时；在并行安全防护措施下，昂贵模型可能会在防护完成前就已开始运行。详见下文“执行模式”）。

安全防护措施分为两类：

1. 输入安全防护措施运行在初始用户输入上
2. 输出安全防护措施运行在最终智能体输出上

## 输入安全防护措施

输入安全防护措施分三步运行：

1. 首先，安全防护措施接收传给智能体的相同输入。
2. 接着，防护函数运行以产生一个[`GuardrailFunctionOutput`][agents.guardrail.GuardrailFunctionOutput]，随后被包装为[`InputGuardrailResult`][agents.guardrail.InputGuardrailResult]。
3. 最后，我们检查[`.tripwire_triggered`][agents.guardrail.GuardrailFunctionOutput.tripwire_triggered]是否为 true。若为 true，将抛出[`InputGuardrailTripwireTriggered`][agents.exceptions.InputGuardrailTripwireTriggered]异常，以便你恰当地响应用户或处理异常。

!!! 注意

    输入安全防护措施用于运行在用户输入上，因此只有当该智能体是“第一个”智能体时，它的安全防护措施才会运行。你或许会好奇，为什么是把`guardrails`属性放在智能体上，而不是传给`Runner.run`？这是因为安全防护措施往往与具体的智能体相关——不同智能体会运行不同的防护措施，因此将代码就近放置有助于可读性。

### 执行模式

输入安全防护措施支持两种执行模式：

- **并行执行**（默认，`run_in_parallel=True`）：安全防护与智能体执行并发进行。由于两者同时启动，延迟最佳。然而，如果防护失败，智能体在被取消前可能已经消耗了 token 并执行了工具。
- **阻塞执行**（`run_in_parallel=False`）：安全防护在智能体启动之前运行并完成。如果触发了绊线，智能体将不会执行，从而避免 token 消耗与工具调用。这在成本优化以及需要避免工具调用副作用时尤为理想。

## 输出安全防护措施

输出安全防护措施分三步运行：

1. 首先，安全防护措施接收智能体产生的输出。
2. 接着，防护函数运行以产生一个[`GuardrailFunctionOutput`][agents.guardrail.GuardrailFunctionOutput]，随后被包装为[`OutputGuardrailResult`][agents.guardrail.OutputGuardrailResult]。
3. 最后，我们检查[`.tripwire_triggered`][agents.guardrail.GuardrailFunctionOutput.tripwire_triggered]是否为 true。若为 true，将抛出[`OutputGuardrailTripwireTriggered`][agents.exceptions.OutputGuardrailTripwireTriggered]异常，以便你恰当地响应用户或处理异常。

!!! 注意

    输出安全防护措施用于运行在最终的智能体输出上，因此只有当该智能体是“最后一个”智能体时，它的安全防护措施才会运行。与输入安全防护类似，这是因为防护措施往往与具体的智能体相关——不同智能体会运行不同的防护措施，因此将代码就近放置有助于可读性。

    输出安全防护措施总是在智能体完成之后运行，因此不支持`run_in_parallel`参数。

## 工具安全防护措施

工具安全防护措施包装**工具调用**，允许你在执行前后验证或阻止工具调用。它们在工具本身进行配置，并在每次调用该工具时运行。

- 输入工具安全防护措施在工具执行前运行，可跳过调用、用一条消息替换输出，或触发绊线。
- 输出工具安全防护措施在工具执行后运行，可替换输出或触发绊线。
- 工具安全防护措施仅适用于通过[`function_tool`][agents.function_tool]创建的工具调用；托管工具（`WebSearchTool`、`FileSearchTool`、`HostedMCPTool`、`CodeInterpreterTool`、`ImageGenerationTool`）和本地运行时工具（`ComputerTool`、`ShellTool`、`ApplyPatchTool`、`LocalShellTool`）不使用此防护流程。

详见下方代码片段。

## 绊线（Tripwires）

若输入或输出未通过安全防护措施，安全防护可通过绊线进行信号通知。一旦检测到某个安全防护触发了绊线，我们会立刻抛出`{Input,Output}GuardrailTripwireTriggered`异常并停止智能体执行。

## 实现安全防护措施

你需要提供一个接收输入并返回[`GuardrailFunctionOutput`][agents.guardrail.GuardrailFunctionOutput]的函数。在此示例中，我们将通过在底层运行一个智能体来完成。

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

1. 我们将在防护函数中使用这个智能体。
2. 这是接收智能体输入/上下文并返回结果的防护函数。
3. 我们可以在防护结果中包含额外信息。
4. 这是定义工作流的实际智能体。

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
2. 这是安全防护的输出类型。
3. 这是接收智能体输出并返回结果的防护函数。
4. 这是定义工作流的实际智能体。

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

任务转移允许一个智能体将任务委派给另一个智能体。这在不同智能体分别专精于不同领域的场景中特别有用。例如，一个客户支持应用可能包含多个智能体，分别专门处理订单状态、退款、常见问题解答等任务。

任务转移会以工具的形式呈现给 LLM。因此，如果要任务转移到名为 `Refund Agent` 的智能体，该工具会被命名为 `transfer_to_refund_agent`。

## 创建任务转移

所有智能体都有一个 [`handoffs`][agents.agent.Agent.handoffs] 参数，它既可以直接接收一个 `Agent`，也可以接收一个用于自定义任务转移的 `Handoff` 对象。

如果你传入的是普通的 `Agent` 实例，它们的 [`handoff_description`][agents.agent.Agent.handoff_description]（设置后）会被追加到默认的工具描述中。你可以用它来提示模型在何时应选择该任务转移，而无需编写完整的 `handoff()` 对象。

你可以使用 Agents SDK 提供的 [`handoff()`][agents.handoffs.handoff] 函数来创建任务转移。该函数允许你指定要转移到的智能体，并提供可选的覆写项与输入过滤器。

### 基本用法

下面展示如何创建一个简单的任务转移：

```python
from agents import Agent, handoff

billing_agent = Agent(name="Billing agent")
refund_agent = Agent(name="Refund agent")

# (1)!
triage_agent = Agent(name="Triage agent", handoffs=[billing_agent, handoff(refund_agent)])
```

1. 你可以直接使用智能体（如 `billing_agent`），也可以使用 `handoff()` 函数。

### 通过 `handoff()` 函数自定义任务转移

[`handoff()`][agents.handoffs.handoff] 函数允许你自定义相关内容。

-   `agent`：要将任务转移给的智能体。
-   `tool_name_override`：默认使用 `Handoff.default_tool_name()` 函数，解析为 `transfer_to_<agent_name>`。你可以覆写它。
-   `tool_description_override`：覆写 `Handoff.default_tool_description()` 的默认工具描述。
-   `on_handoff`：当任务转移被调用时执行的回调函数。这对在你确定将发生任务转移时立即触发数据拉取等操作很有用。该函数会接收智能体上下文，并且也可以选择接收由 LLM 生成的输入。输入数据由 `input_type` 参数控制。
-   `input_type`：任务转移期望的输入类型（可选）。
-   `input_filter`：用于过滤下一个智能体接收到的输入。更多内容见下文。
-   `is_enabled`：任务转移是否启用。可以是布尔值，也可以是返回布尔值的函数，从而支持在运行时动态启用或禁用任务转移。

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

在某些情况下，你希望 LLM 在调用任务转移时提供一些数据。例如，设想有一个转移到“升级处理智能体”的任务转移。你可能希望提供一个原因，以便记录日志。

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

当发生任务转移时，就像新的智能体接管了对话，并能看到此前的全部对话历史。如果你想改变这一点，可以设置一个 [`input_filter`][agents.handoffs.Handoff.input_filter]。输入过滤器是一个函数，它通过 [`HandoffInputData`][agents.handoffs.HandoffInputData] 接收现有输入，并必须返回一个新的 `HandoffInputData`。

嵌套任务转移以可选加入（opt-in）的 beta 形式提供；在我们稳定它们期间，默认是禁用的。当你启用 [`RunConfig.nest_handoff_history`][agents.run.RunConfig.nest_handoff_history] 时，runner 会将此前的对话记录折叠为一条 assistant 总结消息，并将其包裹在一个 `<CONVERSATION HISTORY>` 块中；当同一次运行期间发生多次任务转移时，该块会持续追加新的轮次。你可以通过 [`RunConfig.handoff_history_mapper`][agents.run.RunConfig.handoff_history_mapper] 提供自己的映射函数，以在不编写完整 `input_filter` 的情况下替换生成的消息。该 opt-in 仅在任务转移和运行都未提供显式 `input_filter` 时生效，因此现有已经自定义 payload 的代码（包括本仓库中的代码示例）无需修改即可保持当前行为。你可以通过在 [`handoff(...)`][agents.handoffs.handoff] 中传入 `nest_handoff_history=True` 或 `False` 来为单个任务转移覆写嵌套行为，这会设置 [`Handoff.nest_handoff_history`][agents.handoffs.Handoff.nest_handoff_history]。如果你只需要修改生成总结的包装文本，请在运行智能体之前调用 [`set_conversation_history_wrappers`][agents.handoffs.set_conversation_history_wrappers]（并可选调用 [`reset_conversation_history_wrappers`][agents.handoffs.reset_conversation_history_wrappers]）。

有一些常见模式（例如从历史记录中移除所有工具调用），我们已在 [`agents.extensions.handoff_filters`][] 中为你实现。

```python
from agents import Agent, handoff
from agents.extensions import handoff_filters

agent = Agent(name="FAQ agent")

handoff_obj = handoff(
    agent=agent,
    input_filter=handoff_filters.remove_all_tools, # (1)!
)
```

1. 当调用 `FAQ agent` 时，这会自动从历史记录中移除所有工具。

## 推荐提示词

为确保 LLM 正确理解任务转移，我们建议在你的智能体中包含有关任务转移的信息。我们在 [`agents.extensions.handoff_prompt.RECOMMENDED_PROMPT_PREFIX`][] 中提供了建议的前缀；或者你可以调用 [`agents.extensions.handoff_prompt.prompt_with_handoff_instructions`][] 来自动将推荐数据添加到你的提示词中。

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
File: docs/zh/index.md
================
---
search:
  exclude: true
---
# OpenAI Agents SDK

[OpenAI Agents SDK](https://github.com/openai/openai-agents-python) 使你能够以轻量、易用、抽象极少的方式构建智能体 AI 应用。这是我们此前用于智能体实验的项目 [Swarm](https://github.com/openai/swarm/tree/main) 的生产级升级版本。Agents SDK 只有一小组 basic components：

-   **智能体**：配备 instructions 和 tools 的 LLM
-   **Agents as tools / 任务转移**：允许智能体将特定任务委派给其他智能体
-   **安全防护措施**：用于对智能体输入与输出进行验证

与 Python 结合时，这些 basic components 足以表达工具与智能体之间的复杂关系，并让你无需陡峭的学习曲线就能构建真实世界的应用。此外，SDK 内置 **追踪**，可用于可视化与调试你的智能体流程，并对其进行评估，甚至为你的应用微调模型。

## 使用 Agents SDK 的原因

SDK 有两个核心设计原则：

1. 功能足够多，值得使用；但 basic components 足够少，便于快速上手。
2. 开箱即用，同时也允许你精确自定义行为。

以下是 SDK 的主要特性：

-   **智能体循环**：内置智能体循环，负责处理工具调用、将结果回传给 LLM，并持续运行直到任务完成。
-   **Python 优先**：使用内置语言特性来编排与串联智能体，而无需学习新的抽象。
-   **Agents as tools / 任务转移**：用于跨多个智能体协调与委派工作的强大机制。
-   **安全防护措施**：在智能体执行的同时并行运行输入验证与安全检查，检查不通过时快速失败。
-   **工具调用**：将任意 Python 函数转换为工具，自动生成 schema，并提供由 Pydantic 驱动的验证。
-   **MCP server 工具调用**：内置 MCP server 工具集成，使用方式与工具调用相同。
-   **会话**：用于在智能体循环中维护工作上下文的持久化记忆层。
-   **人在回路（Human in the loop）**：在智能体运行过程中引入人类参与的内置机制。
-   **追踪**：用于可视化、调试与监控工作流的内置追踪，并支持 OpenAI 的评估、微调与蒸馏工具套件。
-   **Realtime 智能体**：构建强大的语音智能体，具备自动打断检测、上下文管理、安全防护措施等能力。

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

(_如果要运行此示例，请确保已设置 `OPENAI_API_KEY` 环境变量_)

```bash
export OPENAI_API_KEY=sk-...
```

================
File: docs/zh/mcp.md
================
---
search:
  exclude: true
---
# Model context protocol (MCP)

[Model context protocol](https://modelcontextprotocol.io/introduction)（MCP）标准化了应用如何向语言模型暴露工具和上下文。摘自官方文档：

> MCP 是一个开放协议，用于标准化应用向 LLM 提供上下文的方式。可以把 MCP 想象成 AI 应用的 USB-C 端口。正如 USB-C 提供了一种标准化方式，将你的设备连接到各种外设和配件，MCP 也提供了一种标准化方式，将 AI 模型连接到不同的数据源和工具。

Agents Python SDK 支持多种 MCP 传输方式。这让你能够复用现有的 MCP 服务，或自行构建服务，以向智能体暴露由文件系统、HTTP 或连接器支持的工具。

## MCP 集成选择

在将 MCP 服务接入智能体之前，先决定工具调用应在哪里执行，以及你能触达哪些传输方式。下表总结了 Python SDK 支持的选项。

| 你需要的能力                                                                         | 推荐选项                                              |
| ------------------------------------------------------------------------------------ | ----------------------------------------------------- |
| 让 OpenAI 的 Responses API 代表模型调用一个可公网访问的 MCP 服务                       | 通过 [`HostedMCPTool`][agents.tool.HostedMCPTool] 使用 **Hosted MCP server tools** |
| 连接你在本地或远程运行的 Streamable HTTP 服务                                         | 通过 [`MCPServerStreamableHttp`][agents.mcp.server.MCPServerStreamableHttp] 使用 **Streamable HTTP MCP servers** |
| 与实现了带 Server-Sent Events 的 HTTP 的服务通信                                      | 通过 [`MCPServerSse`][agents.mcp.server.MCPServerSse] 使用 **HTTP with SSE MCP servers** |
| 启动本地进程并通过 stdin/stdout 通信                                                  | 通过 [`MCPServerStdio`][agents.mcp.server.MCPServerStdio] 使用 **stdio MCP servers** |

下面将分别介绍每种选项、如何配置，以及何时应优先选择某种传输方式。

## 1. Hosted MCP server tools

Hosted 工具将整个工具往返过程都交由 OpenAI 基础设施处理。你的代码不再负责列出和调用工具，而是由 [`HostedMCPTool`][agents.tool.HostedMCPTool] 将服务标签（以及可选的连接器元数据）转发给 Responses API。模型会列出远程服务的工具并调用它们，无需额外回调到你的 Python 进程。Hosted 工具目前适用于支持 Responses API 的 hosted MCP 集成的 OpenAI 模型。

### 基本 hosted MCP 工具

通过将 [`HostedMCPTool`][agents.tool.HostedMCPTool] 添加到智能体的 `tools` 列表来创建 hosted 工具。`tool_config` dict 对应你会发送到 REST API 的 JSON：

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

Hosted 服务会自动暴露其工具；你无需将其添加到 `mcp_servers`。

### 流式传输 hosted MCP 结果

Hosted 工具以与工具调用完全相同的方式支持流式输出。将 `stream=True` 传给 `Runner.run_streamed`，即可在模型仍在工作时消费增量 MCP 输出：

```python
result = Runner.run_streamed(agent, "Summarise this repository's top languages")
async for event in result.stream_events():
    if event.type == "run_item_stream_event":
        print(f"Received: {event.item}")
print(result.final_output)
```

### 可选审批流程

如果服务可能执行敏感操作，你可以在每次工具执行前要求人工或程序化审批。在 `tool_config` 中配置 `require_approval`：可以是单一策略（`"always"`、`"never"`），也可以是将工具名称映射到策略的 dict。若要在 Python 内做出决策，请提供 `on_approval_request` 回调。

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

该回调可以是同步或异步，并会在模型需要审批数据以继续运行时被调用。

### 由连接器支持的 hosted 服务

Hosted MCP 也支持 OpenAI connectors。无需指定 `server_url`，而是提供 `connector_id` 和访问令牌。Responses API 负责处理鉴权，hosted 服务会暴露连接器的工具。

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

完整可运行的 hosted 工具示例（包括流式传输、审批和连接器）位于
[`examples/hosted_mcp`](https://github.com/openai/openai-agents-python/tree/main/examples/hosted_mcp)。

## 2. Streamable HTTP MCP servers

当你希望自行管理网络连接时，请使用 [`MCPServerStreamableHttp`][agents.mcp.server.MCPServerStreamableHttp]。在你可控传输方式，或希望在自有基础设施中运行服务并保持低延迟时，Streamable HTTP 服务是理想选择。

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

构造函数还接受其他选项：

- `client_session_timeout_seconds` 控制 HTTP 读取超时。
- `use_structured_content` 切换是否优先使用 `tool_result.structured_content` 而非文本输出。
- `max_retry_attempts` 和 `retry_backoff_seconds_base` 为 `list_tools()` 和 `call_tool()` 增加自动重试。
- `tool_filter` 允许你只暴露工具子集（见 [工具过滤](#tool-filtering)）。

## 3. HTTP with SSE MCP servers

!!! warning

    MCP 项目已弃用 Server-Sent Events 传输方式。新集成应优先使用 Streamable HTTP 或 stdio，SSE 仅用于遗留服务。

如果 MCP 服务实现了带 SSE 的 HTTP 传输方式，请实例化 [`MCPServerSse`][agents.mcp.server.MCPServerSse]。除传输方式外，其 API 与 Streamable HTTP 服务完全一致。

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

对于作为本地子进程运行的 MCP 服务，请使用 [`MCPServerStdio`][agents.mcp.server.MCPServerStdio]。SDK 会启动该进程，保持管道开启，并在上下文管理器退出时自动关闭。该选项适用于快速概念验证，或服务仅提供命令行入口的场景。

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

当你有多个 MCP 服务时，使用 `MCPServerManager` 预先连接它们，并将已连接的子集暴露给你的智能体。

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

- 当 `drop_failed_servers=True`（默认）时，`active_servers` 仅包含连接成功的服务。
- 失败会记录在 `failed_servers` 和 `errors` 中。
- 设置 `strict=True` 可在首次连接失败时抛出异常。
- 调用 `reconnect(failed_only=True)` 以重试失败服务，或 `reconnect(failed_only=False)` 以重启所有服务。
- 使用 `connect_timeout_seconds`、`cleanup_timeout_seconds` 和 `connect_in_parallel` 来调整生命周期行为。

## 工具过滤

每个 MCP 服务都支持工具过滤器，以便你只暴露智能体需要的函数。过滤可以在构造时进行，也可以在每次运行时动态进行。

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

当同时提供 `allowed_tool_names` 和 `blocked_tool_names` 时，SDK 会先应用允许列表，然后从剩余集合中移除被阻止的工具。

### 动态工具过滤

对于更复杂的逻辑，传入一个可调用对象，它接收 [`ToolFilterContext`][agents.mcp.ToolFilterContext]。该可调用对象可以是同步或异步，并在工具应被暴露时返回 `True`。

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

过滤上下文会暴露当前 `run_context`、请求工具的 `agent` 以及 `server_name`。

## Prompts

MCP 服务也可以提供 prompts，用于动态生成智能体指令。支持 prompts 的服务会暴露两个方法：

- `list_prompts()` 枚举可用的 prompt 模板。
- `get_prompt(name, arguments)` 获取一个具体 prompt（可选带参数）。

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

每次智能体运行都会对每个 MCP 服务调用 `list_tools()`。远程服务可能引入明显延迟，因此所有 MCP 服务类都提供 `cache_tools_list` 选项。仅当你确信工具定义不会频繁变化时，才将其设为 `True`。若稍后需要强制刷新列表，请在服务实例上调用 `invalidate_tools_cache()`。

## 追踪

[Tracing](./tracing.md) 会自动捕获 MCP 活动，包括：

1. 调用 MCP 服务以列出工具。
2. 工具调用中的 MCP 相关信息。

![MCP 追踪截图](../assets/images/mcp-tracing.jpg)

## 延伸阅读

- [Model Context Protocol](https://modelcontextprotocol.io/) – 规范与设计指南。
- [examples/mcp](https://github.com/openai/openai-agents-python/tree/main/examples/mcp) – 可运行的 stdio、SSE 和 Streamable HTTP 示例。
- [examples/hosted_mcp](https://github.com/openai/openai-agents-python/tree/main/examples/hosted_mcp) – 完整的 hosted MCP 演示，包括审批与连接器。

================
File: docs/zh/multi_agent.md
================
---
search:
  exclude: true
---
# 协调多个智能体

协调是指应用中智能体的流程：哪些智能体要运行、以何种顺序运行，以及它们如何决定接下来要做什么。协调智能体主要有两种方式：

1. 允许 LLM 做决策：利用 LLM 的智能进行规划、推理，并据此决定采取的步骤。
2. 通过代码进行编排：用你的代码决定智能体的流程。

你可以混合使用这些模式。每种方式都有各自的权衡，详见下文。

## 通过 LLM 协调

一个智能体是配备了指令、工具和 handoffs 的 LLM。这意味着在给定开放式任务的情况下，LLM 可以自主规划如何处理任务，使用工具执行操作和获取数据，并通过 handoffs 将任务委派给子智能体。比如，一个研究智能体可以配备如下工具：

- 网络检索以在网上查找信息
- 文件检索与获取以搜索专有数据与连接
- 计算机操作以在计算机上执行动作
- 代码执行以进行数据分析
- handoffs 到擅长规划、报告撰写等的专业智能体

当任务是开放式且你希望依赖 LLM 的智能时，这种模式非常适合。这里最重要的策略是：

1. 打造高质量提示词。明确可用的工具、如何使用它们，以及必须遵循的参数范围。
2. 监控并迭代你的应用。观察问题出现在哪里，并迭代优化提示词。
3. 允许智能体自我反思并改进。例如，在循环中运行它，让它自我批评；或者提供错误信息并让它改进。
4. 使用在单一任务上表现卓越的专业智能体，而不是期望一个通用智能体在所有方面都很出色。
5. 投入到[评测](https://platform.openai.com/docs/guides/evals)。这使你能够训练智能体改进并在任务上表现更好。

## 通过代码协调

虽然通过 LLM 协调很强大，但通过代码协调在速度、成本和性能方面更具确定性和可预测性。常见模式包括：

- 使用[structured outputs](https://platform.openai.com/docs/guides/structured-outputs)生成你可以用代码检查的格式良好的数据。例如，你可以要求智能体将任务分类到几个目录中，然后基于该目录选择下一个智能体。
- 通过将一个智能体的输出转换为下一个智能体的输入来串联多个智能体。你可以将撰写博客文章这样的任务分解为一系列步骤——进行研究、写大纲、写正文、评审，然后改进。
- 将执行任务的智能体与一个评估并提供反馈的智能体一起在 `while` 循环中运行，直到评估者认为输出通过了特定标准。
- 并行运行多个智能体，例如通过 Python 基本组件如 `asyncio.gather`。当你有多个彼此不依赖的任务时，这有助于提升速度。

我们在[`examples/agent_patterns`](https://github.com/openai/openai-agents-python/tree/main/examples/agent_patterns)中提供了若干 code examples。

================
File: docs/zh/quickstart.md
================
---
search:
  exclude: true
---
# 快速开始

## 创建项目与虚拟环境

只需执行一次。

```bash
mkdir my_project
cd my_project
python -m venv .venv
```

### 激活虚拟环境

每次启动新的终端会话时都需要执行。

```bash
source .venv/bin/activate
```

### 安装 Agents SDK

```bash
pip install openai-agents # or `uv add openai-agents`, etc
```

### 设置 OpenAI API key

如果你还没有，请按照[这些说明](https://platform.openai.com/docs/quickstart#create-and-export-an-api-key)创建一个 OpenAI API key。

```bash
export OPENAI_API_KEY=sk-...
```

## 创建首个智能体

使用 instructions、名称和可选配置（如 `model_config`）定义智能体。

```python
from agents import Agent

agent = Agent(
    name="Math Tutor",
    instructions="You provide help with math problems. Explain your reasoning at each step and include examples",
)
```

## 添加更多智能体

可以用相同方式定义其他智能体。`handoff_descriptions` 为确定任务转移路由提供附加上下文。

```python
from agents import Agent

history_tutor_agent = Agent(
    name="History Tutor",
    handoff_description="Specialist agent for historical questions",
    instructions="You provide assistance with historical queries. Explain important events and context clearly.",
)

math_tutor_agent = Agent(
    name="Math Tutor",
    handoff_description="Specialist agent for math questions",
    instructions="You provide help with math problems. Explain your reasoning at each step and include examples",
)
```

## 定义任务转移

在每个智能体上，你可以定义一个外发任务转移选项的清单，智能体可从中选择以决定如何推进其任务。

```python
triage_agent = Agent(
    name="Triage Agent",
    instructions="You determine which agent to use based on the user's homework question",
    handoffs=[history_tutor_agent, math_tutor_agent]
)
```

## 运行智能体编排

检查工作流是否运行，以及分诊智能体是否在两个专家智能体之间正确路由。

```python
from agents import Runner

async def main():
    result = await Runner.run(triage_agent, "who was the first president of the united states?")
    print(result.final_output)
```

## 添加安全防护措施

你可以定义自定义安全防护措施，作用于输入或输出。

```python
from agents import GuardrailFunctionOutput, Agent, Runner
from pydantic import BaseModel


class HomeworkOutput(BaseModel):
    is_homework: bool
    reasoning: str

guardrail_agent = Agent(
    name="Guardrail check",
    instructions="Check if the user is asking about homework.",
    output_type=HomeworkOutput,
)

async def homework_guardrail(ctx, agent, input_data):
    result = await Runner.run(guardrail_agent, input_data, context=ctx.context)
    final_output = result.final_output_as(HomeworkOutput)
    return GuardrailFunctionOutput(
        output_info=final_output,
        tripwire_triggered=not final_output.is_homework,
    )
```

## 整合运行

将以上组合起来，使用任务转移和输入安全防护措施运行整个工作流。

```python
from agents import Agent, InputGuardrail, GuardrailFunctionOutput, Runner
from agents.exceptions import InputGuardrailTripwireTriggered
from pydantic import BaseModel
import asyncio

class HomeworkOutput(BaseModel):
    is_homework: bool
    reasoning: str

guardrail_agent = Agent(
    name="Guardrail check",
    instructions="Check if the user is asking about homework.",
    output_type=HomeworkOutput,
)

math_tutor_agent = Agent(
    name="Math Tutor",
    handoff_description="Specialist agent for math questions",
    instructions="You provide help with math problems. Explain your reasoning at each step and include examples",
)

history_tutor_agent = Agent(
    name="History Tutor",
    handoff_description="Specialist agent for historical questions",
    instructions="You provide assistance with historical queries. Explain important events and context clearly.",
)


async def homework_guardrail(ctx, agent, input_data):
    result = await Runner.run(guardrail_agent, input_data, context=ctx.context)
    final_output = result.final_output_as(HomeworkOutput)
    return GuardrailFunctionOutput(
        output_info=final_output,
        tripwire_triggered=not final_output.is_homework,
    )

triage_agent = Agent(
    name="Triage Agent",
    instructions="You determine which agent to use based on the user's homework question",
    handoffs=[history_tutor_agent, math_tutor_agent],
    input_guardrails=[
        InputGuardrail(guardrail_function=homework_guardrail),
    ],
)

async def main():
    # Example 1: History question
    try:
        result = await Runner.run(triage_agent, "who was the first president of the united states?")
        print(result.final_output)
    except InputGuardrailTripwireTriggered as e:
        print("Guardrail blocked this input:", e)

    # Example 2: General/philosophical question
    try:
        result = await Runner.run(triage_agent, "What is the meaning of life?")
        print(result.final_output)
    except InputGuardrailTripwireTriggered as e:
        print("Guardrail blocked this input:", e)

if __name__ == "__main__":
    asyncio.run(main())
```

## 查看追踪

要回顾智能体运行过程中的事件，请前往 [OpenAI Dashboard 中的 Trace viewer](https://platform.openai.com/traces) 查看运行追踪。

## 后续步骤

了解如何构建更复杂的智能体流程：

- 学习如何配置[智能体](agents.md)。
- 了解[运行智能体](running_agents.md)。
- 了解[工具](tools.md)、[安全防护措施](guardrails.md)和[模型](models/index.md)。

================
File: docs/zh/release.md
================
---
search:
  exclude: true
---
# 发布流程/更新日志

本项目采用经轻微修改的语义化版本控制，版本号形式为 `0.Y.Z`。前导的 `0` 表示该 SDK 仍在快速演进中。各部分的递增规则如下：

## 次版本（`Y`）

对于未标记为 beta 的任何公共接口发生**不兼容变更**时，我们会提升次版本号 `Y`。例如，从 `0.0.x` 升级到 `0.1.x` 可能包含不兼容变更。

如果你不希望引入不兼容变更，建议在你的项目中固定到 `0.0.x` 版本。

## 修订版本（`Z`）

对于非破坏性变更，我们会递增 `Z`：

- Bug 修复
- 新功能
- 私有接口的变更
- 测试版功能的更新

## 不兼容变更日志

### 0.6.0

在此版本中，默认的任务转移历史现在被封装为单条 assistant 消息，而不再暴露原始的 user/assistant 轮次，从而为下游智能体提供简洁且可预测的回顾
- 现有的单消息任务转移记录默认会在 `<CONVERSATION HISTORY>` 块前以“For context, here is the conversation so far between the user and the previous agent:”开头，使下游智能体获得带有清晰标签的回顾

### 0.5.0

该版本没有引入可见的不兼容变更，但包含新特性和若干重要的底层更新：

- 为 `RealtimeRunner` 新增了处理 [SIP 协议连接](https://platform.openai.com/docs/guides/realtime-sip) 的支持
- 大幅修订了 `Runner#run_sync` 的内部逻辑，以兼容 Python 3.14

### 0.4.0

在此版本中，[openai](https://pypi.org/project/openai/) 包的 v1.x 版本不再受支持。请将 openai 升级至 v2.x 并与本 SDK 一同使用。

### 0.3.0

在此版本中，Realtime API 支持迁移至 gpt-realtime 模型及其 API 接口（GA 版本）。

### 0.2.0

在此版本中，若干此前接收 `Agent` 作为参数的位置，现在改为接收 `AgentBase` 作为参数。例如，MCP 服务中的 `list_tools()` 调用。这只是类型层面的变更，你仍将收到 `Agent` 对象。要更新的话，只需将类型错误中出现的 `Agent` 替换为 `AgentBase` 即可。

### 0.1.0

在此版本中，[`MCPServer.list_tools()`][agents.mcp.server.MCPServer] 新增了两个参数：`run_context` 和 `agent`。你需要将这些参数添加到任何继承 `MCPServer` 的类中。

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

当你调用 `Runner.run` 方法时，你会得到：

-   如果调用 `run` 或 `run_sync`，则得到 [`RunResult`][agents.result.RunResult]
-   如果调用 `run_streamed`，则得到 [`RunResultStreaming`][agents.result.RunResultStreaming]

这两者都继承自 [`RunResultBase`][agents.result.RunResultBase]，大多数有用的信息都在这里。

## 最终输出

[`final_output`][agents.result.RunResultBase.final_output] 属性包含最后一个运行的智能体的最终输出。它可能是：

-   `str`，如果最后一个智能体未定义 `output_type`
-   类型为 `last_agent.output_type` 的对象，如果该智能体定义了输出类型。

!!! note

    `final_output` 的类型是 `Any`。由于存在任务转移，我们无法进行静态类型标注。如果发生任务转移，意味着任意智能体都可能是最后一个，因此我们无法静态地知道可能的输出类型集合。

## 下一轮的输入

你可以使用 [`result.to_input_list()`][agents.result.RunResultBase.to_input_list] 将结果转换为一个输入列表，该列表把你提供的原始输入与智能体运行期间生成的条目连接起来。这样便于将一次智能体运行的输出传递到另一次运行中，或者在循环中运行并在每次追加新的用户输入。

## 最后一个智能体

[`last_agent`][agents.result.RunResultBase.last_agent] 属性包含最后一个运行的智能体。根据你的应用场景，这通常对用户下次输入时很有用。比如，如果你有一个前线分诊智能体将任务转移给特定语言的智能体，你可以存储这个最后的智能体，并在用户下次发送消息给智能体时复用它。

## 新增条目

[`new_items`][agents.result.RunResultBase.new_items] 属性包含本次运行期间生成的新条目。条目是 [`RunItem`][agents.items.RunItem]。运行条目会封装由 LLM 生成的原始条目。

-   [`MessageOutputItem`][agents.items.MessageOutputItem] 表示来自 LLM 的消息。原始条目是生成的消息。
-   [`HandoffCallItem`][agents.items.HandoffCallItem] 表示 LLM 调用了任务转移工具。原始条目是来自 LLM 的工具调用条目。
-   [`HandoffOutputItem`][agents.items.HandoffOutputItem] 表示发生了任务转移。原始条目是对任务转移工具调用的工具响应。你还可以从该条目中访问源/目标智能体。
-   [`ToolCallItem`][agents.items.ToolCallItem] 表示 LLM 调用了某个工具。
-   [`ToolCallOutputItem`][agents.items.ToolCallOutputItem] 表示某个工具被调用。原始条目是工具响应。你还可以从该条目访问工具输出。
-   [`ReasoningItem`][agents.items.ReasoningItem] 表示来自 LLM 的推理条目。原始条目是生成的推理内容。

## 其他信息

### 安全防护措施结果

[`input_guardrail_results`][agents.result.RunResultBase.input_guardrail_results] 和 [`output_guardrail_results`][agents.result.RunResultBase.output_guardrail_results] 属性包含安全防护措施的结果（如果有）。安全防护措施的结果有时包含你可能想要记录或存储的有用信息，因此我们将其提供给你。

工具的安全防护措施结果单独提供为 [`tool_input_guardrail_results`][agents.result.RunResultBase.tool_input_guardrail_results] 和 [`tool_output_guardrail_results`][agents.result.RunResultBase.tool_output_guardrail_results]。这些安全防护措施可以附加到工具上，并在智能体工作流期间的工具调用中执行。

### 原始响应

[`raw_responses`][agents.result.RunResultBase.raw_responses] 属性包含由 LLM 生成的 [`ModelResponse`][agents.items.ModelResponse]。

### 原始输入

[`input`][agents.result.RunResultBase.input] 属性包含你传递给 `run` 方法的原始输入。在大多数情况下你不需要它，但如果需要，它也可用。

================
File: docs/zh/running_agents.md
================
---
search:
  exclude: true
---
# 运行智能体

你可以通过 [`Runner`][agents.run.Runner] 类来运行智能体。你有 3 种选择：

1. [`Runner.run()`][agents.run.Runner.run]：异步运行并返回 [`RunResult`][agents.result.RunResult]。
2. [`Runner.run_sync()`][agents.run.Runner.run_sync]：同步方法，底层只是运行 `.run()`。
3. [`Runner.run_streamed()`][agents.run.Runner.run_streamed]：异步运行并返回 [`RunResultStreaming`][agents.result.RunResultStreaming]。它以流式模式调用 LLM，并在接收到事件时将这些事件流式传输给你。

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

更多信息请参阅[结果指南](results.md)。

## 智能体循环

当你在 `Runner` 中使用 run 方法时，需要传入一个起始智能体和输入。输入可以是字符串（会被视为一条用户消息），也可以是输入项列表（即 OpenAI Responses API 中的 items）。

Runner 随后会运行一个循环：

1. 我们使用当前输入为当前智能体调用 LLM。
2. LLM 生成其输出。
    1. 如果 LLM 返回 `final_output`，循环结束并返回结果。
    2. 如果 LLM 进行了 handoff，我们会更新当前智能体和输入，并重新运行循环。
    3. 如果 LLM 产生了工具调用，我们会运行这些工具调用，追加结果，然后重新运行循环。
3. 如果超过传入的 `max_turns`，我们会抛出 [`MaxTurnsExceeded`][agents.exceptions.MaxTurnsExceeded] 异常。

!!! note

    判断 LLM 输出是否被视为“最终输出”的规则是：它生成了所需类型的文本输出，并且没有任何工具调用。

## 流式传输

流式传输允许你在 LLM 运行时额外接收流式事件。流结束后，[`RunResultStreaming`][agents.result.RunResultStreaming] 将包含本次运行的完整信息，包括产生的所有新输出。你可以调用 `.stream_events()` 来获取流式事件。更多信息请参阅[流式传输指南](streaming.md)。

## 运行配置

`run_config` 参数允许你为智能体运行配置一些全局设置：

-   [`model`][agents.run.RunConfig.model]：允许设置全局要使用的 LLM 模型，不受每个 Agent 的 `model` 影响。
-   [`model_provider`][agents.run.RunConfig.model_provider]：用于查找模型名称的模型提供方，默认为 OpenAI。
-   [`model_settings`][agents.run.RunConfig.model_settings]：覆盖智能体级别的设置。例如，你可以设置全局的 `temperature` 或 `top_p`。
-   [`input_guardrails`][agents.run.RunConfig.input_guardrails]、[`output_guardrails`][agents.run.RunConfig.output_guardrails]：要在所有运行中包含的一组输入或输出安全防护措施。
-   [`handoff_input_filter`][agents.run.RunConfig.handoff_input_filter]：用于所有 handoffs 的全局输入过滤器（如果 handoff 本身尚未设置）。输入过滤器允许你编辑发送给新智能体的输入。更多详情请参阅 [`Handoff.input_filter`][agents.handoffs.Handoff.input_filter] 文档。
-   [`nest_handoff_history`][agents.run.RunConfig.nest_handoff_history]：可选开启的 beta 功能，会在调用下一个智能体之前，将先前的对话记录折叠为一条 assistant 消息。在我们稳定嵌套任务转移期间，此功能默认关闭；设置为 `True` 以启用，或保持 `False` 以透传原始对话记录。当你未传入 `RunConfig` 时，所有 [`Runner` 方法](agents.run.Runner)都会自动创建一个 `RunConfig`，因此 quickstarts 和示例保持默认关闭；任何显式的 [`Handoff.input_filter`][agents.handoffs.Handoff.input_filter] 回调仍会覆盖它。单个 handoff 可以通过 [`Handoff.nest_handoff_history`][agents.handoffs.Handoff.nest_handoff_history] 覆盖此设置。
-   [`handoff_history_mapper`][agents.run.RunConfig.handoff_history_mapper]：可选的可调用对象。在你选择启用 `nest_handoff_history` 时，它会在每次收到归一化的对话记录（history + handoff items）时被调用。它必须返回要转发给下一个智能体的、完全一致的输入项列表，从而让你无需编写完整的 handoff 过滤器即可替换内置摘要。
-   [`tracing_disabled`][agents.run.RunConfig.tracing_disabled]：允许你为整个运行禁用[追踪](tracing.md)。
-   [`tracing`][agents.run.RunConfig.tracing]：传入 [`TracingConfig`][agents.tracing.TracingConfig] 以覆盖本次运行的导出器、进程或追踪元数据。
-   [`trace_include_sensitive_data`][agents.run.RunConfig.trace_include_sensitive_data]：配置追踪中是否包含潜在敏感数据，例如 LLM 与工具调用的输入/输出。
-   [`workflow_name`][agents.run.RunConfig.workflow_name]、[`trace_id`][agents.run.RunConfig.trace_id]、[`group_id`][agents.run.RunConfig.group_id]：设置本次运行的追踪工作流名称、trace ID 和 trace group ID。我们建议至少设置 `workflow_name`。group ID 是可选字段，可让你跨多次运行关联 traces。
-   [`trace_metadata`][agents.run.RunConfig.trace_metadata]：要包含在所有 traces 上的元数据。
-   [`session_input_callback`][agents.run.RunConfig.session_input_callback]：在使用 Sessions 时，自定义在每轮之前如何将新的用户输入与会话历史合并。
-   [`call_model_input_filter`][agents.run.RunConfig.call_model_input_filter]：用于在模型调用前立即编辑已完全准备好的模型输入（instructions 和输入项）的钩子，例如用于裁剪历史或注入系统提示词。

嵌套任务转移（nested handoffs）以可选开启的 beta 形式提供。通过传入 `RunConfig(nest_handoff_history=True)` 来启用折叠对话记录的行为，或对特定 handoff 设置 `handoff(..., nest_handoff_history=True)` 以为该 handoff 启用。如果你更倾向于保留原始对话记录（默认行为），请不要设置该标志，或提供一个 `handoff_input_filter`（或 `handoff_history_mapper`）来按你的需求逐字转发对话。若要在不编写自定义 mapper 的情况下更改生成摘要中使用的包装文本，请调用 [`set_conversation_history_wrappers`][agents.handoffs.set_conversation_history_wrappers]（并通过 [`reset_conversation_history_wrappers`][agents.handoffs.reset_conversation_history_wrappers] 恢复默认值）。

## 对话/聊天线程

调用任意 run 方法都可能导致一个或多个智能体运行（因此会有一次或多次 LLM 调用），但它表示聊天对话中的一次逻辑轮次。例如：

1. 用户轮次：用户输入文本
2. Runner 运行：第一个智能体调用 LLM、运行工具、handoff 到第二个智能体，第二个智能体运行更多工具，然后生成输出。

在智能体运行结束时，你可以选择向用户展示什么。例如，你可以向用户展示智能体生成的每一条新 item，或仅展示最终输出。无论哪种方式，用户随后可能会提出后续问题，此时你可以再次调用 run 方法。

### 手动对话管理

你可以使用 [`RunResultBase.to_input_list()`][agents.result.RunResultBase.to_input_list] 方法手动管理对话历史，以获取下一轮所需的输入：

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

### 使用 Sessions 的自动对话管理

为了更简单，你可以使用 [Sessions](sessions/index.md) 自动处理对话历史，而无需手动调用 `.to_input_list()`：

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

-   在每次运行前检索对话历史
-   在每次运行后存储新消息
-   为不同的 session ID 维护彼此独立的对话

更多详情请参阅 [Sessions 文档](sessions/index.md)。

### 服务端托管的对话

你也可以让 OpenAI conversation state 功能在服务端管理对话状态，而不是在本地使用 `to_input_list()` 或 `Sessions` 来处理。这样你无需手动重发所有历史消息，就能保留对话历史。更多详情请参阅 [OpenAI Conversation state guide](https://platform.openai.com/docs/guides/conversation-state?api-mode=responses)。

OpenAI 提供两种方式来跨轮次跟踪状态：

#### 1. 使用 `conversation_id`

你先使用 OpenAI Conversations API 创建一个对话，然后在后续每次调用中复用它的 ID：

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

#### 2. 使用 `previous_response_id`

另一种选择是**响应串联（response chaining）**，其中每一轮都显式链接到上一轮的 response ID。

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

## Call model input filter

使用 `call_model_input_filter` 在模型调用前编辑模型输入。该钩子接收当前智能体、上下文，以及合并后的输入项（包含存在时的会话历史），并返回新的 `ModelInputData`。

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

你可以通过 `run_config` 为每次运行设置该钩子，或将其设为你的 `Runner` 的默认值，用于脱敏敏感数据、裁剪过长历史，或注入额外的系统指导。

## 长时间运行的智能体与 human-in-the-loop

### Temporal

你可以使用 Agents SDK 的 [Temporal](https://temporal.io/) 集成来运行持久的、长时间运行的工作流，包括 human-in-the-loop 任务。观看 Temporal 与 Agents SDK 协作完成长时间任务的演示，请参见[此视频](https://www.youtube.com/watch?v=fFBZqzT4DD8)，并[在此查看文档](https://github.com/temporalio/sdk-python/tree/main/temporalio/contrib/openai_agents)。 

### Restate

你可以使用 Agents SDK 的 [Restate](https://restate.dev/) 集成来实现轻量级、持久的智能体，包括人工审批、handoffs 与会话管理。该集成需要 Restate 的单二进制运行时作为依赖，并支持将智能体作为进程/容器或无服务器函数运行。
更多详情请阅读[概览](https://www.restate.dev/blog/durable-orchestration-for-ai-agents-with-restate-and-openai-sdk)或查看[文档](https://docs.restate.dev/ai)。

## 异常

SDK 会在某些情况下抛出异常。完整列表见 [`agents.exceptions`][]。概览如下：

-   [`AgentsException`][agents.exceptions.AgentsException]：SDK 内部抛出的所有异常的基类。它作为通用类型，所有其他具体异常都从它派生。
-   [`MaxTurnsExceeded`][agents.exceptions.MaxTurnsExceeded]：当智能体运行超过传入 `Runner.run`、`Runner.run_sync` 或 `Runner.run_streamed` 方法的 `max_turns` 限制时抛出。它表示智能体无法在指定的交互轮次数内完成任务。
-   [`ModelBehaviorError`][agents.exceptions.ModelBehaviorError]：当底层模型（LLM）产生意外或无效输出时发生。可能包括：
    -   JSON 格式错误：当模型为工具调用或其直接输出提供了格式错误的 JSON 结构，尤其是在定义了特定 `output_type` 的情况下。
    -   与工具相关的意外失败：当模型未按预期方式使用工具时
-   [`UserError`][agents.exceptions.UserError]：当你（使用 SDK 编写代码的人）在使用 SDK 时发生错误而抛出。通常源于错误的代码实现、无效配置或对 SDK API 的误用。
-   [`InputGuardrailTripwireTriggered`][agents.exceptions.InputGuardrailTripwireTriggered]、[`OutputGuardrailTripwireTriggered`][agents.exceptions.OutputGuardrailTripwireTriggered]：当输入安全防护措施或输出安全防护措施的条件分别被满足时抛出。输入安全防护措施会在处理前检查传入消息，而输出安全防护措施会在交付前检查智能体的最终响应。

================
File: docs/zh/streaming.md
================
---
search:
  exclude: true
---
# 流式传输

流式传输允许你在智能体运行过程中订阅其更新。这对于向终端用户展示进度更新和部分响应非常有用。

要进行流式传输，你可以调用 [`Runner.run_streamed()`][agents.run.Runner.run_streamed]，它会返回一个 [`RunResultStreaming`][agents.result.RunResultStreaming]。调用 `result.stream_events()` 会返回一个由 [`StreamEvent`][agents.stream_events.StreamEvent] 对象组成的异步流，详见下文。

## 原始响应事件

[`RawResponsesStreamEvent`][agents.stream_events.RawResponsesStreamEvent] 是直接从 LLM 传递过来的原始事件。它们采用 OpenAI Responses API 格式，这意味着每个事件都有一个类型（如 `response.created`、`response.output_text.delta` 等）以及数据。如果你想在生成后立即将响应消息流式发送给用户，这些事件会很有用。

例如，下面的示例会按 token 输出 LLM 生成的文本。

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

## 运行项事件与智能体事件

[`RunItemStreamEvent`][agents.stream_events.RunItemStreamEvent] 是更高层级的事件。它会在某个项完全生成时通知你。这样你可以在“消息已生成”“工具已运行”等层级上推送进度更新，而不是在每个 token 上。同样，[`AgentUpdatedStreamEvent`][agents.stream_events.AgentUpdatedStreamEvent] 会在当前智能体发生变化时（例如由于任务转移）向你提供更新。

例如，下面的示例会忽略原始事件，仅向用户流式传输更新。

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

工具让智能体能够采取行动：例如获取数据、运行代码、调用外部 API，甚至进行计算机操作。SDK 支持五类工具：

-   由OpenAI托管的工具：与模型一起在 OpenAI 服务上运行。
-   本地运行时工具：在你的环境中运行（计算机操作、shell、应用补丁）。
-   工具调用：将任何 Python 函数包装为工具。
-   Agents as tools：将智能体暴露为可调用工具，而无需完整的任务转移。
-   实验性：Codex 工具：通过工具调用运行工作区作用域的 Codex 任务。

## 由OpenAI托管的工具

在使用 [`OpenAIResponsesModel`][agents.models.openai_responses.OpenAIResponsesModel] 时，OpenAI 提供了一些内置工具：

-   [`WebSearchTool`][agents.tool.WebSearchTool] 让智能体进行网络检索。
-   [`FileSearchTool`][agents.tool.FileSearchTool] 允许从你的 OpenAI 向量存储中检索信息。
-   [`CodeInterpreterTool`][agents.tool.CodeInterpreterTool] 让 LLM 在沙盒环境中执行代码。
-   [`HostedMCPTool`][agents.tool.HostedMCPTool] 将远程 MCP 服务的工具暴露给模型。
-   [`ImageGenerationTool`][agents.tool.ImageGenerationTool] 根据提示词生成图像。

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

## 本地运行时工具

本地运行时工具在你的环境中执行，并且需要你提供实现：

-   [`ComputerTool`][agents.tool.ComputerTool]：实现 [`Computer`][agents.computer.Computer] 或 [`AsyncComputer`][agents.computer.AsyncComputer] 接口，以启用 GUI/浏览器自动化。
-   [`ShellTool`][agents.tool.ShellTool] 或 [`LocalShellTool`][agents.tool.LocalShellTool]：提供一个 shell 执行器来运行命令。
-   [`ApplyPatchTool`][agents.tool.ApplyPatchTool]：实现 [`ApplyPatchEditor`][agents.editor.ApplyPatchEditor]，以在本地应用 diff。

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

你可以将任何 Python 函数作为工具使用。Agents SDK 会自动设置该工具：

-   工具名称将是 Python 函数的名称（或你也可以提供名称）
-   工具描述将来自该函数的 docstring（或你也可以提供描述）
-   函数输入的 schema 会根据函数参数自动创建
-   每个输入的描述来自该函数的 docstring，除非禁用

我们使用 Python 的 `inspect` 模块提取函数签名，同时使用 [`griffe`](https://mkdocstrings.github.io/griffe/) 解析 docstring，并用 `pydantic` 创建 schema。

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

1.  你可以使用任何 Python 类型作为函数参数，且函数可以是同步或异步的。
2.  如果存在 docstring，则会用于捕获描述和参数描述。
3.  函数可以选择接收 `context`（必须是第一个参数）。你也可以设置覆盖项，例如工具名称、描述、使用哪种 docstring 风格等。
4.  你可以将装饰后的函数传入 tools 列表。

??? note "展开以查看输出"

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

除了返回文本输出之外，你还可以返回一个或多个图像或文件作为工具调用的输出。为此，你可以返回以下任意类型：

-   图像：[`ToolOutputImage`][agents.tool.ToolOutputImage]（或其 TypedDict 版本 [`ToolOutputImageDict`][agents.tool.ToolOutputImageDict]）
-   文件：[`ToolOutputFileContent`][agents.tool.ToolOutputFileContent]（或其 TypedDict 版本 [`ToolOutputFileContentDict`][agents.tool.ToolOutputFileContentDict]）
-   文本：字符串或可转为字符串的对象，或 [`ToolOutputText`][agents.tool.ToolOutputText]（或其 TypedDict 版本 [`ToolOutputTextDict`][agents.tool.ToolOutputTextDict]）

### 自定义工具调用

有时，你不想将 Python 函数作为工具。你也可以直接创建一个 [`FunctionTool`][agents.tool.FunctionTool]。你需要提供：

-   `name`
-   `description`
-   `params_json_schema`，即参数的 JSON schema
-   `on_invoke_tool`，即一个异步函数：接收 [`ToolContext`][agents.tool_context.ToolContext] 和以 JSON 字符串形式传入的参数，并且必须将工具输出以字符串形式返回。

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

如前所述，我们会自动解析函数签名以提取工具 schema，并解析 docstring 以提取工具及各参数的描述。补充说明：

1. 签名解析通过 `inspect` 模块完成。我们使用类型注解来理解参数类型，并动态构建一个 Pydantic 模型来表示整体 schema。它支持大多数类型，包括 Python 基础类型、Pydantic 模型、TypedDict 等。
2. 我们使用 `griffe` 解析 docstring。支持的 docstring 格式包括 `google`、`sphinx` 和 `numpy`。我们会尝试自动检测 docstring 格式，但这是尽力而为；你也可以在调用 `function_tool` 时显式设置。你还可以将 `use_docstring_info` 设为 `False` 来禁用 docstring 解析。

schema 提取的代码位于 [`agents.function_schema`][]。

## Agents as tools

在某些工作流中，你可能希望由一个中心智能体来编排一组专门的智能体，而不是进行控制权任务转移。你可以通过将智能体建模为工具来实现这一点。

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

### 自定义工具智能体

`agent.as_tool` 函数是一个便捷方法，用于更轻松地将智能体转换为工具。但它不支持所有配置；例如，你无法设置 `max_turns`。对于高级用例，请在你的工具实现中直接使用 `Runner.run`：

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

### 自定义输出提取

在某些情况下，你可能希望在将工具智能体的输出返回给中心智能体之前对其进行修改。这在以下场景中可能很有用：

-   从子智能体的聊天历史中提取特定信息（例如 JSON payload）。
-   转换或重新格式化智能体的最终答案（例如将 Markdown 转为纯文本或 CSV）。
-   校验输出，或在智能体响应缺失或格式不正确时提供回退值。

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

### 流式传输嵌套智能体运行

向 `as_tool` 传入 `on_stream` 回调，以监听嵌套智能体发出的流式事件，同时在流完成后仍返回其最终输出。

```python
from agents import AgentToolStreamEvent


async def handle_stream(event: AgentToolStreamEvent) -> None:
    # Inspect the underlying StreamEvent along with agent metadata.
    print(f"[stream] {event['agent']['name']} :: {event['event'].type}")


billing_agent_tool = billing_agent.as_tool(
    tool_name="billing_helper",
    tool_description="Answer billing questions.",
    on_stream=handle_stream,  # Can be sync or async.
)
```

预期行为：

- 事件类型与 `StreamEvent["type"]` 镜像一致：`raw_response_event`、`run_item_stream_event`、`agent_updated_stream_event`。
- 提供 `on_stream` 会自动以流式模式运行嵌套智能体，并在返回最终输出之前消费完流。
- 处理器可以是同步或异步的；每个事件会按到达顺序依次交付。
- 当工具通过模型的工具调用触发时会包含 `tool_call_id`；直接调用时可能为 `None`。
- 完整可运行示例参见 `examples/agent_patterns/agents_as_tools_streaming.py`。

### 条件式工具启用

你可以使用 `is_enabled` 参数在运行时按条件启用或禁用智能体工具。这使你能够基于上下文、用户偏好或运行时条件，动态过滤 LLM 可用的工具。

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

`is_enabled` 参数支持：

-   **布尔值**：`True`（始终启用）或 `False`（始终禁用）
-   **可调用函数**：接收 `(context, agent)` 并返回布尔值的函数
-   **异步函数**：用于复杂条件逻辑的异步函数

被禁用的工具在运行时对 LLM 完全隐藏，因此可用于：

-   基于用户权限的功能门控
-   环境特定的工具可用性（dev vs prod）
-   对不同工具配置进行 A/B 测试
-   基于运行时状态的动态工具过滤

## 实验性：Codex 工具

`codex_tool` 封装了 Codex CLI，使智能体能够在一次工具调用期间运行工作区作用域的任务（shell、文件编辑、MCP 工具）。该接口为实验性，可能会发生变化。

```python
from agents import Agent
from agents.extensions.experimental.codex import ThreadOptions, codex_tool

agent = Agent(
    name="Codex Agent",
    instructions="Use the codex tool to inspect the workspace and answer the question.",
    tools=[
        codex_tool(
            sandbox_mode="workspace-write",
            working_directory="/path/to/repo",
            default_thread_options=ThreadOptions(
                model="gpt-5.2-codex",
                network_access_enabled=True,
                web_search_enabled=False,
            ),
            persist_session=True,
        )
    ],
)
```

注意事项：

-   认证：设置 `CODEX_API_KEY`（推荐）或 `OPENAI_API_KEY`，或传入 `codex_options={"api_key": "..."}`。
-   运行时：`codex_options.base_url` 会覆盖 CLI base URL，`codex_options.codex_path_override`（或 `CODEX_PATH`）用于选择二进制文件。
-   环境：`codex_options.env` 完全控制子进程环境。提供后，子进程不会继承 `os.environ`。
-   输入：工具调用必须在 `inputs` 中至少包含一项 `{ "type": "text", "text": ... }` 或 `{ "type": "local_image", "path": ... }`。
-   安全：将 `sandbox_mode` 与 `working_directory` 配对使用；在非 Git 仓库中设置 `skip_git_repo_check=True`。
-   行为：`persist_session=True` 会复用单个 Codex thread，并返回其 `thread_id`。
-   流式传输：`on_stream` 会接收 Codex 事件（推理、命令执行、MCP 工具调用、文件变更、网络检索）。
-   输出：结果包含 `response`、`usage` 和 `thread_id`；usage 会加入到 `RunContextWrapper.usage`。
-   结构：当你需要类型化输出时，`output_schema` 会强制 Codex 以 structured outputs 响应。
-   完整可运行示例参见 `examples/tools/codex.py`。

## 在工具调用中处理错误

当你通过 `@function_tool` 创建工具调用时，可以传入 `failure_error_function`。这是一个在工具调用崩溃时向 LLM 提供错误响应的函数。

-   默认情况下（即不传任何值），会运行 `default_tool_error_function`，告知 LLM 发生了错误。
-   如果你传入自定义错误函数，则会改为运行该函数，并将其响应发送给 LLM。
-   如果你显式传入 `None`，则任何工具调用错误都会被重新抛出，由你处理。例如，如果模型生成了无效 JSON，则可能是 `ModelBehaviorError`；如果你的代码崩溃，则可能是 `UserError` 等。

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

如果你是手动创建 `FunctionTool` 对象，那么你必须在 `on_invoke_tool` 函数内部处理错误。

================
File: docs/zh/tracing.md
================
---
search:
  exclude: true
---
# 追踪

Agents SDK 内置追踪功能，会在智能体运行期间收集全面的事件记录：LLM 生成、工具调用、任务转移、安全防护措施，甚至是发生的自定义事件。使用 [Traces 仪表板](https://platform.openai.com/traces)，你可以在开发和生产环境中调试、可视化并监控你的工作流。

!!!note

    追踪默认启用。有两种方式可以禁用追踪：

    1. 你可以通过设置环境变量 `OPENAI_AGENTS_DISABLE_TRACING=1` 来全局禁用追踪
    2. 你可以通过将 [`agents.run.RunConfig.tracing_disabled`][] 设置为 `True` 来为单次运行禁用追踪

***对于在使用 OpenAI API 且遵循 Zero Data Retention (ZDR) 策略的组织，追踪不可用。***

## Traces 与 spans

-   **Traces** 表示一个“工作流”的单次端到端操作。它们由 Spans 组成。Traces 具有以下属性：
    -   `workflow_name`：逻辑工作流或应用。例如 “Code generation” 或 “Customer service”。
    -   `trace_id`：Trace 的唯一 ID。如果你未传入，会自动生成。格式必须为 `trace_<32_alphanumeric>`。
    -   `group_id`：可选的分组 ID，用于将同一对话中的多个 trace 关联起来。例如，你可以使用聊天线程 ID。
    -   `disabled`：若为 True，则不会记录该 trace。
    -   `metadata`：该 trace 的可选元数据。
-   **Spans** 表示具有开始与结束时间的操作。Spans 具有：
    -   `started_at` 和 `ended_at` 时间戳。
    -   `trace_id`：表示其所属的 trace
    -   `parent_id`：指向该 Span 的父 Span（如果有）
    -   `span_data`：关于该 Span 的信息。例如，`AgentSpanData` 包含关于 Agent 的信息，`GenerationSpanData` 包含关于 LLM 生成的信息，等等。

## 默认追踪

默认情况下，SDK 会追踪以下内容：

-   整个 `Runner.{run, run_sync, run_streamed}()` 会被包裹在 `trace()` 中。
-   每次智能体运行时，都会被包裹在 `agent_span()` 中
-   LLM 生成会被包裹在 `generation_span()` 中
-   工具调用中的每次函数调用都会被包裹在 `function_span()` 中
-   安全防护措施会被包裹在 `guardrail_span()` 中
-   任务转移会被包裹在 `handoff_span()` 中
-   音频输入（speech-to-text）会被包裹在 `transcription_span()` 中
-   音频输出（text-to-speech）会被包裹在 `speech_span()` 中
-   相关的音频 span 可能会作为子项挂在 `speech_group_span()` 下

默认情况下，trace 名称为 “Agent workflow”。如果你使用 `trace`，可以设置该名称；或者你也可以通过 [`RunConfig`][agents.run.RunConfig] 配置名称及其他属性。

此外，你还可以配置[自定义 trace 处理器](#custom-tracing-processors)，将 trace 推送到其他目标位置（作为替代或第二目标）。

## 更高层级的 traces

有时，你可能希望多次对 `run()` 的调用都属于同一个 trace。你可以通过用 `trace()` 包裹整个代码来实现。

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

1. 因为对 `Runner.run` 的两次调用都包裹在 `with trace()` 中，因此各次运行会成为整体 trace 的一部分，而不是创建两个 trace。

## 创建 traces

你可以使用 [`trace()`][agents.tracing.trace] 函数创建 trace。Trace 需要被启动和结束。你有两种选择：

1. **推荐**：将 trace 作为上下文管理器使用，即 `with trace(...) as my_trace`。这样会在正确的时间自动启动与结束该 trace。
2. 你也可以手动调用 [`trace.start()`][agents.tracing.Trace.start] 和 [`trace.finish()`][agents.tracing.Trace.finish]。

当前 trace 通过 Python 的 [`contextvar`](https://docs.python.org/3/library/contextvars.html) 进行跟踪。这意味着它会自动支持并发。如果你手动启动/结束 trace，则需要在 `start()`/`finish()` 中传入 `mark_as_current` 和 `reset_current` 来更新当前 trace。

## 创建 spans

你可以使用各种 [`*_span()`][agents.tracing.create] 方法创建 span。一般来说，你不需要手动创建 spans。我们提供了 [`custom_span()`][agents.tracing.custom_span] 函数，用于追踪自定义 span 信息。

Spans 会自动属于当前 trace，并嵌套在最近的当前 span 之下；当前 span 同样通过 Python 的 [`contextvar`](https://docs.python.org/3/library/contextvars.html) 进行跟踪。

## 敏感数据

某些 span 可能会捕获潜在的敏感数据。

`generation_span()` 会存储 LLM 生成的输入/输出，`function_span()` 会存储函数调用的输入/输出。这些可能包含敏感数据，因此你可以通过 [`RunConfig.trace_include_sensitive_data`][agents.run.RunConfig.trace_include_sensitive_data] 禁用对这些数据的捕获。

同样，音频 span 默认包含对输入与输出音频的 base64 编码 PCM 数据。你可以通过配置 [`VoicePipelineConfig.trace_include_sensitive_audio_data`][agents.voice.pipeline_config.VoicePipelineConfig.trace_include_sensitive_audio_data] 来禁用对音频数据的捕获。

默认情况下，`trace_include_sensitive_data` 为 `True`。你可以在运行应用之前，通过导出 `OPENAI_AGENTS_TRACE_INCLUDE_SENSITIVE_DATA` 环境变量为 `true/1` 或 `false/0` 来在不改代码的情况下设置默认值。

## 自定义追踪处理器

追踪的高层架构如下：

-   在初始化时，我们创建一个全局 [`TraceProvider`][agents.tracing.setup.TraceProvider]，负责创建 trace。
-   我们为 `TraceProvider` 配置一个 [`BatchTraceProcessor`][agents.tracing.processors.BatchTraceProcessor]，它会将 traces/spans 以批处理方式发送给 [`BackendSpanExporter`][agents.tracing.processors.BackendSpanExporter]，后者会以批处理方式将 spans 与 traces 导出到 OpenAI 后端。

要自定义此默认设置，将 trace 发送到替代或额外的后端，或修改 exporter 行为，你有两种选择：

1. [`add_trace_processor()`][agents.tracing.add_trace_processor] 允许你添加一个**额外的** trace 处理器，它会在 traces 与 spans 就绪时接收它们。这使你可以在将 trace 发送到 OpenAI 后端之外，额外执行自己的处理。
2. [`set_trace_processors()`][agents.tracing.set_trace_processors] 允许你用自己的 trace 处理器**替换**默认处理器。这意味着除非你包含了一个会将 traces 发送到 OpenAI 后端的 `TracingProcessor`，否则 traces 将不会被发送到 OpenAI 后端。

## 使用非 OpenAI 模型进行追踪

你可以使用 OpenAI API key 搭配非 OpenAI 模型，在无需禁用追踪的情况下，在 OpenAI Traces 仪表板中启用免费的追踪功能。

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

如果你只需要为单次运行使用不同的追踪 key，请通过 `RunConfig` 传入，而不是修改全局 exporter。

```python
from agents import Runner, RunConfig

await Runner.run(
    agent,
    input="Hello",
    run_config=RunConfig(tracing={"api_key": "sk-tracing-123"}),
)
```

## 说明
- 在 Openai Traces 仪表板中查看免费的 traces。

## 外部追踪处理器列表

-   [Weights & Biases](https://weave-docs.wandb.ai/guides/integrations/openai_agents)
-   [Arize-Phoenix](https://docs.arize.com/phoenix/tracing/integrations-tracing/openai-agents-sdk)
-   [Future AGI](https://docs.futureagi.com/future-agi/products/observability/auto-instrumentation/openai_agents)
-   [MLflow（自托管/OSS）](https://mlflow.org/docs/latest/tracing/integrations/openai-agent)
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

Sometimes, you want to observe the lifecycle of an agent. For example, you may want to log events, or pre-fetch data when certain events occur. You can hook into the agent lifecycle with the `hooks` property. Subclass the [`AgentHooks`][agents.lifecycle.AgentHooks] class, and override the methods you're interested in.

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
# Configuring the SDK

## API keys and clients

By default, the SDK looks for the `OPENAI_API_KEY` environment variable for LLM requests and tracing, as soon as it is imported. If you are unable to set that environment variable before your app starts, you can use the [set_default_openai_key()][agents.set_default_openai_key] function to set the key.

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

Tracing is enabled by default. It uses the OpenAI API keys from the section above by default (i.e. the environment variable or the default key you set). You can specifically set the API key used for tracing by using the [`set_tracing_export_api_key`][agents.set_tracing_export_api_key] function.

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

## Debug logging

The SDK has two Python loggers without any handlers set. By default, this means that warnings and errors are sent to `stdout`, but other logs are suppressed.

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

Certain logs may contain sensitive data (for example, user data). If you want to disable this data from being logged, set the following environment variables.

To disable logging LLM inputs and outputs:

```bash
export OPENAI_AGENTS_DONT_LOG_MODEL_DATA=1
```

To disable logging tool inputs and outputs:

```bash
export OPENAI_AGENTS_DONT_LOG_TOOL_DATA=1
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

-   **[reasoning_content](https://github.com/openai/openai-agents-python/tree/main/examples/reasoning_content):**
    Examples demonstrating how to work with reasoning content and structured outputs.

-   **[research_bot](https://github.com/openai/openai-agents-python/tree/main/examples/research_bot):**
    Simple deep research clone that demonstrates complex multi-agent research workflows.

-   **[tools](https://github.com/openai/openai-agents-python/tree/main/examples/tools):**
    Learn how to implement OAI hosted tools such as:

    -   Web search and web search with filters
    -   File search
    -   Code interpreter
    -   Computer use
    -   Image generation

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
- Tool guardrails apply only to function tools created with [`function_tool`][agents.function_tool]; hosted tools (`WebSearchTool`, `FileSearchTool`, `HostedMCPTool`, `CodeInterpreterTool`, `ImageGenerationTool`) and local runtime tools (`ComputerTool`, `ShellTool`, `ApplyPatchTool`, `LocalShellTool`) do not use this guardrail pipeline.

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

Hosted tools support streaming results in exactly the same way as function tools. Pass `stream=True` to `Runner.run_streamed` to
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
# Orchestrating multiple agents

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

This pattern is great when the task is open-ended and you want to rely on the intelligence of an LLM. The most important tactics here are:

1. Invest in good prompts. Make it clear what tools are available, how to use them, and what parameters it must operate within.
2. Monitor your app and iterate on it. See where things go wrong, and iterate on your prompts.
3. Allow the agent to introspect and improve. For example, run it in a loop, and let it critique itself; or, provide error messages and let it improve.
4. Have specialized agents that excel in one task, rather than having a general purpose agent that is expected to be good at anything.
5. Invest in [evals](https://platform.openai.com/docs/guides/evals). This lets you train your agents to improve and get better at tasks.

## Orchestrating via code

While orchestrating via LLM is powerful, orchestrating via code makes tasks more deterministic and predictable, in terms of speed, cost and performance. Common patterns here are:

-   Using [structured outputs](https://platform.openai.com/docs/guides/structured-outputs) to generate well formed data that you can inspect with your code. For example, you might ask an agent to classify the task into a few categories, and then pick the next agent based on the category.
-   Chaining multiple agents by transforming the output of one into the input of the next. You can decompose a task like writing a blog post into a series of steps - do research, write an outline, write the blog post, critique it, and then improve it.
-   Running the agent that performs the task in a `while` loop with an agent that evaluates and provides feedback, until the evaluator says the output passes certain criteria.
-   Running multiple agents in parallel, e.g. via Python primitives like `asyncio.gather`. This is useful for speed when you have multiple tasks that don't depend on each other.

We have a number of examples in [`examples/agent_patterns`](https://github.com/openai/openai-agents-python/tree/main/examples/agent_patterns).

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

Agents are defined with instructions, a name, and optional config (such as `model_config`)

```python
from agents import Agent

agent = Agent(
    name="Math Tutor",
    instructions="You provide help with math problems. Explain your reasoning at each step and include examples",
)
```

## Add a few more agents

Additional agents can be defined in the same way. `handoff_descriptions` provide additional context for determining handoff routing

```python
from agents import Agent

history_tutor_agent = Agent(
    name="History Tutor",
    handoff_description="Specialist agent for historical questions",
    instructions="You provide assistance with historical queries. Explain important events and context clearly.",
)

math_tutor_agent = Agent(
    name="Math Tutor",
    handoff_description="Specialist agent for math questions",
    instructions="You provide help with math problems. Explain your reasoning at each step and include examples",
)
```

## Define your handoffs

On each agent, you can define an inventory of outgoing handoff options that the agent can choose from to decide how to make progress on their task.

```python
triage_agent = Agent(
    name="Triage Agent",
    instructions="You determine which agent to use based on the user's homework question",
    handoffs=[history_tutor_agent, math_tutor_agent]
)
```

## Run the agent orchestration

Let's check that the workflow runs and the triage agent correctly routes between the two specialist agents.

```python
from agents import Runner

async def main():
    result = await Runner.run(triage_agent, "who was the first president of the united states?")
    print(result.final_output)
```

## Add a guardrail

You can define custom guardrails to run on the input or output.

```python
from agents import GuardrailFunctionOutput, Agent, Runner
from pydantic import BaseModel


class HomeworkOutput(BaseModel):
    is_homework: bool
    reasoning: str

guardrail_agent = Agent(
    name="Guardrail check",
    instructions="Check if the user is asking about homework.",
    output_type=HomeworkOutput,
)

async def homework_guardrail(ctx, agent, input_data):
    result = await Runner.run(guardrail_agent, input_data, context=ctx.context)
    final_output = result.final_output_as(HomeworkOutput)
    return GuardrailFunctionOutput(
        output_info=final_output,
        tripwire_triggered=not final_output.is_homework,
    )
```

## Put it all together

Let's put it all together and run the entire workflow, using handoffs and the input guardrail.

```python
from agents import Agent, InputGuardrail, GuardrailFunctionOutput, Runner
from agents.exceptions import InputGuardrailTripwireTriggered
from pydantic import BaseModel
import asyncio

class HomeworkOutput(BaseModel):
    is_homework: bool
    reasoning: str

guardrail_agent = Agent(
    name="Guardrail check",
    instructions="Check if the user is asking about homework.",
    output_type=HomeworkOutput,
)

math_tutor_agent = Agent(
    name="Math Tutor",
    handoff_description="Specialist agent for math questions",
    instructions="You provide help with math problems. Explain your reasoning at each step and include examples",
)

history_tutor_agent = Agent(
    name="History Tutor",
    handoff_description="Specialist agent for historical questions",
    instructions="You provide assistance with historical queries. Explain important events and context clearly.",
)


async def homework_guardrail(ctx, agent, input_data):
    result = await Runner.run(guardrail_agent, input_data, context=ctx.context)
    final_output = result.final_output_as(HomeworkOutput)
    return GuardrailFunctionOutput(
        output_info=final_output,
        tripwire_triggered=not final_output.is_homework,
    )

triage_agent = Agent(
    name="Triage Agent",
    instructions="You determine which agent to use based on the user's homework question",
    handoffs=[history_tutor_agent, math_tutor_agent],
    input_guardrails=[
        InputGuardrail(guardrail_function=homework_guardrail),
    ],
)

async def main():
    # Example 1: History question
    try:
        result = await Runner.run(triage_agent, "who was the first president of the united states?")
        print(result.final_output)
    except InputGuardrailTripwireTriggered as e:
        print("Guardrail blocked this input:", e)

    # Example 2: General/philosophical question
    try:
        result = await Runner.run(triage_agent, "What is the meaning of life?")
        print(result.final_output)
    except InputGuardrailTripwireTriggered as e:
        print("Guardrail blocked this input:", e)

if __name__ == "__main__":
    asyncio.run(main())
```

## View your traces

To review what happened during your agent run, navigate to the [Trace viewer in the OpenAI Dashboard](https://platform.openai.com/traces) to view traces of your agent runs.

## Next steps

Learn how to build more complex agentic flows:

-   Learn about how to configure [Agents](agents.md).
-   Learn about [running agents](running_agents.md).
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

## Final output

The [`final_output`][agents.result.RunResultBase.final_output] property contains the final output of the last agent that ran. This is either:

-   a `str`, if the last agent didn't have an `output_type` defined
-   an object of type `last_agent.output_type`, if the agent had an output type defined.

!!! note

    `final_output` is of type `Any`. We can't statically type this, because of handoffs. If handoffs occur, that means any Agent might be the last agent, so we don't statically know the set of possible output types.

## Inputs for the next turn

You can use [`result.to_input_list()`][agents.result.RunResultBase.to_input_list] to turn the result into an input list that concatenates the original input you provided, to the items generated during the agent run. This makes it convenient to take the outputs of one agent run and pass them into another run, or to run it in a loop and append new user inputs each time.

## Last agent

The [`last_agent`][agents.result.RunResultBase.last_agent] property contains the last agent that ran. Depending on your application, this is often useful for the next time the user inputs something. For example, if you have a frontline triage agent that hands off to a language-specific agent, you can store the last agent, and re-use it the next time the user messages the agent.

## New items

The [`new_items`][agents.result.RunResultBase.new_items] property contains the new items generated during the run. The items are [`RunItem`][agents.items.RunItem]s. A run item wraps the raw item generated by the LLM.

-   [`MessageOutputItem`][agents.items.MessageOutputItem] indicates a message from the LLM. The raw item is the message generated.
-   [`HandoffCallItem`][agents.items.HandoffCallItem] indicates that the LLM called the handoff tool. The raw item is the tool call item from the LLM.
-   [`HandoffOutputItem`][agents.items.HandoffOutputItem] indicates that a handoff occurred. The raw item is the tool response to the handoff tool call. You can also access the source/target agents from the item.
-   [`ToolCallItem`][agents.items.ToolCallItem] indicates that the LLM invoked a tool.
-   [`ToolCallOutputItem`][agents.items.ToolCallOutputItem] indicates that a tool was called. The raw item is the tool response. You can also access the tool output from the item.
-   [`ReasoningItem`][agents.items.ReasoningItem] indicates a reasoning item from the LLM. The raw item is the reasoning generated.

## Other information

### Guardrail results

The [`input_guardrail_results`][agents.result.RunResultBase.input_guardrail_results] and [`output_guardrail_results`][agents.result.RunResultBase.output_guardrail_results] properties contain the results of the guardrails, if any. Guardrail results can sometimes contain useful information you want to log or store, so we make these available to you.

Tool guardrail results are available separately as [`tool_input_guardrail_results`][agents.result.RunResultBase.tool_input_guardrail_results] and [`tool_output_guardrail_results`][agents.result.RunResultBase.tool_output_guardrail_results]. These guardrails can be attached to tools, and those tool calls execute the guardrails during the agent workflow.

### Raw responses

The [`raw_responses`][agents.result.RunResultBase.raw_responses] property contains the [`ModelResponse`][agents.items.ModelResponse]s generated by the LLM.

### Original input

The [`input`][agents.result.RunResultBase.input] property contains the original input you provided to the `run` method. In most cases you won't need this, but it's available in case you do.

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

## The agent loop

When you use the run method in `Runner`, you pass in a starting agent and input. The input can either be a string (which is considered a user message), or a list of input items, which are the items in the OpenAI Responses API.

The runner then runs a loop:

1. We call the LLM for the current agent, with the current input.
2. The LLM produces its output.
    1. If the LLM returns a `final_output`, the loop ends and we return the result.
    2. If the LLM does a handoff, we update the current agent and input, and re-run the loop.
    3. If the LLM produces tool calls, we run those tool calls, append the results, and re-run the loop.
3. If we exceed the `max_turns` passed, we raise a [`MaxTurnsExceeded`][agents.exceptions.MaxTurnsExceeded] exception.

!!! note

    The rule for whether the LLM output is considered as a "final output" is that it produces text output with the desired type, and there are no tool calls.

## Streaming

Streaming allows you to additionally receive streaming events as the LLM runs. Once the stream is done, the [`RunResultStreaming`][agents.result.RunResultStreaming] will contain the complete information about the run, including all the new outputs produced. You can call `.stream_events()` for the streaming events. Read more in the [streaming guide](streaming.md).

## Run config

The `run_config` parameter lets you configure some global settings for the agent run:

-   [`model`][agents.run.RunConfig.model]: Allows setting a global LLM model to use, irrespective of what `model` each Agent has.
-   [`model_provider`][agents.run.RunConfig.model_provider]: A model provider for looking up model names, which defaults to OpenAI.
-   [`model_settings`][agents.run.RunConfig.model_settings]: Overrides agent-specific settings. For example, you can set a global `temperature` or `top_p`.
-   [`input_guardrails`][agents.run.RunConfig.input_guardrails], [`output_guardrails`][agents.run.RunConfig.output_guardrails]: A list of input or output guardrails to include on all runs.
-   [`handoff_input_filter`][agents.run.RunConfig.handoff_input_filter]: A global input filter to apply to all handoffs, if the handoff doesn't already have one. The input filter allows you to edit the inputs that are sent to the new agent. See the documentation in [`Handoff.input_filter`][agents.handoffs.Handoff.input_filter] for more details.
-   [`nest_handoff_history`][agents.run.RunConfig.nest_handoff_history]: Opt-in beta that collapses the prior transcript into a single assistant message before invoking the next agent. This is disabled by default while we stabilize nested handoffs; set to `True` to enable or leave `False` to pass through the raw transcript. All [`Runner` methods](agents.run.Runner) automatically create a `RunConfig` when you do not pass one, so the quickstarts and examples keep the default off, and any explicit [`Handoff.input_filter`][agents.handoffs.Handoff.input_filter] callbacks continue to override it. Individual handoffs can override this setting via [`Handoff.nest_handoff_history`][agents.handoffs.Handoff.nest_handoff_history].
-   [`handoff_history_mapper`][agents.run.RunConfig.handoff_history_mapper]: Optional callable that receives the normalized transcript (history + handoff items) whenever you opt in to `nest_handoff_history`. It must return the exact list of input items to forward to the next agent, allowing you to replace the built-in summary without writing a full handoff filter.
-   [`tracing_disabled`][agents.run.RunConfig.tracing_disabled]: Allows you to disable [tracing](tracing.md) for the entire run.
-   [`tracing`][agents.run.RunConfig.tracing]: Pass a [`TracingConfig`][agents.tracing.TracingConfig] to override exporters, processors, or tracing metadata for this run.
-   [`trace_include_sensitive_data`][agents.run.RunConfig.trace_include_sensitive_data]: Configures whether traces will include potentially sensitive data, such as LLM and tool call inputs/outputs.
-   [`workflow_name`][agents.run.RunConfig.workflow_name], [`trace_id`][agents.run.RunConfig.trace_id], [`group_id`][agents.run.RunConfig.group_id]: Sets the tracing workflow name, trace ID and trace group ID for the run. We recommend at least setting `workflow_name`. The group ID is an optional field that lets you link traces across multiple runs.
-   [`trace_metadata`][agents.run.RunConfig.trace_metadata]: Metadata to include on all traces.
-   [`session_input_callback`][agents.run.RunConfig.session_input_callback]: Customize how new user input is merged with session history before each turn when using Sessions.
-   [`call_model_input_filter`][agents.run.RunConfig.call_model_input_filter]: Hook to edit the fully prepared model input (instructions and input items) immediately before the model call, e.g., to trim history or inject a system prompt.

Nested handoffs are available as an opt-in beta. Enable the collapsed-transcript behavior by passing `RunConfig(nest_handoff_history=True)` or set `handoff(..., nest_handoff_history=True)` to turn it on for a specific handoff. If you prefer to keep the raw transcript (the default), leave the flag unset or provide a `handoff_input_filter` (or `handoff_history_mapper`) that forwards the conversation exactly as you need. To change the wrapper text used in the generated summary without writing a custom mapper, call [`set_conversation_history_wrappers`][agents.handoffs.set_conversation_history_wrappers] (and [`reset_conversation_history_wrappers`][agents.handoffs.reset_conversation_history_wrappers] to restore the defaults).

## Conversations/chat threads

Calling any of the run methods can result in one or more agents running (and hence one or more LLM calls), but it represents a single logical turn in a chat conversation. For example:

1. User turn: user enter text
2. Runner run: first agent calls LLM, runs tools, does a handoff to a second agent, second agent runs more tools, and then produces an output.

At the end of the agent run, you can choose what to show to the user. For example, you might show the user every new item generated by the agents, or just the final output. Either way, the user might then ask a followup question, in which case you can call the run method again.

### Manual conversation management

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

### Automatic conversation management with Sessions

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


### Server-managed conversations

You can also let the OpenAI conversation state feature manage conversation state on the server side, instead of handling it locally with `to_input_list()` or `Sessions`. This allows you to preserve conversation history without manually resending all past messages. See the [OpenAI Conversation state guide](https://platform.openai.com/docs/guides/conversation-state?api-mode=responses) for more details.

OpenAI provides two ways to track state across turns:

#### 1. Using `conversation_id`

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

#### 2. Using `previous_response_id`

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

## Call model input filter

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

Set the hook per run via `run_config` or as a default on your `Runner` to redact sensitive data, trim long histories, or inject additional system guidance.

## Long running agents & human-in-the-loop

### Temporal

You can use the Agents SDK [Temporal](https://temporal.io/) integration to run durable, long-running workflows, including human-in-the-loop tasks. View a demo of Temporal and the Agents SDK working in action to complete long-running tasks [in this video](https://www.youtube.com/watch?v=fFBZqzT4DD8), and [view docs here](https://github.com/temporalio/sdk-python/tree/main/temporalio/contrib/openai_agents). 

### Restate

You can use the Agents SDK [Restate](https://restate.dev/) integration for lightweight, durable agents, including human approval, handoffs, and session management. The integration requires Restate's single-binary runtime as a dependency, and supports running agents as processes/containers or serverless functions.
Read the [overview](https://www.restate.dev/blog/durable-orchestration-for-ai-agents-with-restate-and-openai-sdk) or view the [docs](https://docs.restate.dev/ai) for more details.

## Exceptions

The SDK raises exceptions in certain cases. The full list is in [`agents.exceptions`][]. As an overview:

-   [`AgentsException`][agents.exceptions.AgentsException]: This is the base class for all exceptions raised within the SDK. It serves as a generic type from which all other specific exceptions are derived.
-   [`MaxTurnsExceeded`][agents.exceptions.MaxTurnsExceeded]: This exception is raised when the agent's run exceeds the `max_turns` limit passed to the `Runner.run`, `Runner.run_sync`, or `Runner.run_streamed` methods. It indicates that the agent could not complete its task within the specified number of interaction turns.
-   [`ModelBehaviorError`][agents.exceptions.ModelBehaviorError]: This exception occurs when the underlying model (LLM) produces unexpected or invalid outputs. This can include:
    -   Malformed JSON: When the model provides a malformed JSON structure for tool calls or in its direct output, especially if a specific `output_type` is defined.
    -   Unexpected tool-related failures: When the model fails to use tools in an expected manner
-   [`UserError`][agents.exceptions.UserError]: This exception is raised when you (the person writing code using the SDK) make an error while using the SDK. This typically results from incorrect code implementation, invalid configuration, or misuse of the SDK's API.
-   [`InputGuardrailTripwireTriggered`][agents.exceptions.InputGuardrailTripwireTriggered], [`OutputGuardrailTripwireTriggered`][agents.exceptions.OutputGuardrailTripwireTriggered]: This exception is raised when the conditions of an input guardrail or output guardrail are met, respectively. Input guardrails check incoming messages before processing, while output guardrails check the agent's final response before delivery.

================
File: docs/streaming.md
================
# Streaming

Streaming lets you subscribe to updates of the agent run as it proceeds. This can be useful for showing the end-user progress updates and partial responses.

To stream, you can call [`Runner.run_streamed()`][agents.run.Runner.run_streamed], which will give you a [`RunResultStreaming`][agents.result.RunResultStreaming]. Calling `result.stream_events()` gives you an async stream of [`StreamEvent`][agents.stream_events.StreamEvent] objects, which are described below.

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

## Run item events and agent events

[`RunItemStreamEvent`][agents.stream_events.RunItemStreamEvent]s are higher level events. They inform you when an item has been fully generated. This allows you to push progress updates at the level of "message generated", "tool ran", etc, instead of each token. Similarly, [`AgentUpdatedStreamEvent`][agents.stream_events.AgentUpdatedStreamEvent] gives you updates when the current agent changes (e.g. as the result of a handoff).

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
-   Local runtime tools: run in your environment (computer use, shell, apply patch).
-   Function calling: wrap any Python function as a tool.
-   Agents as tools: expose an agent as a callable tool without a full handoff.
-   Experimental: Codex tool: run workspace-scoped Codex tasks from a tool call.

## Hosted tools

OpenAI offers a few built-in tools when using the [`OpenAIResponsesModel`][agents.models.openai_responses.OpenAIResponsesModel]:

-   The [`WebSearchTool`][agents.tool.WebSearchTool] lets an agent search the web.
-   The [`FileSearchTool`][agents.tool.FileSearchTool] allows retrieving information from your OpenAI Vector Stores.
-   The [`CodeInterpreterTool`][agents.tool.CodeInterpreterTool] lets the LLM execute code in a sandboxed environment.
-   The [`HostedMCPTool`][agents.tool.HostedMCPTool] exposes a remote MCP server's tools to the model.
-   The [`ImageGenerationTool`][agents.tool.ImageGenerationTool] generates images from a prompt.

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

## Local runtime tools

Local runtime tools execute in your environment and require you to supply implementations:

-   [`ComputerTool`][agents.tool.ComputerTool]: implement the [`Computer`][agents.computer.Computer] or [`AsyncComputer`][agents.computer.AsyncComputer] interface to enable GUI/browser automation.
-   [`ShellTool`][agents.tool.ShellTool] or [`LocalShellTool`][agents.tool.LocalShellTool]: provide a shell executor to run commands.
-   [`ApplyPatchTool`][agents.tool.ApplyPatchTool]: implement [`ApplyPatchEditor`][agents.editor.ApplyPatchEditor] to apply diffs locally.

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
-   `on_invoke_tool`, which is an async function that receives a [`ToolContext`][agents.tool_context.ToolContext] and the arguments as a JSON string, and must return the tool output as a string.

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

The `agent.as_tool` function is a convenience method to make it easy to turn an agent into a tool. It doesn't support all configuration though; for example, you can't set `max_turns`. For advanced use cases, use `Runner.run` directly in your tool implementation:

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

### Streaming nested agent runs

Pass an `on_stream` callback to `as_tool` to listen to streaming events emitted by the nested agent while still returning its final output once the stream completes.

```python
from agents import AgentToolStreamEvent


async def handle_stream(event: AgentToolStreamEvent) -> None:
    # Inspect the underlying StreamEvent along with agent metadata.
    print(f"[stream] {event['agent']['name']} :: {event['event'].type}")


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
- `tool_call_id` is present when the tool is invoked via a model tool call; direct calls may leave it `None`.
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

The `codex_tool` wraps the Codex CLI so an agent can run workspace-scoped tasks (shell, file edits, MCP tools)
during a tool call. This surface is experimental and may change.

```python
from agents import Agent
from agents.extensions.experimental.codex import ThreadOptions, codex_tool

agent = Agent(
    name="Codex Agent",
    instructions="Use the codex tool to inspect the workspace and answer the question.",
    tools=[
        codex_tool(
            sandbox_mode="workspace-write",
            working_directory="/path/to/repo",
            default_thread_options=ThreadOptions(
                model="gpt-5.2-codex",
                network_access_enabled=True,
                web_search_enabled=False,
            ),
            persist_session=True,
        )
    ],
)
```

What to know:

-   Auth: set `CODEX_API_KEY` (preferred) or `OPENAI_API_KEY`, or pass `codex_options={"api_key": "..."}`.
-   Runtime: `codex_options.base_url` overrides the CLI base URL, and `codex_options.codex_path_override` (or `CODEX_PATH`) selects the binary.
-   Environment: `codex_options.env` fully controls the subprocess environment. When it is provided, the subprocess does not inherit `os.environ`.
-   Inputs: tool calls must include at least one item in `inputs` with `{ "type": "text", "text": ... }` or `{ "type": "local_image", "path": ... }`.
-   Safety: pair `sandbox_mode` with `working_directory`; set `skip_git_repo_check=True` outside Git repos.
-   Behavior: `persist_session=True` reuses a single Codex thread and returns its `thread_id`.
-   Streaming: `on_stream` receives Codex events (reasoning, command execution, MCP tool calls, file changes, web search).
-   Outputs: results include `response`, `usage`, and `thread_id`; usage is added to `RunContextWrapper.usage`.
-   Structure: `output_schema` enforces structured Codex responses when you need typed outputs.
-   See `examples/tools/codex.py` for a complete runnable sample.

## Handling errors in function tools

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

================
File: docs/tracing.md
================
# Tracing

The Agents SDK includes built-in tracing, collecting a comprehensive record of events during an agent run: LLM generations, tool calls, handoffs, guardrails, and even custom events that occur. Using the [Traces dashboard](https://platform.openai.com/traces), you can debug, visualize, and monitor your workflows during development and in production.

!!!note

    Tracing is enabled by default. There are two ways to disable tracing:

    1. You can globally disable tracing by setting the env var `OPENAI_AGENTS_DISABLE_TRACING=1`
    2. You can disable tracing for a single run by setting [`agents.run.RunConfig.tracing_disabled`][] to `True`

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


## Tracing with Non-OpenAI Models

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

## Notes
- View free traces at Openai Traces dashboard.


## External tracing processors list

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
