import { Router } from "express";
import {
  createAlert,
  getAlertsByCategory,
  deleteAlert,
} from "../controllers/alertController.js";

const router = Router();

router.post("/", createAlert);
router.get("/:category", getAlertsByCategory);
router.delete("/:id", deleteAlert);

export default router;
