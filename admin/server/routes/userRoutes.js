import { Router } from "express";
import { searchUser, updateUserAlertAccess } from "../controllers/userController.js";

const router = Router();

router.get("/search", searchUser);
router.put("/alert-access/:firebaseUid", updateUserAlertAccess);

export default router;
