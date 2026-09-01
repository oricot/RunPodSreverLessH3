# AmbientLoop — l'image du travailleur à la requête
#
# Écrit le 01/09. Décision d'Olivier : la mise en route d'une carte louée se paie
# 11 à 15 minutes au tarif GPU, contre 2 à 3 minutes ici. L'usage visé est le TIR
# ISOLÉ ; les lots et les chaînes de maillons restent sur la carte à l'heure.
#
# LES POIDS SONT DANS L'IMAGE, PAS SUR UN VOLUME. C'est ce qui supprime à la fois
# le loyer du volume et sa relecture facturée à chaque réveil : le téléchargement
# d'une image n'est pas facturé (état « Initializing » chez le loueur), et c'est
# le loueur qui les descend sur son propre réseau — rien ne part d'ici.
#
# 44,4 Go pour cinq fichiers, sous la limite documentée de 80 Go.
#
# PAS DE extra_model_paths.yaml : le fichier livré avec le travailleur ne déclare
# ni diffusion_models ni text_encoders, mais il ne sert qu'aux poids montés depuis
# un volume. Les nôtres sont dans l'arborescence de ComfyUI, qui les trouve seule.
#
# PAS DE NŒUD TIERS : le jeu à références n'en demande aucun. Les deux extensions
# du projet (WanVideoWrapper, Stand-In_Preprocessor) ne servent qu'à la recette
# d'identité en Wan, qui n'est pas dans cette image.

FROM runpod/worker-comfyui:5.10.0-base

# LE FICHIER DE CONTRÔLE, COPIÉ MAIS JAMAIS LANCÉ. Le constructeur du loueur
# refusait le dépôt tant que le Dockerfile ne mentionnait aucun gestionnaire —
# le nôtre est déjà dans l'image de base. Ce COPY satisfait le contrôle sans
# rien changer à l'exécution : le fichier est posé, personne ne l'importe.
#
# NE JAMAIS AJOUTER DE `CMD` ICI. Celui de l'image de base lance ComfyUI puis le
# vrai gestionnaire. Le remplacer donnerait un point d'entrée qui répond
# correctement, en ne faisant rien.
COPY rp_handler.py /rp_handler.py

# Le dépôt public de l'éditeur, tel que l'installeur de la carte louée l'emploie
# (tools/pod/installer.sh:234).
ARG MMX=https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main

# LE FORMAT EST FIGÉ À fp8_scaled. Sur la carte louée, l'installeur le choisit
# d'après la version de CUDA trouvée sur la machine ; ici la machine est l'image,
# donc le choix se fait une fois, à la construction. Si un jour le travailleur
# tourne sur une carte qui veut int8_convrot, c'est cette ligne qui change.
ARG FORMAT=fp8_scaled

# Le transformeur — 20,96 Go
RUN comfy model download \
      --url ${MMX}/diffusion_models/minimax_h3_ref2va_pruned_${FORMAT}.safetensors \
      --relative-path models/diffusion_models \
      --filename minimax_h3_ref2va_pruned_${FORMAT}.safetensors

# L'encodeur de texte — 15,69 Go
RUN comfy model download \
      --url ${MMX}/text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors \
      --relative-path models/text_encoders \
      --filename qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors

# Le décodeur d'image — 5,21 Go
RUN comfy model download \
      --url ${MMX}/vae/minimax_h3_video_vae_fp16.safetensors \
      --relative-path models/vae \
      --filename minimax_h3_video_vae_fp16.safetensors

# Le module d'accélération à quatre pas — 1,96 Go
RUN comfy model download \
      --url ${MMX}/loras/minimax_h3_ref2v_turbo_4step_v0.1_comfyui_bf16.safetensors \
      --relative-path models/loras \
      --filename minimax_h3_ref2v_turbo_4step_v0.1_comfyui_bf16.safetensors

# LE DÉCODEUR AUDIO EST OBLIGATOIRE, MÊME MUET — 0,61 Go. Le nœud à références le
# réclame en entrée qu'on veuille du son ou non ; il rend aussi la bande sonore du
# plan. C'est écrit dans l'installeur de la carte louée, et ça vaut ici à
# l'identique (tools/pod/installer.sh:400-406).
RUN comfy model download \
      --url ${MMX}/vae/minimax_h3_audio_vae_fp32.safetensors \
      --relative-path models/vae \
      --filename minimax_h3_audio_vae_fp32.safetensors
