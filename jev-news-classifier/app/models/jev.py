from pydantic import BaseModel


class JEVTokenUsage(BaseModel):
    input_tokens: int = 0
    output_tokens: int = 0
    total_tokens: int = 0


class JEVResponse(BaseModel):
    result: dict
    latency_ms: float
    token_usage: JEVTokenUsage