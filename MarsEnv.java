import jason.asSyntax.*;
import jason.environment.Environment;
import jason.environment.grid.GridWorldModel;
import jason.environment.grid.GridWorldView;
import jason.environment.grid.Location;

import java.awt.*;
import java.util.*;
import java.util.logging.Logger;

public class MarsEnv extends Environment {

    // GRID 8x8
    public static final int GSize = 8;
    public static final int GARB  = 16;
    public static final int GOLD  = 32;

    public static final Term ns = Literal.parseLiteral("next(slot)");
    public static final Term pg = Literal.parseLiteral("pick(garb)");
    public static final Term po = Literal.parseLiteral("pick(gold)");
    public static final Term dg = Literal.parseLiteral("drop(garb)");
    public static final Term dgo = Literal.parseLiteral("drop(gold)");
    public static final Term bg = Literal.parseLiteral("burn(garb)");
    public static final Literal g1 = Literal.parseLiteral("garbage(r1)");
    public static final Literal g2 = Literal.parseLiteral("garbage(r2)");
    public static final Literal gold1 = Literal.parseLiteral("gold(r1)");

    static Logger logger = Logger.getLogger(MarsEnv.class.getName());

    private MarsModel model;
    private MarsView view;

    @Override
    public void init(String[] args) {
        System.out.println("========================================");
        System.out.println("  INICIALIZANDO MARS ENVIRONMENT");
        System.out.println("  Grid: " + GSize + "x" + GSize);
        System.out.println("========================================");
        model = new MarsModel();
        view = new MarsView(model);
        model.setView(view);
        updatePercepts();
        System.out.println("Ambiente inicializado com sucesso!");
    }

    @Override
    public boolean executeAction(String ag, Structure action) {
        logger.info(ag + " executando: " + action);
        try {
            if (action.equals(ns)) {
                model.nextSlot();
            } else if (action.getFunctor().equals("move_towards")) {
                int x = (int)((NumberTerm)action.getTerm(0)).solve();
                int y = (int)((NumberTerm)action.getTerm(1)).solve();
                model.moveTowards(x, y);
            } else if (action.equals(pg)) {
                model.pickGarb();
            } else if (action.equals(po)) {
                model.pickGold();
            } else if (action.equals(dg)) {
                model.dropGarb();
            } else if (action.equals(dgo)) {
                model.dropGold();
            } else if (action.equals(bg)) {
                model.burnGarb();
            } else {
                return false;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        updatePercepts();

        try {
            Thread.sleep(300);
        } catch (Exception e) {}
        informAgsEnvironmentChanged();
        return true;
    }

    void updatePercepts() {
        clearPercepts();

        Location r1Loc = model.getAgPos(0);
        Location r2Loc = model.getAgPos(1);

        Literal pos1 = Literal.parseLiteral("pos(r1," + r1Loc.x + "," + r1Loc.y + ")");
        Literal pos2 = Literal.parseLiteral("pos(r2," + r2Loc.x + "," + r2Loc.y + ")");
        addPercept(pos1);
        addPercept(pos2);

        if (model.hasObject(GARB, r1Loc)) addPercept(g1);
        if (model.hasObject(GARB, r2Loc)) addPercept(g2);
        if (model.hasObject(GOLD, r1Loc)) addPercept(gold1);

        addPercept(model.getPriorityPercept());

        // Adicionar percepções de mapa para supervisor
        java.util.List<Literal> gridMap = model.getGridMapPercepts();
        for (Literal percept : gridMap) {
            addPercept("supervisor", percept);
        }
    }

    class MarsModel extends GridWorldModel {
        public static final int MErr = 2;
        int nerr;
        boolean r1HasGarb = false;
        boolean r1HasGold = false;
        Random random = new Random(System.currentTimeMillis());
        
        int garbageCollected = 0;
        int goldCollected = 0;
        int garbageBurned = 0;

        private MarsModel() {
            super(GSize, GSize, 2);

            try {
                // ⭐ POSIÇÕES AJUSTADAS PARA GRID 8x8
                setAgPos(0, 7, 0); // r1 (canto superior direito)
                setAgPos(1, 3, 3); // r2 (centro-esquerda)
            } catch (Exception e) {
                e.printStackTrace();
            }

            // ⭐ RECURSOS EXPANDIDOS: 4 LIXOS + 2 OUROS
            System.out.println("\n=== ADICIONANDO RECURSOS AO GRID ===");
            
            // Lixos originais
            add(GARB, 1, 1);
            System.out.println("✓ Lixo adicionado em (1,1)");
            
            add(GARB, 1, 3);
            System.out.println("✓ Lixo adicionado em (1,3)");
            
            // ⭐ NOVOS LIXOS
            add(GARB, 6, 2);
            System.out.println("✓ Lixo adicionado em (6,2)");
            
            add(GARB, 4, 6);
            System.out.println("✓ Lixo adicionado em (4,6)");
            
            // Ouro original
            add(GOLD, 7, 7);
            System.out.println("✓ Ouro adicionado em (7,7)");
            
            // ⭐ NOVO OURO
            add(GOLD, 2, 5);
            System.out.println("✓ Ouro adicionado em (2,5)");
            
            System.out.println("=== RECURSOS ADICIONADOS ===");
            System.out.println("Total: 4 lixos + 2 ouros no grid " + GSize + "x" + GSize + "\n");
        }

        void nextSlot() throws Exception {
            Location r1 = getAgPos(0);
            r1.x++;
            if (r1.x == getWidth()) {
                r1.x = 0;
                r1.y++;
            }
            if (r1.y == getHeight()) return;
            setAgPos(0, r1);
            setAgPos(1, getAgPos(1));
        }

        void moveTowards(int x, int y) throws Exception {
            Location r1 = getAgPos(0);
            if (r1.x < x) r1.x++;
            else if (r1.x > x) r1.x--;
            if (r1.y < y) r1.y++;
            else if (r1.y > y) r1.y--;
            setAgPos(0, r1);
            setAgPos(1, getAgPos(1));
        }

        void pickGarb() {
            if (model.hasObject(GARB, getAgPos(0))) {
                if (random.nextBoolean() || nerr == MErr) {
                    remove(GARB, getAgPos(0));
                    nerr = 0;
                    r1HasGarb = true;
                    garbageCollected++;
                    System.out.println("✓ R1 coletou lixo!");
                } else {
                    nerr++;
                }
            }
        }

        void pickGold() {
            if (model.hasObject(GOLD, getAgPos(0))) {
                remove(GOLD, getAgPos(0));
                r1HasGold = true;
                goldCollected++;
                System.out.println("✓ R1 coletou ouro!");
            }
        }

        void dropGarb() {
            if (r1HasGarb) {
                r1HasGarb = false;
                add(GARB, getAgPos(0));
                System.out.println("✓ R1 largou lixo");
            }
        }

        void dropGold() {
            if (r1HasGold) {
                r1HasGold = false;
                add(GOLD, getAgPos(0));
                System.out.println("✓ R1 armazenou ouro");
            }
        }

        void burnGarb() {
            if (model.hasObject(GARB, getAgPos(1))) {
                remove(GARB, getAgPos(1));
                garbageBurned++;
                System.out.println("✓ R2 queimou lixo!");
            }
        }

        Literal getPriorityPercept() {
            return Literal.parseLiteral("priority(balanced)");
        }

        java.util.List<Literal> getGridMapPercepts() {
            java.util.List<Literal> percepts = new java.util.ArrayList<>();
            
            System.out.println("\n=== ESCANEANDO GRID ===");
            
            for (int x = 0; x < GSize; x++) {
                for (int y = 0; y < GSize; y++) {
                    Location loc = new Location(x, y);
                    
                    if (hasObject(GARB, loc)) {
                        Literal garbPercept = Literal.parseLiteral("garbage_at(" + x + "," + y + ")");
                        percepts.add(garbPercept);
                        System.out.println("  ✓ Lixo em (" + x + "," + y + ")");
                    }
                    
                    if (hasObject(GOLD, loc)) {
                        Literal goldPercept = Literal.parseLiteral("gold_at(" + x + "," + y + ")");
                        percepts.add(goldPercept);
                        System.out.println("  ✓ Ouro em (" + x + "," + y + ")");
                    }
                }
            }
            
            System.out.println("Total: " + percepts.size() + " recursos");
            System.out.println("======================\n");
            return percepts;
        }
    }

    class MarsView extends GridWorldView {
        public MarsView(MarsModel model) {
            super(model, "Mars World - Sistema Inteligente [" + GSize + "x" + GSize + "]", 800);
            defaultFont = new Font("Arial", Font.BOLD, 14);
            setVisible(true);
            repaint();
        }

        @Override
        public void draw(Graphics g, int x, int y, int object) {
            switch (object) {
                case MarsEnv.GARB:
                    drawGarb(g, x, y);
                    break;
                case MarsEnv.GOLD:
                    drawGold(g, x, y);
                    break;
            }
        }

        @Override
        public void drawAgent(Graphics g, int x, int y, Color c, int id) {
            String label = "R" + (id + 1);
            c = Color.blue;
            
            if (id == 0) {
                c = Color.yellow;
                if (((MarsModel)model).r1HasGarb) {
                    label += "-L";
                    c = Color.orange;
                }
                if (((MarsModel)model).r1HasGold) {
                    label += "-Au";
                    c = new Color(255, 215, 0);
                }
            }
            
            super.drawAgent(g, x, y, c, -1);
            g.setColor(id == 0 ? Color.black : Color.white);
            super.drawString(g, x, y, defaultFont, label);
        }

        public void drawGarb(Graphics g, int x, int y) {
            super.drawObstacle(g, x, y);
            g.setColor(Color.white);
            drawString(g, x, y, defaultFont, "L");
        }

        public void drawGold(Graphics g, int x, int y) {
            g.setColor(new Color(255, 215, 0));
            super.drawObstacle(g, x, y);
            g.setColor(Color.black);
            drawString(g, x, y, defaultFont, "Au");
        }

        @Override
        public void paint(Graphics g) {
            super.paint(g);
            g.setColor(Color.black);
            g.setFont(new Font("Arial", Font.BOLD, 14));
            int statsY = getHeight() - 30;
            MarsModel m = (MarsModel)model;
            g.drawString("Lixo Coletado: " + m.garbageCollected, 10, statsY);
            g.drawString("Ouro Coletado: " + m.goldCollected, 200, statsY);
            g.drawString("Lixo Queimado: " + m.garbageBurned, 370, statsY);
        }
    }
}