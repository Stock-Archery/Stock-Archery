import { Router } from "express";
import { login } from "../controllers/adminAuthController.js";
import { listUsers, exportUsers, getMeta, getStats } from "../controllers/adminUserController.js";
import { requireAdminAuth } from "../middleware/adminAuth.js";

const router = Router();

router.post("/login", login);

router.use(requireAdminAuth);
router.get("/users", listUsers);
router.get("/users/export", exportUsers);
router.get("/meta", getMeta);
router.get("/stats", getStats);

export default router;
