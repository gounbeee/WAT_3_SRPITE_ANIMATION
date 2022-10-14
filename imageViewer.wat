(module
  (import "env" "log" (func $log (param i32 i32)))

  (memory (;0;) 4)


  ;; ------------------------------------
  ;; < SIGNATURE DEFINITION OF FUNCTION > 
  ;; BELOW type SECTION WILL BE USED IN  sumArrayInt32 FUNCTION DEFINITION
  ;; https://webassembly.github.io/spec/core/syntax/modules.html#functions
  ;; The  of a function declares its signature by reference to a type defined 
  ;; in the module. The parameters of the function are referenced through 0-based 
  ;; local indices in the function’s body; they are mutable.
  (type (;0;) (func))
  (type (;1;) (func (param i32 i32 i32 i32 i32 i32 i32 i32) ) )
 


  (func $getSpriteImg (type 1) (param $pArrPix i32) (param $srcWidth i32) (param $srcHeight i32) (param $tarWidth i32) (param $tarHeight i32) (param $tarIndex i32) (param $tarIndexAll i32) (param $resultArray i32) 
    ;;                                

    ;; -----------------------------------------------------------
    ;; PARAMETERS
    ;; LOCAL VARIABLE 0 -> POINTER OF ARRAY STORING ENTIRE PIXELS               $pArrPix
    ;;                1 -> SOURCE IMAGE'S WIDTH                           384   $srcWidth
    ;;                2 -> SOURCE IMAGE'S HEIGHT                          32    $srcHeight 
    ;;                3 -> TARGET IMAGE'S WIDTH                           32    $tarWidth
    ;;                4 -> TARGET IMAGE'S HEIGHT                          32    $tarHeight
    ;;                5 -> INDEX SPRITE IMAGE                             0     $tarIndex
    ;;                6 -> COUNT OF SPRITE IMAGES                         12    $tarIndexAll
    ;;                7 -> RESULT POINTER TO ARRAY BUFFER                       $resultArray


    ;; -------------------------------
    ;; CALCULATING TARGET PIXEL LENGTH
    (local $stride i32)
    (local $i i32)    
    (local $iFloat f32)
    (local $iRow i32)    
    (local $pixel i32)
    (local $pixLength i32)
    (local $remainder i32)
    (local $tarWidthFlt f32)
    (local $beforeSubtract f32)
    (local $prompt i32)
    (local $innerIndex i32)
    (local $promptedResult i32)
    (local $promptedSource i32)

    ;; --------------
    ;; FOR DEBUG
    (local $test i32)

    (local.set $pixLength (i32.mul (i32.mul (local.get $tarWidth) (local.get $tarHeight)) (i32.const 4)))

    ;; SETTING STRIDE NUMBER 4 (BECAUSE WE HAE 4 CHANNELS FOR 1 PIXEL :: rgba) 
    (local.set $stride (i32.const 4))


    ;; ;; DDDDDDDDDEBUG :D
    ;; ;; FOR DEBUG
    ;; i32.const 3333  
    ;; local.get $pixLength  
    ;; call $log


    ;; 
    (loop $pixelLoop 

        ;; ----------------------------------------------------
        ;; BLOCK 
        ;; CAN CREATE AREA WE CAN JUMP OUT LATER
        ;; < block AND br >
        ;; https://qiita.com/kgtkr/items/2c39bb2cbbbfd0e0e14b

        (block

          ;; -------------------------------------------
          ;; GETTING DATA OF INDEX $i FROM SOURCE ARRAY


          ;; *******************************************************************************************************************************
          ;; WE WILL CALCULATE index WITH BELOW FORMULA
          ;; $tarIndex  *  $tarWidth  *  $stride    +    $innerIndex   +  ($tarIndexAll * $tarWidth  * $stride)　  *　   $iRow            
          ;;     2            32            4             0 ~ 31               12            32          4             0 ~ 31           
          ;; SPRITE NUM     TARGET       CHANNELS        CHANGING         TOTAL COUNT    TARGET      CHANNELS        CHANGING          
          ;; WE WANT      PIXEL WIDTH    PER 1 PX        EVERY LOOP        OF SPRITES     PIXEL WIDTH   PER 1 PX      PER 128 INDICES  

          local.get $tarIndex                                       ;; POINTER OF STARTING POINT
          local.get $tarWidth
          i32.mul
          local.get $stride
          i32.mul

          local.get $innerIndex                                     ;; POINTER SHIFTING TO INDICATE 32 * 4 (pixels x channels)  
                                                                    ;; (MOVING FROM 0 TO 128)
          i32.add


          local.get $tarIndexAll                                    ;; POINTER SHIFTING TO NEXT 'ROW'
          local.get $tarWidth
          i32.mul
          local.get $stride
          i32.mul
          local.get $iRow
          i32.mul

          i32.add

          local.set $prompt 


          ;; DDDDDDDDD
          ;; FOR DEBUG
          ;;local.get $i   
          ;;local.get $prompt  
          ;;call $log



          ;; ----------------------------------------------------
          ;; STORING SINGLE PIXEL DATA TO POINTER
          local.get $resultArray
          local.get $i
          i32.const 2                                     ;; **************  MULTIPLYING BY 4 BECAUSE HERE WE ARE USING Int32Array CONTAINER !   
          i32.shl
          i32.add
          local.set $promptedResult

          local.get $pArrPix
          local.get $prompt
          i32.const 2                                     ;; **************  MULTIPLYING BY 4 BECAUSE HERE WE ARE USING Int32Array CONTAINER !  
          i32.shl                
          i32.add

          i32.load                                 ;; SETTING POINTER BEFORE GETTING PIXEL VALUE
          local.set $promptedSource


          ;; ------------------------------------
          ;; STORING VALUE
          local.get $promptedResult
          local.get $promptedSource
          i32.store 


          ;; -------------------------------------
          ;; INDEX ;; INCREMENT BY 1
          (local.set $i 
            (i32.add (local.get $i) (i32.const 1)) 
          )
          (local.set $innerIndex    
            (i32.add (local.get $innerIndex) (i32.const 1))
          )

          ;; -------------------------------------
          ;; ROW INDEX ;; INCREMENT BY 1
          ;; ONLY IF $i IS EXECUTED 32 TIMES !! (== $tarWidth)

          ;; CALCULATE DIVISION BETWEEN $i AND $tarWidth * 4
          ;; FOR MODULO CALCULATION !!

          ;; IF INDEX NUMBER IS NOT ZERO, (SKIPPING 0 INDEX)
          (if 
            (i32.ne (local.get $i) (i32.const 0))
            (then

              ;; CONVERTING INDEX(INTEGER) TO INDEX(FLOAT)
              local.get $i
              f32.convert_i32_s
              local.set $iFloat

              ;; CONVERTING tarWidth(INTEGER) TO tarWidthFlt(FLOAT)
              ;; WE HAVE 32 px  *  4 ch DATA HERE 
              local.get $tarWidth
              i32.const 4
              i32.mul
              f32.convert_i32_s
              local.set $tarWidthFlt

              ;; ------------------------------------------------------------------------
              ;; DIVIDE AND GETTING REMAINDER
              ;; http://wrean.ca/math155/textbook/master.pdf?
              ;;
              local.get $iFloat                                       ;; 1.0, 2.0, 3.0, 4.0 ... (0 IS SKIPPED !) ~ 4095
              local.get $tarWidthFlt                                  ;; 32.0 * 4
              f32.div                                                 ;; 0.03125, 0.0625, 0.09375 ... 

              ;; THEN WE WANT TO DROP DECIMAL PART IN NUMBER
              i32.trunc_f32_s
              f32.convert_i32_s

              ;; THEN MULTIPLY WITH UNIT NUMBER,
              local.get $tarWidthFlt
              f32.mul
              local.set $beforeSubtract                               ;; STORE IT 

              ;; THEN SUBTRACT FROM INITIAL NUMBER
              local.get $iFloat
              local.get $beforeSubtract
              f32.sub
              i32.trunc_f32_s

              local.set $remainder

            )
          )


          ;; -----------------------------------------------------------
          ;; IF REMAINDER IS ZERO, WHICH MEANS WE NEED TO JUMP NEXT ROW
          f32.const 0
          local.get $remainder
          f32.convert_i32_s
          f32.eq
          
          if
            ;; INCREMENT ROW INDEX BY 1
            local.get $iRow
            i32.const 1
            i32.add
            local.tee $iRow
            local.set $iRow

            ;; RESET INNER INDEX BECAUSE WE WANT THIS LOOPS 0 ~ 31
            (local.tee $innerIndex (i32.const 0))
            local.set $innerIndex
          end


          ;; ------------------
          ;; EXITING LOOP CHECK 
          (br_if 0
            (i32.ge_u (local.get $i) (local.get $pixLength))
          )

          br $pixelLoop

        )
      )
  )


  (export "memory" (memory 0))
  (export "getSpriteImg" (func $getSpriteImg))

)
