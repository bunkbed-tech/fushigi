import httpx


def seed_pocketbase(grammar_data, base_url="http://db:8080/api"):
    # Auth against _superusers collection
    auth_response = httpx.post(f"{base_url}/collections/_superusers/auth-with-password", json={
        "identity": "tester@example.com",
        "password": "password123"
    })
    token = auth_response.json()["token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Create Japanese language
    lang_response = httpx.post(f"{base_url}/collections/languages/records",
                              json={"name": "Japanese"},
                              headers=headers)
    language_id = lang_response.json()["id"]

    # Seed grammar data
    for grammar in grammar_data:
        payload = {
            "language_id": language_id,
            "usage": grammar.usage,
            "meaning": grammar.meaning,
            "context": grammar.context,
            "notes": grammar.notes,
            "nuance": grammar.nuance,
            "tags": grammar.tags,
            "examples": [ex.dict() for ex in grammar.examples] if grammar.examples else []
        }
        grammar_response = httpx.post(f"{base_url}/collections/grammar/records",
                             json=payload, headers=headers)
        if grammar_response.status_code != 200:
            print(f"Grammar creation failed: {grammar_response.text}")

    print("Seeding completed!")
