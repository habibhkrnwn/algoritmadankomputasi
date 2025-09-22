# Numerical Integration with MATLAB

## 📌 Project Title

Numerical Integration (Left/Right Riemann) with MATLAB

## 📖 Project Description

This project implements **numerical integration methods** (Left and
Right Riemann sums) to approximate the integral of the function:

\[ y(t) = `\sin`{=tex}(2`\pi `{=tex}t) - `\cos`{=tex}(3`\pi `{=tex}t),
`\quad `{=tex}t `\in [0, 5]`{=tex}. \]

The numerical results are compared against the **analytical integral
solution**:

\[ Y\_{`\text{exact}`{=tex}}(t) = -`\frac{\cos(2\pi t)}{2\pi}`{=tex} -
`\frac{\sin(3\pi t)}{3\pi}`{=tex} + `\frac{1}{2\pi}`{=tex}. \]

Additionally, derivative validation is performed by comparing the
**finite difference approximation** of (`\dot{y}`{=tex}(t)) with its
analytical form.

------------------------------------------------------------------------

## 🛠 Methodology

1.  Construct a uniform time grid on (\[0, 5\]) with (N) segments.
2.  Evaluate (y(t)) at each grid point.
3.  Compute cumulative integrals using:
    -   **Left Riemann Sum**
    -   **Right Riemann Sum**
4.  Compare results with the analytical solution
    (Y\_{`\text{exact}`{=tex}}(t)).
5.  Plot error curves and derivative comparison.

------------------------------------------------------------------------

## 📊 Results & Analysis

-   **Left Riemann**: tends to **under-estimate** (negative error).\
-   **Right Riemann**: tends to **over-estimate** (positive error).\
-   Both methods show **oscillatory error patterns** due to the
    sinusoidal nature of (y(t)).\
-   Error magnitude is about (10\^{-3}) for large (N), showing
    reasonable accuracy despite the simplicity of the methods.

------------------------------------------------------------------------

## 📈 Figures

-   *Error Curves*: Show the deviation of Left/Right Riemann vs
    Analytical.\
-   *Derivative Check*: Confirms numerical finite difference derivative
    matches analytical derivative.

------------------------------------------------------------------------

## 📂 File Structure

    .
    ├── Difference/
    │   ├── difference.m              # MATLAB code for numerical integration & derivative check
    │   ├── NumericalIntegration.pdf  # Report (LaTeX compiled to PDF)
    │   └── CV-1.pdf                  # Example CV with project documentation
    └── README.md                     # This documentation

------------------------------------------------------------------------

## 🔧 Requirements

-   MATLAB R2018a+
-   Basic LaTeX (for report compilation, optional)

------------------------------------------------------------------------

## 🚀 How to Run

1.  Open `difference.m` in MATLAB.
2.  Run the script to generate plots:
    -   Integral approximation (Left & Right Riemann).
    -   Error curves vs analytical solution.
    -   Derivative comparison.

------------------------------------------------------------------------

## 📚 Conclusion

Left and Right Riemann methods are simple but effective numerical
integration techniques.\
They provide lower and upper bounds of the true integral, respectively.\
On oscillatory functions like (y(t)), both methods exhibit alternating
bias, but accuracy improves linearly with smaller step size (h).

------------------------------------------------------------------------

## 👨‍💻 Author

-   Habib Hammam Kurniawan\
    Master Student in Electrical Engineering, ITS Surabaya
