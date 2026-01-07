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
                                $width = ($b['rot'] % 2 == 0) ? $b['w'] : $b['h'];
                                $height = ($b['rot'] % 2 == 0) ? $b['h'] : $b['w'];
                            ?>
                            <rect x="<?= $b['x'] ?>" y="<?= $b['y'] ?>" width="<?= $width ?>" height="<?= $height ?>" fill="<?= $b['color'] ?>" stroke="#000" stroke-width="0.05"/>
                        <?php endforeach; ?>
                    </svg>

                    <div class="mt-4">
                        <h4>Détails</h4>
                        <p>Nombre de briques : <?= count($bricks) ?></p>
                        
                        <form action="index.php?page=order" method="POST">
                            <input type="hidden" name="id_upload" value="<?= $uploadId ?>">
                            <input type="hidden" name="brick_data" value="<?= htmlspecialchars(json_encode($bricks)) ?>">
                            <input type="hidden" name="price" value="<?= count($bricks) * 0.10 ?>">
                            <input type="hidden" name="size" value="64">
                            <button type="submit" class="btn btn-primary btn-lg mt-2">Commander les pièces</button>
                        </form>
                    </div>
                <?php else: ?>
                    <div class="alert alert-danger">La génération a échoué.</div>
                <?php endif; ?>
            </div>
        </div>
    </div>
</div>
<?php $content = ob_get_clean(); require __DIR__ . '/layout.php'; ?>