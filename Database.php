<?php
/* =====================================================================
   Database.php - Tüm sayfaların ORTAK kullandığı tek bağlantı sınıfı.
   index.php, business_hours.php, rezervasyon.php, get_available_slots.php
   ve create_appointment.php ARTIK BURAYI kullanıyor; her dosyanın
   içinde ayrı ayrı mysqli bağlantı bilgisi YOK.
   ===================================================================== */
class Database {
    // Veritabanı bağlantı bilgilerini kendi sistemine göre düzenle
    private $host     = "localhost";
    private $db_name  = "randevu_sistemi"; // Kendi veritabanı adını buraya yaz
    private $username = "root";            // XAMPP/WAMP kullanıyorsan genelde 'root' olur
    private $password = "";                // XAMPP/WAMP kullanıyorsan genelde şifre boş bırakılır
    public $conn;

    // Veritabanı bağlantısını kuran fonksiyon
    public function connect() {
        $this->conn = null;

        // DİKKAT: Burada artık echo YOK. Bağlantı başarısız olursa
        // PDOException'ı olduğu gibi yukarı fırlatıyoruz (throw).
        // Çünkü bu sınıfı hem normal HTML sayfalar (index.php vb.)
        // hem de SADECE JSON dönmesi gereken AJAX dosyaları
        // (get_available_slots.php, create_appointment.php) kullanıyor.
        // echo ile buradan direkt HTML basarsak, JSON bekleyen fetch()
        // çağrıları "Unexpected token '<'..." hatası alır.
        $dsn = "mysql:host=" . $this->host . ";dbname=" . $this->db_name . ";charset=utf8mb4";

        $this->conn = new PDO($dsn, $this->username, $this->password);

        // Hata modunu Exception (İstisna) fırlatacak şekilde ayarla
        $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

        // Fetch modunu varsayılan olarak Associative Array (İlişkisel Dizi) yap
        $this->conn->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);

        return $this->conn;
    }
}
