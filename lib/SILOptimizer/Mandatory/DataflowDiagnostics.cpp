//===--- DataflowDiagnostics.cpp - Emits diagnostics based on SIL analysis ===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#include "swift/SILOptimizer/PassManager/Passes.h"
#include "swift/SILOptimizer/PassManager/Transforms.h"
#include "swift/AST/ASTContext.h"
#include "swift/AST/DiagnosticEngine.h"
#include "swift/AST/DiagnosticsSIL.h"
#include "swift/AST/Expr.h"
#include "swift/SIL/SILFunction.h"
#include "swift/SIL/SILInstruction.h"
#include "swift/SIL/SILLocation.h"
#include "swift/SIL/SILModule.h"
#include "swift/SIL/SILVisitor.h"
using namespace swift;

template<typename...T, typename...U>
static void diagnose(ASTContext &Context, SourceLoc loc, Diag<T...> diag,
              U &&...args) {
  Context.Diags.diagnose(loc,
                         diag, std::forward<U>(args)...);
}

static void diagnoseMissingReturn(const UnreachableInst *UI,
                                  ASTContext &Context) {
  const SILBasicBlock *BB = UI->getParent();
  const SILFunction *F = BB->getParent();
  SILLocation FLoc = F->getLocation();

  Type ResTy;

  if (auto *FD = FLoc.getAsASTNode<FuncDecl>()) {
    ResTy = FD->getResultInterfaceType();
  } else if (auto *CE = FLoc.getAsASTNode<ClosureExpr>()) {
    ResTy = CE->getResultType();
  } else {
    llvm_unreachable("unhandled case in MissingReturn");
  }

  SILLocation L = UI->getLoc();
  assert(L && ResTy);
  auto diagID = F->isNoReturnFunction() ? diag::missing_never_call
                                        : diag::missing_return;
  diagnose(Context,
           L.getEndSourceLoc(),
           diagID, ResTy,
           FLoc.isASTNode<ClosureExpr>() ? 1 : 0);
}


static void diagnoseUnreachable(const SILInstruction *I,
                                ASTContext &Context) {
  if (auto *UI = dyn_cast<UnreachableInst>(I)) {
    SILLocation L = UI->getLoc();

    // Invalid location means that the instruction has been generated by SIL
    // passes, such as DCE. FIXME: we might want to just introduce a separate
    // instruction kind, instead of keeping this invariant.
    //
    // We also do not want to emit diagnostics for code that was
    // transparently inlined. We should have already emitted these
    // diagnostics when we process the callee function prior to
    // inlining it.
    if (!L || L.is<MandatoryInlinedLocation>())
      return;

    // The most common case of getting an unreachable instruction is a
    // missing return statement. In this case, we know that the instruction
    // location will be the enclosing function.
    if (L.isASTNode<AbstractFunctionDecl>() || L.isASTNode<ClosureExpr>()) {
      diagnoseMissingReturn(UI, Context);
      return;
    }

    // A non-exhaustive switch would also produce an unreachable instruction.
    if (L.isASTNode<SwitchStmt>()) {
      diagnose(Context, L.getEndSourceLoc(), diag::non_exhaustive_switch);
      return;
    }

    if (auto *Guard = L.getAsASTNode<GuardStmt>()) {
      diagnose(Context, Guard->getBody()->getEndLoc(),
               diag::guard_body_must_not_fallthrough);
      return;
    }
  }
}

/// \brief Issue diagnostics whenever we see Builtin.static_report(1, ...).
static void diagnoseStaticReports(const SILInstruction *I,
                                  SILModule &M) {

  // Find out if we are dealing with Builtin.staticReport().
  if (auto *BI = dyn_cast<BuiltinInst>(I)) {
    const BuiltinInfo &B = BI->getBuiltinInfo();
    if (B.ID == BuiltinValueKind::StaticReport) {

      // Report diagnostic if the first argument has been folded to '1'.
      OperandValueArrayRef Args = BI->getArguments();
      IntegerLiteralInst *V = dyn_cast<IntegerLiteralInst>(Args[0]);
      if (!V || V->getValue() != 1)
        return;

      diagnose(M.getASTContext(), I->getLoc().getSourceLoc(),
               diag::static_report_error);
    }
  }
}

namespace {
class EmitDFDiagnostics : public SILFunctionTransform {
  ~EmitDFDiagnostics() override {}

  StringRef getName() override { return "Emit Dataflow Diagnostics"; }

  /// The entry point to the transformation.
  void run() override {
    SILModule &M = getFunction()->getModule();
    for (auto &BB : *getFunction())
      for (auto &I : BB) {
        diagnoseUnreachable(&I, M.getASTContext());
        diagnoseStaticReports(&I, M);
      }
  }
};
} // end anonymous namespace


SILTransform *swift::createEmitDFDiagnostics() {
  return new EmitDFDiagnostics();
}
