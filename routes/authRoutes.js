const express = require("express");

// route controller
const AuthController = require("../controller/authController");
const router = express.Router();

// authentication routes
router.get("/login", AuthController.Login)
router.get("/register", AuthController.Register)
router.post("/register",AuthController.PostRegister)
router.post("/login",AuthController.PostLogin)
router.get('/logout',AuthController.logout)

module.exports = router;