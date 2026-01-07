<?php ob_start(); ?>

<link href="https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.5.13/cropper.min.css" rel="stylesheet">
<script src="https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.5.13/cropper.min.js"></script>

<div class="container mt-4">
    <div class="row">
        <div class="col-md-8 text-center bg-dark p-3 rounded">
            <div style="max-height: 500px; display: flex; align-items: center; justify-content: center;">
                <img id="image-preview" 
                     src="image.php?id=<?= $image['id_upload'] ?>" 
                     style="max-width: 100%; max-height: 500px; display: block;">
            </div>
        </div>

        <div class="col-md-4">
            <h4 class="mb-3">Options de Mosaïque</h4>
            <p class="text-muted">Recadrez l'image pour focaliser sur une zone.</p>

            <div class="d-grid gap-2 mb-4">
                <button type="button" class="btn btn-outline-dark" onclick="startCropper()">
                    <i class="bi bi-crop"></i> Activer le recadrage
                </button>
                <button type="button" class="btn btn-success" id="btn-save-crop" style="display:none;" onclick="saveCrop()">
                    <i class="bi bi-check-circle"></i> Valider le recadrage
                </button>
            </div>

            <div id="crop-message" class="alert alert-info" style="display:none;"></div>

            <hr>

            <form action="index.php?page=results" method="POST" id="form-generate">
                
                <input type="hidden" name="id_upload" id="input-upload-id" value="<?= $image['id_upload'] ?>">

                <div class="mb-3">
                    <label class="form-label fw-bold">Taille de la plaque (Studs)</label>
                    <select name="size_option" class="form-select">
                        <option value="32">32x32 (Petit)</option>
                        <option value="64" selected>64x64 (Standard)</option>
                        <option value="96">96x96 (Grand)</option>
                    </select>
                </div>

                <div class="d-grid">
                    <button type="submit" class="btn btn-primary btn-lg">
                        Générer la Mosaïque
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
    let cropper;
    const image = document.getElementById('image-preview');
    const btnSave = document.getElementById('btn-save-crop');
    const inputId = document.getElementById('input-upload-id');
    const msgBox = document.getElementById('crop-message');


    function startCropper() {
        if (cropper) {
            cropper.destroy();
        }

        cropper = new Cropper(image, {
            aspectRatio: 1,
            viewMode: 1, 
            autoCropArea: 0.8,
            background: false,
        });

        btnSave.style.display = 'block';
        msgBox.style.display = 'none';
    }

    function saveCrop() {
        if (!cropper) return;


        btnSave.disabled = true;
        btnSave.textContent = 'Sauvegarde...';
        const canvas = cropper.getCroppedCanvas({
            width: 512,
            height: 512,
            imageSmoothingEnabled: true,
            imageSmoothingQuality: 'high',
        });

        const base64Image = canvas.toDataURL('image/jpeg');

        fetch('index.php?page=crop', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                image: base64Image,
                original_id: inputId.value
            })
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                inputId.value = data.new_id;
 
                cropper.destroy();
                cropper = null;
                image.src = base64Image; 

                btnSave.style.display = 'none';
                msgBox.style.display = 'block';
                msgBox.className = 'alert alert-success mt-3';
                msgBox.textContent = 'Image recadrée avec succès !';
            } else {
                alert("Erreur serveur : " + (data.error || 'Inconnue'));
            }
        })
        .catch(err => {
            console.error(err);
            alert("Erreur de connexion lors de la sauvegarde.");
        })
        .finally(() => {
            btnSave.disabled = false;
            btnSave.innerHTML = '<i class="bi bi-check-circle"></i> Valider le recadrage';
        });
    }
</script>

<?php $content = ob_get_clean(); require __DIR__ . '/layout.php'; ?>