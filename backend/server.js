const express = require("express");
const cors = require("cors");
const sql = require("mssql");
require("dotenv").config();

const app = express();
app.use(cors());
app.use(express.json());
app.use("/images", express.static("public/images"));


app.get("/health", (req, res) => res.json({ ok: true }));

const dbConfig = {
  server: process.env.DB_SERVER,
  port: parseInt(process.env.DB_PORT, 10),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  options: { trustServerCertificate: true, encrypt: false },
};



app.get("/items", async (req, res) => {
  try {
    const pool = await sql.connect(dbConfig);

    const result = await pool.request().query(`
      SELECT TOP 50
        i.Id,
        i.Title,
        i.Brand,
        i.Size,
        i.Category,
        i.ItemCondition,
        i.Description,
        p.Url AS PhotoUrl
      FROM dbo.Items i
      LEFT JOIN dbo.ItemPhotos p ON p.ItemId = i.Id AND p.SortOrder = 0
      WHERE i.IsAvailable = 1
      ORDER BY i.CreatedAt DESC;
    `);

    res.json(result.recordset);
  } catch (err) {
    console.error("DB error:", err);
    res.status(500).json({ error: "Database query failed", details: String(err.message || err) });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`API running on http://localhost:${PORT}`));
