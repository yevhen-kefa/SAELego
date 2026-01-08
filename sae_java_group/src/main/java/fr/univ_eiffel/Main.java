package fr.univ_eiffel;

import fr.univ_eiffel.domain.DatabaseManager;
import fr.univ_eiffel.factory.OrderService;
import fr.univ_eiffel.image.BicubicStrategy;
import fr.univ_eiffel.image.ImageResizer;
import fr.univ_eiffel.image.ImageToPixelMatrix;
import fr.univ_eiffel.pay.FactoryClient;
import fr.univ_eiffel.pay.PoWMethod;
import fr.univ_eiffel.image.CSolverAdapter;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.File;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;

//TIP To <b>Run</b> code, press <shortcut actionId="Run"/> or
// click the <icon src="AllIcons.Actions.Execute"/> icon in the gutter.
public class Main {
    private static final String EMAIL = "student@univ-eiffel.fr";
    private static final String API_KEY = "94a8f331b671391d4e0e4b850db9036c645b37265a95f9393e9619672691b0c9";

    public static void main(String[] args) throws Exception {

        
        // Database setup
        DatabaseManager db = new DatabaseManager();
        db.importColorsToDb("sae_java_group/colors.csv");
        db.importBrickToDb("sae_java_group/bricks.txt"); 
        
        // Image processing
        System.out.println("--- Image processing ---");
        File imgFile = new File("sae_java_group/test_image.jpg");
        BufferedImage original = ImageIO.read(imgFile);
        
        // Generate pixel matrix from image
        ImageResizer imgRes = new ImageResizer(new BicubicStrategy());
        BufferedImage resizedImg = imgRes.resizeImage(original, 32, 32); 
        ImageToPixelMatrix.setPixelMatrix(resizedImg); 

        // Prepare files for C solver
        System.out.println("--- Prepare files for C solver---");
        // Write image.txt
        ImageToPixelMatrix.writeImageForC("sae_java_group/image.txt");
        // Write briques.txt (export from DB)
        db.exportCatalogForC("sae_java_group/briques.txt");

        // Run C solver
        System.out.println("--- Run C solver ---");
        CSolverAdapter solver = new CSolverAdapter();
        solver.runSolver("./sae_java_group/"); 

        // Analyze results
        System.out.println("--- Analyze results ---");
        Map<String, Integer> itemsToOrder = solver.parseSolution("./sae_java_group/");
        
        System.out.println("Need to order:");
        itemsToOrder.forEach((k, v) -> System.out.println(k + " : " + v));

        // Check account balance and mine if needed
        System.out.println("--- Checking Account Balance ---");
        
        Properties props = new Properties();
        props.setProperty("USER_MAIL", EMAIL);
        props.setProperty("API_KEY", API_KEY);
        
        FactoryClient client = FactoryClient.makeFromProps(props);
        
        try {
            double balance = client.balance();
            System.out.println("Current Balance: " + balance);

            if (balance < 1000) { 
                System.out.println("Balance is low. Starting mining (Proof of Work)...");
                System.out.println("Please wait, solving puzzles...");
                
                PoWMethod miner = new PoWMethod(client);
                while(client.balance() < 500) {
                    miner.pay(100); 
                }
                System.out.println("New Balance: " + client.balance());
            }
        } catch (Exception e) {
            System.err.println("Mining failed. Is the server running? Check FactoryClient URL.");
            e.printStackTrace();
        }

        // Place order
        if (!itemsToOrder.isEmpty()) {
            System.out.println("--- Place order ---");
            OrderService orders = new OrderService(EMAIL, API_KEY);
            
            Map<String, Integer> formattedItems = new HashMap<>();
            for (Map.Entry<String, Integer> entry : itemsToOrder.entrySet()) {
                String oldKey = entry.getKey();
                String newKey = oldKey.replace("x", "-");
                formattedItems.put(newKey, entry.getValue());
            }

            String quoteId = orders.requestQuote(formattedItems); 
            if (quoteId != null) {
                System.out.println("Devis: " + quoteId);
                if (orders.confirmOrder(quoteId)) {
                    System.out.println("Order confirmed!");

                    // Update stock in DB
                    System.out.println("--- Updating Database Stock ---");
                    for (Map.Entry<String, Integer> entry : formattedItems.entrySet()) {
                         String[] parts = entry.getKey().split("/");
                         if(parts.length == 2) {
                             String brickName = parts[0];
                             try {
                                 System.out.println("Added to DB: " + brickName + " (" + parts[1] + ") x " + entry.getValue());
                             } catch (Exception e) {
                                 e.printStackTrace();
                             }
                         }
                    }
                }else {
                    System.out.println("Failed to confirm order.");
                }
            }else {
                System.out.println("Quote failed (null id).");
            }
        }
    }
}