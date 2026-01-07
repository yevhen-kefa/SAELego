<?php ob_start(); ?>
<h2 class="mb-4 text-center">Résultat de votre Mosaïque</h2>

<div class="row justify-content-center">
    <div class="col-md-8">
        <div class="card shadow">
            <div class="card-body text-center">
                
                <?php if (!empty($bricks)): ?>
                    <svg viewBox="0 0 64 64" width="100%" height="auto" style="background: #eee; border: 1px solid #ccc;">
                        <?php foreach ($bricks as $b): ?>
                            <?php 
                                // Calcul largeur/hauteur selon la rotation
                                $width = ($b['rot'] % 2 == 0) ? $b['w'] : $b['h'];
                                $height = ($b['rot'] % 2 == 0) ? $b['h'] : $b['w'];
                            ?>
                            <rect x="<?= $b['x'] ?>" y="<?= $b['y'] ?>" width="<?= $width ?>" height="<?= $height ?>" fill="<?= $b['color'] ?>" stroke="#000" stroke-width="0.05"/>
                        <?php endforeach; ?>
                    </svg>

                    <div class="mt-4">
                        <h4>Détails</h4>
                        <p>Nombre de briques : <strong><?= count($bricks) ?></strong></p>
                        
                        <form action="index.php?page=order" method="POST">
                            <input type="hidden" name="id_upload" value="<?= $uploadId ?>">
                            <input type="hidden" name="brick_data" value="<?= htmlspecialchars(json_encode($bricks)) ?>">
                            <input type="hidden" name="price" value="<?= count($bricks) * 0.10 ?>">
                            <input type="hidden" name="size" value="64">
                            <button type="submit" class="btn btn-primary btn-lg mt-2">
                                Commander les pièces (~<?= number_format(count($bricks) * 0.10, 2) ?> €)
                            </button>
                        </form>
                    </div>

                    <div class="mt-4 pt-3 border-top">
                        <h5>Télécharger les documents</h5>
                        <div class="d-flex justify-content-center gap-2 mt-2 flex-wrap">
                            
                            <form action="index.php?page=download" method="POST" target="_blank">
                                <input type="hidden" name="type" value="csv">
                                <input type="hidden" name="brick_data" value="<?= htmlspecialchars(json_encode($bricks)) ?>">
                                <button type="submit" class="btn btn-outline-success">
                                    <i class="bi bi-file-earmark-spreadsheet"></i> Liste (CSV)
                                </button>
                            </form>

                            <form action="index.php?page=download" method="POST" target="_blank">
                                <input type="hidden" name="type" value="svg">
                                <input type="hidden" name="brick_data" value="<?= htmlspecialchars(json_encode($bricks)) ?>">
                                <button type="submit" class="btn btn-outline-primary">
                                    <i class="bi bi-card-image"></i> Image (SVG)
                                </button>
                            </form>

                            <button onclick="window.print()" class="btn btn-outline-dark">
                                <i class="bi bi-printer"></i> Plan (PDF)
                            </button>
                        </div>
                    </div>

                <?php else: ?>
                    <div class="alert alert-danger">
                        La génération a échoué. Aucune brique n'a été retournée.
                    </div>
                <?php endif; ?>
            </div>
        </div>
    </div>
</div>

<style>
@media print {
    body * {
        visibility: hidden;
    }
    .card-body, .card-body * {
        visibility: visible;
    }
    .card-body {
        position: absolute;
        left: 0;
        top: 0;
        width: 100%;
    }
    button, .btn, form {
        display: none !important;
    }
}
</style>

<?php $content = ob_get_clean(); require __DIR__ . '/layout.php'; ?>