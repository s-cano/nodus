from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .database import init_pool, close_pool
from .routers import red, repartidores, tramos, caminos


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_pool()
    yield
    await close_pool()


app = FastAPI(
    title="NODUS API",
    description="Sistema de Gestión de Red de Fibra Óptica — FGV",
    version="1.0.0",
    lifespan=lifespan,
    root_path="/api",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET"],
    allow_headers=["*"],
)

app.include_router(red.router,          prefix="/v1", tags=["red"])
app.include_router(repartidores.router, prefix="/v1", tags=["repartidores"])
app.include_router(tramos.router,       prefix="/v1", tags=["tramos"])
app.include_router(caminos.router,      prefix="/v1", tags=["caminos"])


@app.get("/health", tags=["sistema"])
async def health():
    return {"status": "ok", "sistema": "NODUS"}
