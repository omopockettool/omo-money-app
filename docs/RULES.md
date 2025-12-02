Check these docs to get context:
- PROJECT_STRUCTURE.md
- ARCHITECTURE_DIAGRAMS.md 
- CLEAN_ARCHITECTURE_GUIDE.md 

1. Use the USE CASES and protocol which acts as a contract between layers:
  - Domain defines what operations exist (protocol)
  - Data implements how they work (concrete class)
  - Presentation uses the operations (via protocol)

2. Incremental update 
  - ALWAYS use the cache system
  - Update the cache then core data methods in background
