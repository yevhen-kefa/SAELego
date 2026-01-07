<?php ob_start(); ?>
<div class="container mt-5">
    <h2>Finaliser la commande</h2>
    <div class="row">
        <div class="col-md-6">
            <form action="index.php?page=order_process" method="POST">
                <input type="hidden" name="upload_id" value="<?= $uploadId ?>">
                <input type="hidden" name="total_price" value="<?= $price ?>">
                <input type="hidden" name="size_option" value="<?= $size ?>">
                <input type="hidden" name="filter_css" value="<?= htmlspecialchars($filter) ?>">
                <input type="hidden" name="brick_data" value="<?= htmlspecialchars($brickData) ?>">

                <div class="mb-3">
                    <label class="form-label">Adresse de livraison</label>
                    <input type="text" name="address" class="form-control" required placeholder="123 Rue de la Paix" value="<?= htmlspecialchars($user['address'] ?? '') ?>">
                </div>
                <div class="row">
                    <div class="col-md-6 mb-3">
                        <label class="form-label">Ville</label>
                        <input type="text" name="city" class="form-control" required>
                    </div>
                    <div class="col-md-6 mb-3">
                        <label class="form-label">Code Postal</label>
                        <input type="text" name="zip" class="form-control" required>
                    </div>
                </div>

                <h4 class="mt-4">Paiement</h4>
                <div class="alert alert-info">Paiement simulé par carte bancaire (Sandbox)</div>

                <div class="d-flex justify-content-between align-items-center mt-4">
                    <h3>Total: <?= number_format($price, 2) ?> €</h3>
                    <button type="submit" class="btn btn-success btn-lg">Payer & Commander</button>
                </div>
            </form>
        </div>
        
        <div class="col-md-6">
            <div class="card">
                <div class="card-body">
                    <h5 class="card-title">Récapitulatif</h5>
                    <ul class="list-group list-group-flush">
                        <li class="list-group-item">Taille: <?= $size ?>x<?= $size ?></li>
                        <li class="list-group-item">Prix estimé: <?= number_format($price, 2) ?> €</li>
                    </ul>
                </div>
            </div>
        </div>
    </div>
</div>
<?php $content = ob_get_clean(); require __DIR__ . '/layout.php'; ?>