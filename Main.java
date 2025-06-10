public class Main {
  public static void main(String[] args) {
    boolean m = true, n = false;
    m = !m;

    boolean q = m && n;

    boolean p = m || n;

    System.out.println(q);
    System.out.println(p);

  }
}
