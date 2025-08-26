from typing import List

from psycopg import AsyncConnection
from psycopg.types.json import Json

from ..data.models import Grammar


async def generate_db(conn: AsyncConnection, grammar_data: List[Grammar]) -> None:
    async with conn.cursor() as cur:
        for g in grammar_data:
            await cur.execute(
                """
                INSERT INTO grammar
                    (language_id, usage, meaning, context, tags, notes, nuance, examples)
                VALUES
                    (%s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    1,  # hardcoded for now to Japanese
                    g.usage,
                    g.meaning,
                    g.context,
                    g.tags,
                    g.notes,
                    g.nuance,
                    Json(
                        [e.model_dump() for e in g.examples]
                    )  # like json dumps for jsonb type in db
                ),
            )
        await conn.commit()
