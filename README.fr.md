# Bounce Gateway

> **Comme un UPS pour vos outils IA — un seul endpoint, jamais en panne.**

[🇬🇧 English](README.md) | [🇨🇳 中文](README.zh-CN.md) | [🇫🇷 Français](README.fr.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)

**Bounce Gateway** est un proxy de basculement léger qui offre **un endpoint unique compatible OpenAI** pour tous vos outils d'IA. Configurez-le une fois — il bascule automatiquement lorsque les fournisseurs atteignent leur quota, sont limités en débit ou tombent en panne.

```mermaid
flowchart LR
    Tool[Votre outil IA<br/>Continue / Cline / Aider / etc.]
    GW[Bounce Gateway<br/>localhost:3001]
    T1[Abonnement 🥇]
    T2[Pay-as-you-go 🥈]
    T3[Quota gratuit 🥉]
    T4[GPU local 4️⃣]
    T5[Petit CPU local 5️⃣]
    T6[Démo intégrée 🛟]

    Tool -->|http://localhost:3001/v1| GW
    GW --> T1 -->|échec| T2 -->|échec| T3 -->|échec| T4 -->|échec| T5 -->|échec| T6
```

---

## ✨ Fonctionnalités

- **🔌 Un seul endpoint pour tous vos outils** — Pointez chaque outil IA vers `http://localhost:3001/v1`
- **🔄 Basculement automatique** — 6 niveaux, des abonnements cloud au CPU local. Le premier 200 gagne.
- **🆓 Fonctionne immédiatement** — Mode démo intégré, pas besoin de clé API. Clonez, lancez, c'est prêt.
- **🧠 Vrai modèle local** — Installez Qwen2.5-0.5B (~350Mo) pour une IA hors ligne authentique.
- **📦 Modèles de fournisseurs** — Ajoutez DeepSeek, OpenRouter, SiliconFlow, OpenAI en une commande.
- **🛡️ Classification d'erreurs** — Détecte 401/402/403/429 par fournisseur — distingue quota épuisé de limite de débit.
- **🔀 Streaming** — SSE streaming intégral avec en-têtes `X-Provider-Id`.
- **⚖️ Timeouts par fournisseur** — Aucun fournisseur lent ne bloque la chaîne.

---

## 🚀 Démarrage rapide

```bash
# 1. Installation (ou exécutez directement depuis les sources)
pip install flask requests

# 2. Lancez la passerelle
bounce-gateway
```

```text
=======================================================
  Bounce Gateway — http://localhost:3001
=======================================================

  ⚠️  Aucun fournisseur configuré.
     Installer un modèle local : bounce install-local
     Ajouter un fournisseur :   bounce provider add <template> --key <clé>

    [local_demo     ] Démo statique (secours) → toujours disponible

  📡 POST /v1/chat/completions   ← Format OpenAI
  📡 GET  /v1/models              ← Liste des modèles
  📡 GET  /health                  ← Vérification d'état
```

**Ça tourne.** Pas de clé API, pas de configuration — ça marche.

```bash
# Essayez
curl http://localhost:3001/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"demo-model","messages":[{"role":"user","content":"Bonjour !"}]}'
```

La réponse de la démo explique comment ajouter de vrais fournisseurs et installer un modèle local.

---

## 🔑 Obtenez votre première clé API (Gratuit)

Le moyen le plus simple de démarrer avec l'IA dans le cloud — sans carte bancaire.

### ▶️ Recommandé : OpenRouter

[OpenRouter](https://openrouter.ai/auth?ref=llmswitch) vous offre :
- **1 $ de crédits gratuits** à l'inscription — couvre ~500K tokens de DeepSeek ou Gemini
- **400+ modèles** de 60+ fournisseurs avec une seule clé API
- **Paiement à l'utilisation** sans abonnement mensuel

```bash
# 1. Inscrivez-vous : https://openrouter.ai/auth?ref=llmswitch
# 2. Créez une clé API : https://openrouter.ai/keys
# 3. Ajoutez-la à Bounce :
bounce provider add openrouter-payg --key sk-or-v1-votre-clé-ici
bounce provider add openrouter-free --key sk-or-v1-votre-clé-ici
```

> 💡 **Une seule clé pour 400+ modèles.** OpenRouter gère le routage. Vous recevez une facture unique à la fin du mois.

### ▶️ Alternative : DeepSeek

[DeepSeek](https://platform.deepseek.com/) propose :
- **Coding Plan** à 50 ¥/mois — tokens illimités (deepseek-chat uniquement)
- **Paiement à l'utilisation** — deepseek-chat à partir de 0,28 $/M tokens

```bash
bounce provider add deepseek-payg --key sk-votre-clé-ici
```

---

## 🧠 Installer un vrai modèle local

Pour des réponses IA authentiques sans aucune clé API :

```bash
# Installation interactive — demande confirmation avant téléchargement
bounce install-local
```

Ou en mode direct :

```bash
bounce install-local --yes
```

Ce qui se passe :

1. `pip install llama-cpp-python` (CPU, roue pré-compilée)
2. Télécharge **Qwen2.5-0.5B-Instruct-Q4_K_M.gguf** (~350Mo)
3. L'enregistre comme niveau 5 (`local_tiny`)
4. Redémarrez la passerelle — elle utilise maintenant un **vrai modèle IA**, pas une démo

Le modèle fonctionne entièrement sur CPU, prend ~2-3 secondes par réponse sur un matériel moderne, et fonctionne complètement hors ligne.

> 💡 **Vous avez déjà Ollama ?** L'installateur détecte automatiquement Ollama sur `localhost:11434` et le configure à la place.

---

## ☁️ Modèles de fournisseurs cloud

```bash
# Voir les modèles disponibles
bounce provider templates
```

```text
=======================================================
  Modèles de fournisseurs
=======================================================

  ⭐ Abonnement (Niveau 1) :
    deepseek-cp               → https://api.deepseek.com/v1
    huoshan-cp                → https://ark.cn-beijing.volces.com/api/v3

  💰 Pay-as-you-go (Niveau 2) :
    deepseek-payg             → https://api.deepseek.com/v1
    openrouter-payg ★         → https://openrouter.ai/api/v1 (Recommandé)
    openai-payg               → https://api.openai.com/v1
    siliconflow-payg          → https://api.siliconflow.cn/v1

  🆓 Quota gratuit (Niveau 3) :
    openrouter-free           → https://openrouter.ai/api/v1
    siliconflow-free          → https://api.siliconflow.cn/v1

  🖥️ Local GPU (Niveau 4) :
    qwen27b-direct            → http://192.168.1.100:8080/v1 (llama.cpp)
    qwen35b-uncensored        → http://192.168.1.100:8080/v1 (CPU)
```

Ajouter des fournisseurs :

```bash
# Ajouter un abonnement (Niveau 1 — essayé en premier)
bounce provider add deepseek-cp --key sk-votre-clé

# Ajouter OpenRouter (Niveau 2) — une clé pour 400+ modèles
bounce provider add openrouter-payg --key sk-or-v1...clé

# Ajouter un niveau gratuit (Niveau 3)
bounce provider add openrouter-free --key sk-or-v1...clé

# Ajouter un modèle local (Niveau 4)
bounce provider add qwen27b-direct
```

Après avoir ajouté des fournisseurs, redémarrez la passerelle :

```bash
bounce gateway restart
# ou
bounce gateway start
```

---

## 🔗 Intégrer vos outils

Tous les outils compatibles avec l'API OpenAI se connectent à **un seul endpoint** :

| Outil | Configuration |
|-------|--------------|
| [Continue](https://docs.continue.dev/) | `apiBase: "http://localhost:3001/v1"` |
| [Cline](https://github.com/cline/cline) | Fournisseur compatible OpenAI → `http://localhost:3001/v1` |
| [Aider](https://aider.chat/) | `export OPENAI_API_BASE=http://localhost:3001/v1` |
| [Hermes Agent](https://hermes-agent.nousresearch.com/) | Ajouter un fournisseur avec `base_url: http://localhost:3001/v1` |
| [OpenAI Python SDK](https://pypi.org/project/openai/) | `client = OpenAI(base_url="http://localhost:3001/v1")` |
| [curl](https://curl.se/) | `curl http://localhost:3001/v1/chat/completions ...` |
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) | Passerelle via LiteLLM |

---

## 🏗 Architecture

### La chaîne à 6 niveaux

```
┌──────────────────────────────────────────────────────────┐
│              Bounce Gateway                          │
│  localhost:3001/v1                                       │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────┐                                            │
│  │ Requête  │  → DeepSeek Abo. (Niv.1) ─ 200? ──→ ✅   │
│  │          │    ↓ échec (401/402/timeout)               │
│  │          │  → OpenRouter PAYG (Niv.2) ─ 200? ──→ ✅  │
│  │          │    ↓ échec                                 │
│  │          │  → OpenRouter Gratuit (Niv.3) ─ 200? → ✅  │
│  │          │    ↓ échec                                 │
│  │          │  → GPU Local (Niv.4) ────── 200? ──→ ✅   │
│  │          │    ↓ échec                                 │
│  │          │  → Petit CPU (Niv.5) ────── 200? ──→ ✅   │
│  │          │    ↓ non installé                          │
│  │          │  → Démo intégrée (Niv.6) ─ toujours → ✅  │
│  └──────────┘                                            │
│                                                          │
│  Stratégie : le premier 200 gagne.                       │
│  Pas de vérifications d'état — chaque requête probe.     │
└──────────────────────────────────────────────────────────┘
```

Décisions clés :

- **Pas de vérifications d'état en arrière-plan** — Chaque requête EST la vérification. Ajoute ~200ms par échec, mais évite les faux positifs.
- **Pas de format Anthropic** — 90% des outils supportent le format OpenAI. Claude Code passe par le pont LiteLLM.
- **Classification d'erreurs par fournisseur** — SiliconFlow 403 = "Quota épuisé". DeepSeek 402 = "Solde insuffisant".
- **Transmission de streaming** — Les flux SSE sont transmis avec l'en-tête `X-Provider-Id`.

---

## 📦 Référence CLI

```text
Utilisation :
  bounce list                    Lister les fournisseurs
  bounce use <id>                Changer de fournisseur actif
  bounce status                  Afficher l'état actuel
  bounce env                     Afficher les variables d'env.
  bounce doctor                  Vérifier les configs des outils
  bounce panel                   Panneau d'administration Web
  bounce install-local           Installer petit modèle IA local
  bounce gateway <start|stop|status>   Passerelle de basculement
  bounce provider <add|list|templates>  Gestion des fournisseurs
```

---

## 🔧 Configuration

Fichier de configuration par défaut `~/.bounce/config.json` :

```json
{
  "providers": [
    {
      "id": "openrouter-payg",
      "name": "OpenRouter Pay-as-you-go",
      "type": "cloud",
      "tier": "payg",
      "gateway": true,
      "template_id": "openrouter-payg",
      "api_key_env": "OPENROUTER_KEY",
      "api_base": "https://openrouter.ai/api/v1",
      "models": ["deepseek/deepseek-chat", "openai/gpt-4o"],
      "timeout": 20
    }
  ],
  "gateway": {
    "port": 3001,
    "no_demo": false
  }
}
```

Ordre de résolution des clés API :

1. Champ `api_key` dans la config (si c'est une vraie clé)
2. Référence `env:<NOM_VAR>` (ex. `"api_key": "env:OPENROUTER_KEY"`)
3. Champ `api_key_env` (ex. `"api_key_env": "OPENROUTER_KEY"`)
4. Convention : `{ID_MAJUSCULE}_KEY` (ex. `OPENROUTER_KEY`)

---

## 📋 Prérequis

- **Python 3.10+** avec `flask` et `requests`
- **~350Mo d'espace disque** si vous installez le modèle local
- **Pas de GPU nécessaire** — le modèle intégré fonctionne sur CPU

---

## 🔄 Comparaison

| Fonctionnalité | One API / LiteLLM | **Bounce Gateway** |
|----------------|-------------------|----------------------|
| Philosophie | "Choisissez un canal" | "Ne tombe jamais en panne" |
| Basculement | Changement manuel | **Basculement automatique** |
| Modèle local | Non supporté | **Qwen2.5-0.5B intégré** |
| Mode démo | Nécessite une clé API | **Fonctionne immédiatement** |
| Complexité | Multiples configurations | **Un seul endpoint** |
| Classification | HTTP générique | **Par fournisseur** |
| Taille du code | Grand (multi-services) | **~700 lignes Python** |

---

## 📜 Licence

MIT — faites-en ce que vous voulez.

---

## 🙏 Remerciements

- [Qwen/Qwen2.5-0.5B](https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF) — Un modèle petit mais costaud
- [llama-cpp-python](https://github.com/abetlen/llama-cpp-python) — Moteur d'inférence local
- La communauté LLM qui rend l'IA accessible à tous