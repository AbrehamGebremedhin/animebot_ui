# AnimeBot

AnimeBot is an Anime Recommendation Chatbot designed to provide personalized anime recommendations using natural language queries. By leveraging graph databases, machine learning, and user preferences, the bot offers a dynamic and engaging way to discover anime titles tailored to individual tastes.

## Key Features

- **Natural Language Understanding**: Users can interact with the bot using conversational queries like, "Recommend me some adventure anime with great character development." The bot interprets these inputs and translates them into structured queries.
- **Graph-Based Recommendation System**: Powered by Neo4j, the bot organizes anime metadata as nodes and relationships (e.g., genres, themes, characters, studios). Cypher queries retrieve relevant recommendations based on user preferences and query context.
- **Dynamic User Preference Modeling**: Captures and stores user preferences to refine future recommendations. Learns from interactions to enhance personalization.
- **Rich Metadata Integration**: Incorporates a wide range of attributes, including genres, ratings, reviews, studios, and airing status.
- **Ease of Use**: Simple interface, ideal for anime enthusiasts seeking curated recommendations without manual searching.
