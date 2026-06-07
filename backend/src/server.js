const app = require("./app");
const dotenv = require("dotenv");
const { initializeFirebase } = require("./config/firebase");

dotenv.config();

const PORT = process.env.PORT || 5000;

initializeFirebase();

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  console.log(`API base URL: http://localhost:${PORT}`);
});
