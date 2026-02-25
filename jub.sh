#!/usr/bin/env bash
set -e

# 📌 Modell-Repo (Hugging Face GGUF-Variante)
MODEL_REPO="mradermacher/OpenAI-gpt-oss-20B-INSTRUCT-Heretic-Uncensored-GGUF"
QUANT="Q4_K_M"  # empfehlenswerte Quantisierung (~15-16 GB)

# 📁 Zielverzeichnis
TARGET_DIR="$HOME/models/gpt-oss-heretic"

echo "==> Erstelle Zielverzeichnis..."
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

echo "==> Herunterladen des Modells ($MODEL_REPO : $QUANT)..."
# Download via huggingface-cli
huggingface-cli install
huggingface-cli login # nur falls nötig für große Dateien

huggingface-cli download "$MODEL_REPO" \
    --include "*$QUANT*.gguf" --local-dir "$TARGET_DIR"

# 🔄 Falls mehrere Dateien nötig -> zusammenführen
echo "==> (Optional) Zusammenführung mehrerer GGUF-Teile falls vorhanden..."
for f in *.part*; do
    if [ -f "$f" ]; then
        echo "💡 Mögliche mehrteilige GGUF: $f"
    fi
done

# 📝 Optionale Modelfile-Konfiguration
cat > Modelfile <<EOF
FROM ./*.gguf
PARAMETER temperature 0.9
PARAMETER top_p 0.95
PARAMETER num_ctx 32768
EOF

echo "==> Baue Ollama-Modell..."
ollama create gpt-oss-heretic -f Modelfile

echo "==> Fertig! Du kannst das Modell starten mit:"
echo "    ollama run gpt-oss-heretic"