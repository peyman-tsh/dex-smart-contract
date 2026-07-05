import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

// Sample deployment module kept from the Hardhat starter until DEX modules replace it.
export default buildModule("CounterModule", (m) => {
  const counter = m.contract("Counter");

  m.call(counter, "incBy", [5n]);

  return { counter };
});
