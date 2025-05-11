# Practice Portuguese Words Filler

Fully vibe-coded script which helps you to add words to your [Practice Portuguese](https://www.practiceportuguese.com/) smart review list. It reads the most popular portugues words from a CSV file and automatically adds them to your smart review list.

## Prerequisites

- Docker and Docker Compose

## Setup

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd practiceportuguese-words-filler
   ```

2. Create a `.env` file in the root directory with your Practice Portuguese credentials:
   ```
   USERNAME=your_username
   PASSWORD=your_password
   WORD_LIMIT=10  # Number of words to process
   ```

3. Ensure you have a `data/words.csv` file with your words to add. The file should have one word per line in the first column.

## Usage

Run the application using Docker Compose:
```bash
docker compose build
docker compose run -it app
```

The script will:
1. Log in to your Practice Portuguese account
2. Process words from your CSV file up to the specified limit
3. Add each word to your smart review list
4. If a word fails to be added, it will pause and ask if you want to continue or quit
