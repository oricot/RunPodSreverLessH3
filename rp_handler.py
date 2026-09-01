"""Ce fichier existe pour satisfaire un contrôle, et il ne s'exécute jamais.

Le constructeur d'image de RunPod refuse un dépôt où il ne trouve pas la chaîne
`runpod.serverless.start` — il en déduit qu'il n'y a pas de travailleur à
construire. Message rencontré le 01/09 :

    could not find runpod.serverless.start in your repo

Or notre travailleur est déjà dans l'image dont nous héritons
(`runpod/worker-comfyui`), où le vrai gestionnaire démarre ComfyUI puis appelle
lui-même `runpod.serverless.start`. Le dépôt n'a donc aucun fichier Python, et le
contrôle échoue sur un dépôt parfaitement valide.

DEUX RÈGLES À NE PAS ENFREINDRE :

1. **Le Dockerfile ne copie PAS ce fichier.** Il reste dans le dépôt, il n'entre
   pas dans l'image, il ne tourne pas. Si un jour on ajoute un `COPY`, c'est le
   vrai gestionnaire qu'on remplacerait par celui-ci.

2. **Ne jamais redéclarer de `CMD` dans le Dockerfile.** Celui de l'image de base
   est ce qui lance ComfyUI puis le gestionnaire. Le remplacer donnerait un point
   d'entrée qui répond correctement — en ne faisant rien.

*Réserve : ce message d'erreur n'est documenté nulle part, ni chez le loueur ni
dans ses dépôts. Le diagnostic est une déduction à partir de ce que le message
nomme. S'il revient malgré ce fichier, la variante suivante est de le copier dans
l'image — mais alors il faut reprendre le vrai gestionnaire, pas celui-ci.*
"""

import runpod


def handler(job):
    """Jamais appelé. Voir l'explication en tête de fichier."""
    return {"erreur": "Ce gestionnaire est un leurre de construction. "
                      "Le vrai vit dans l'image runpod/worker-comfyui."}


runpod.serverless.start({"handler": handler})
