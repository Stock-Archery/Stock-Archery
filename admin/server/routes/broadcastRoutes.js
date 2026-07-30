import { Router } from "express";
import { broadcastPush } from "../controllers/broadcastController.js";

const router = Router();

router.post("/", broadcastPush);

export default router;
