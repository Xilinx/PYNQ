/* head begin */
'use strict';

var fs = require('fs'),
    system = require('system'),
    page = require('webpage').create();

var argumist = function () {

var exports = {}, module = { exports: exports };

/* head end */
(function(f){if(typeof exports==="object"&&typeof module!=="undefined"){module.exports=f()}else if(typeof define==="function"&&define.amd){define([],f)}else{var g;if(typeof window!=="undefined"){g=window}else if(typeof global!=="undefined"){g=global}else if(typeof self!=="undefined"){g=self}else{g=this}g.argumist = f()}})(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
module.exports = function (args, opts) {
    if (!opts) opts = {};
    
    var flags = { bools : {}, strings : {}, unknownFn: null };

    if (typeof opts['unknown'] === 'function') {
        flags.unknownFn = opts['unknown'];
    }

    if (typeof opts['boolean'] === 'boolean' && opts['boolean']) {
      flags.allBools = true;
    } else {
      [].concat(opts['boolean']).filter(Boolean).forEach(function (key) {
          flags.bools[key] = true;
      });
    }
    
    var aliases = {};
    Object.keys(opts.alias || {}).forEach(function (key) {
        aliases[key] = [].concat(opts.alias[key]);
        aliases[key].forEach(function (x) {
            aliases[x] = [key].concat(aliases[key].filter(function (y) {
                return x !== y;
            }));
        });
    });

    [].concat(opts.string).filter(Boolean).forEach(function (key) {
        flags.strings[key] = true;
        if (aliases[key]) {
            flags.strings[aliases[key]] = true;
        }
     });

    var defaults = opts['default'] || {};
    
    var argv = { _ : [] };
    Object.keys(flags.bools).forEach(function (key) {
        setArg(key, defaults[key] === undefined ? false : defaults[key]);
    });
    
    var notFlags = [];

    if (args.indexOf('--') !== -1) {
        notFlags = args.slice(args.indexOf('--')+1);
        args = args.slice(0, args.indexOf('--'));
    }

    function argDefined(key, arg) {
        return (flags.allBools && /^--[^=]+$/.test(arg)) ||
            flags.strings[key] || flags.bools[key] || aliases[key];
    }

    function setArg (key, val, arg) {
        if (arg && flags.unknownFn && !argDefined(key, arg)) {
            if (flags.unknownFn(arg) === false) return;
        }

        var value = !flags.strings[key] && isNumber(val)
            ? Number(val) : val
        ;
        setKey(argv, key.split('.'), value);
        
        (aliases[key] || []).forEach(function (x) {
            setKey(argv, x.split('.'), value);
        });
    }

    function setKey (obj, keys, value) {
        var o = obj;
        keys.slice(0,-1).forEach(function (key) {
            if (o[key] === undefined) o[key] = {};
            o = o[key];
        });

        var key = keys[keys.length - 1];
        if (o[key] === undefined || flags.bools[key] || typeof o[key] === 'boolean') {
            o[key] = value;
        }
        else if (Array.isArray(o[key])) {
            o[key].push(value);
        }
        else {
            o[key] = [ o[key], value ];
        }
    }
    
    function aliasIsBoolean(key) {
      return aliases[key].some(function (x) {
          return flags.bools[x];
      });
    }

    for (var i = 0; i < args.length; i++) {
        var arg = args[i];
        
        if (/^--.+=/.test(arg)) {
            // Using [\s\S] instead of . because js doesn't support the
            // 'dotall' regex modifier. See:
            // http://stackoverflow.com/a/1068308/13216
            var m = arg.match(/^--([^=]+)=([\s\S]*)$/);
            var key = m[1];
            var value = m[2];
            if (flags.bools[key]) {
                value = value !== 'false';
            }
            setArg(key, value, arg);
        }
        else if (/^--no-.+/.test(arg)) {
            var key = arg.match(/^--no-(.+)/)[1];
            setArg(key, false, arg);
        }
        else if (/^--.+/.test(arg)) {
            var key = arg.match(/^--(.+)/)[1];
            var next = args[i + 1];
            if (next !== undefined && !/^-/.test(next)
            && !flags.bools[key]
            && !flags.allBools
            && (aliases[key] ? !aliasIsBoolean(key) : true)) {
                setArg(key, next, arg);
                i++;
            }
            else if (/^(true|false)$/.test(next)) {
                setArg(key, next === 'true', arg);
                i++;
            }
            else {
                setArg(key, flags.strings[key] ? '' : true, arg);
            }
        }
        else if (/^-[^-]+/.test(arg)) {
            var letters = arg.slice(1,-1).split('');
            
            var broken = false;
            for (var j = 0; j < letters.length; j++) {
                var next = arg.slice(j+2);
                
                if (next === '-') {
                    setArg(letters[j], next, arg)
                    continue;
                }
                
                if (/[A-Za-z]/.test(letters[j]) && /=/.test(next)) {
                    setArg(letters[j], next.split('=')[1], arg);
                    broken = true;
                    break;
                }
                
                if (/[A-Za-z]/.test(letters[j])
                && /-?\d+(\.\d*)?(e-?\d+)?$/.test(next)) {
                    setArg(letters[j], next, arg);
                    broken = true;
                    break;
                }
                
                if (letters[j+1] && letters[j+1].match(/\W/)) {
                    setArg(letters[j], arg.slice(j+2), arg);
                    broken = true;
                    break;
                }
                else {
                    setArg(letters[j], flags.strings[letters[j]] ? '' : true, arg);
                }
            }
            
            var key = arg.slice(-1)[0];
            if (!broken && key !== '-') {
                if (args[i+1] && !/^(-|--)[^-]/.test(args[i+1])
                && !flags.bools[key]
                && (aliases[key] ? !aliasIsBoolean(key) : true)) {
                    setArg(key, args[i+1], arg);
                    i++;
                }
                else if (args[i+1] && /true|false/.test(args[i+1])) {
                    setArg(key, args[i+1] === 'true', arg);
                    i++;
                }
                else {
                    setArg(key, flags.strings[key] ? '' : true, arg);
                }
            }
        }
        else {
            if (!flags.unknownFn || flags.unknownFn(arg) !== false) {
                argv._.push(
                    flags.strings['_'] || !isNumber(arg) ? arg : Number(arg)
                );
            }
            if (opts.stopEarly) {
                argv._.push.apply(argv._, args.slice(i + 1));
                break;
            }
        }
    }
    
    Object.keys(defaults).forEach(function (key) {
        if (!hasKey(argv, key.split('.'))) {
            setKey(argv, key.split('.'), defaults[key]);
            
            (aliases[key] || []).forEach(function (x) {
                setKey(argv, x.split('.'), defaults[key]);
            });
        }
    });
    
    if (opts['--']) {
        argv['--'] = new Array();
        notFlags.forEach(function(key) {
            argv['--'].push(key);
        });
    }
    else {
        notFlags.forEach(function(key) {
            argv._.push(key);
        });
    }

    return argv;
};

function hasKey (obj, keys) {
    var o = obj;
    keys.slice(0,-1).forEach(function (key) {
        o = (o[key] || {});
    });

    var key = keys[keys.length - 1];
    return key in o;
}

function isNumber (x) {
    if (typeof x === 'number') return true;
    if (/^0x[0-9a-f]+$/i.test(x)) return true;
    return /^[-+]?(?:\d+(?:\.\d*)?|\.\d+)(e[-+]?\d+)?$/.test(x);
}


},{}],2:[function(require,module,exports){
/* argumist begin */

module.exports = require('minimist');

/* argumist end */

},{"minimist":1}]},{},[2])(2)
});/* middle begin */

return module.exports;

}

function pagegen (source) {

var exports = {}, module = { exports: exports };

var WaveSkin = {};
window.WaveSkin = WaveSkin;

/* middle end */
var WaveSkin=WaveSkin||{};WaveSkin.default=["svg",{"id":"svg","xmlns":"http://www.w3.org/2000/svg","xmlns:xlink":"http://www.w3.org/1999/xlink","height":"0"},["style",{"type":"text/css"},"text{font-size:11pt;font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;text-align:center;fill-opacity:1;font-family:Helvetica}.muted{fill:#aaa}.warning{fill:#f6b900}.error{fill:#f60000}.info{fill:#0041c4}.success{fill:#00ab00}.h1{font-size:33pt;font-weight:bold}.h2{font-size:27pt;font-weight:bold}.h3{font-size:20pt;font-weight:bold}.h4{font-size:14pt;font-weight:bold}.h5{font-size:11pt;font-weight:bold}.h6{font-size:8pt;font-weight:bold}.s1{fill:none;stroke:#000;stroke-width:1;stroke-linecap:round;stroke-linejoin:miter;stroke-miterlimit:4;stroke-opacity:1;stroke-dasharray:none}.s2{fill:none;stroke:#000;stroke-width:0.5;stroke-linecap:round;stroke-linejoin:miter;stroke-miterlimit:4;stroke-opacity:1;stroke-dasharray:none}.s3{color:#000;fill:none;stroke:#000;stroke-width:1;stroke-linecap:round;stroke-linejoin:miter;stroke-miterlimit:4;stroke-opacity:1;stroke-dasharray:1, 3;stroke-dashoffset:0;marker:none;visibility:visible;display:inline;overflow:visible;enable-background:accumulate}.s4{color:#000;fill:none;stroke:#000;stroke-width:1;stroke-linecap:round;stroke-linejoin:miter;stroke-miterlimit:4;stroke-opacity:1;stroke-dasharray:none;stroke-dashoffset:0;marker:none;visibility:visible;display:inline;overflow:visible}.s5{fill:#fff;stroke:none}.s6{color:#000;fill:#ffffb4;fill-opacity:1;fill-rule:nonzero;stroke:none;stroke-width:1px;marker:none;visibility:visible;display:inline;overflow:visible;enable-background:accumulate}.s7{color:#000;fill:#ffe0b9;fill-opacity:1;fill-rule:nonzero;stroke:none;stroke-width:1px;marker:none;visibility:visible;display:inline;overflow:visible;enable-background:accumulate}.s8{color:#000;fill:#b9e0ff;fill-opacity:1;fill-rule:nonzero;stroke:none;stroke-width:1px;marker:none;visibility:visible;display:inline;overflow:visible;enable-background:accumulate}.s9{fill:#000;fill-opacity:1;stroke:none}.s10{color:#000;fill:#fff;fill-opacity:1;fill-rule:nonzero;stroke:none;stroke-width:1px;marker:none;visibility:visible;display:inline;overflow:visible;enable-background:accumulate}.s11{fill:#0041c4;fill-opacity:1;stroke:none}.s12{fill:none;stroke:#0041c4;stroke-width:1;stroke-linecap:round;stroke-linejoin:miter;stroke-miterlimit:4;stroke-opacity:1;stroke-dasharray:none}"],["defs",["g",{"id":"socket"},["rect",{"y":"15","x":"6","height":"20","width":"20"}]],["g",{"id":"pclk"},["path",{"d":"M0,20 0,0 20,0","class":"s1"}]],["g",{"id":"nclk"},["path",{"d":"m0,0 0,20 20,0","class":"s1"}]],["g",{"id":"000"},["path",{"d":"m0,20 20,0","class":"s1"}]],["g",{"id":"0m0"},["path",{"d":"m0,20 3,0 3,-10 3,10 11,0","class":"s1"}]],["g",{"id":"0m1"},["path",{"d":"M0,20 3,20 9,0 20,0","class":"s1"}]],["g",{"id":"0mx"},["path",{"d":"M3,20 9,0 20,0","class":"s1"}],["path",{"d":"m20,15 -5,5","class":"s2"}],["path",{"d":"M20,10 10,20","class":"s2"}],["path",{"d":"M20,5 5,20","class":"s2"}],["path",{"d":"M20,0 4,16","class":"s2"}],["path",{"d":"M15,0 6,9","class":"s2"}],["path",{"d":"M10,0 9,1","class":"s2"}],["path",{"d":"m0,20 20,0","class":"s1"}]],["g",{"id":"0md"},["path",{"d":"m8,20 10,0","class":"s3"}],["path",{"d":"m0,20 5,0","class":"s1"}]],["g",{"id":"0mu"},["path",{"d":"m0,20 3,0 C 7,10 10.107603,0 20,0","class":"s1"}]],["g",{"id":"0mz"},["path",{"d":"m0,20 3,0 C 10,10 15,10 20,10","class":"s1"}]],["g",{"id":"111"},["path",{"d":"M0,0 20,0","class":"s1"}]],["g",{"id":"1m0"},["path",{"d":"m0,0 3,0 6,20 11,0","class":"s1"}]],["g",{"id":"1m1"},["path",{"d":"M0,0 3,0 6,10 9,0 20,0","class":"s1"}]],["g",{"id":"1mx"},["path",{"d":"m3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,0 20,0","class":"s1"}],["path",{"d":"m20,15 -5,5","class":"s2"}],["path",{"d":"M20,10 10,20","class":"s2"}],["path",{"d":"M20,5 8,17","class":"s2"}],["path",{"d":"M20,0 7,13","class":"s2"}],["path",{"d":"M15,0 6,9","class":"s2"}],["path",{"d":"M10,0 5,5","class":"s2"}],["path",{"d":"M3.5,1.5 5,0","class":"s2"}]],["g",{"id":"1md"},["path",{"d":"m0,0 3,0 c 4,10 7,20 17,20","class":"s1"}]],["g",{"id":"1mu"},["path",{"d":"M0,0 5,0","class":"s1"}],["path",{"d":"M8,0 18,0","class":"s3"}]],["g",{"id":"1mz"},["path",{"d":"m0,0 3,0 c 7,10 12,10 17,10","class":"s1"}]],["g",{"id":"xxx"},["path",{"d":"m0,20 20,0","class":"s1"}],["path",{"d":"M0,0 20,0","class":"s1"}],["path",{"d":"M0,5 5,0","class":"s2"}],["path",{"d":"M0,10 10,0","class":"s2"}],["path",{"d":"M0,15 15,0","class":"s2"}],["path",{"d":"M0,20 20,0","class":"s2"}],["path",{"d":"M5,20 20,5","class":"s2"}],["path",{"d":"M10,20 20,10","class":"s2"}],["path",{"d":"m15,20 5,-5","class":"s2"}]],["g",{"id":"xm0"},["path",{"d":"M0,0 4,0 9,20","class":"s1"}],["path",{"d":"m0,20 20,0","class":"s1"}],["path",{"d":"M0,5 4,1","class":"s2"}],["path",{"d":"M0,10 5,5","class":"s2"}],["path",{"d":"M0,15 6,9","class":"s2"}],["path",{"d":"M0,20 7,13","class":"s2"}],["path",{"d":"M5,20 8,17","class":"s2"}]],["g",{"id":"xm1"},["path",{"d":"M0,0 20,0","class":"s1"}],["path",{"d":"M0,20 4,20 9,0","class":"s1"}],["path",{"d":"M0,5 5,0","class":"s2"}],["path",{"d":"M0,10 9,1","class":"s2"}],["path",{"d":"M0,15 7,8","class":"s2"}],["path",{"d":"M0,20 5,15","class":"s2"}]],["g",{"id":"xmx"},["path",{"d":"m0,20 20,0","class":"s1"}],["path",{"d":"M0,0 20,0","class":"s1"}],["path",{"d":"M0,5 5,0","class":"s2"}],["path",{"d":"M0,10 10,0","class":"s2"}],["path",{"d":"M0,15 15,0","class":"s2"}],["path",{"d":"M0,20 20,0","class":"s2"}],["path",{"d":"M5,20 20,5","class":"s2"}],["path",{"d":"M10,20 20,10","class":"s2"}],["path",{"d":"m15,20 5,-5","class":"s2"}]],["g",{"id":"xmd"},["path",{"d":"m0,0 4,0 c 3,10 6,20 16,20","class":"s1"}],["path",{"d":"m0,20 20,0","class":"s1"}],["path",{"d":"M0,5 4,1","class":"s2"}],["path",{"d":"M0,10 5.5,4.5","class":"s2"}],["path",{"d":"M0,15 6.5,8.5","class":"s2"}],["path",{"d":"M0,20 8,12","class":"s2"}],["path",{"d":"m5,20 5,-5","class":"s2"}],["path",{"d":"m10,20 2.5,-2.5","class":"s2"}]],["g",{"id":"xmu"},["path",{"d":"M0,0 20,0","class":"s1"}],["path",{"d":"m0,20 4,0 C 7,10 10,0 20,0","class":"s1"}],["path",{"d":"M0,5 5,0","class":"s2"}],["path",{"d":"M0,10 10,0","class":"s2"}],["path",{"d":"M0,15 10,5","class":"s2"}],["path",{"d":"M0,20 6,14","class":"s2"}]],["g",{"id":"xmz"},["path",{"d":"m0,0 4,0 c 6,10 11,10 16,10","class":"s1"}],["path",{"d":"m0,20 4,0 C 10,10 15,10 20,10","class":"s1"}],["path",{"d":"M0,5 4.5,0.5","class":"s2"}],["path",{"d":"M0,10 6.5,3.5","class":"s2"}],["path",{"d":"M0,15 8.5,6.5","class":"s2"}],["path",{"d":"M0,20 11.5,8.5","class":"s2"}]],["g",{"id":"ddd"},["path",{"d":"m0,20 20,0","class":"s3"}]],["g",{"id":"dm0"},["path",{"d":"m0,20 10,0","class":"s3"}],["path",{"d":"m12,20 8,0","class":"s1"}]],["g",{"id":"dm1"},["path",{"d":"M0,20 3,20 9,0 20,0","class":"s1"}]],["g",{"id":"dmx"},["path",{"d":"M3,20 9,0 20,0","class":"s1"}],["path",{"d":"m20,15 -5,5","class":"s2"}],["path",{"d":"M20,10 10,20","class":"s2"}],["path",{"d":"M20,5 5,20","class":"s2"}],["path",{"d":"M20,0 4,16","class":"s2"}],["path",{"d":"M15,0 6,9","class":"s2"}],["path",{"d":"M10,0 9,1","class":"s2"}],["path",{"d":"m0,20 20,0","class":"s1"}]],["g",{"id":"dmd"},["path",{"d":"m0,20 20,0","class":"s3"}]],["g",{"id":"dmu"},["path",{"d":"m0,20 3,0 C 7,10 10.107603,0 20,0","class":"s1"}]],["g",{"id":"dmz"},["path",{"d":"m0,20 3,0 C 10,10 15,10 20,10","class":"s1"}]],["g",{"id":"uuu"},["path",{"d":"M0,0 20,0","class":"s3"}]],["g",{"id":"um0"},["path",{"d":"m0,0 3,0 6,20 11,0","class":"s1"}]],["g",{"id":"um1"},["path",{"d":"M0,0 10,0","class":"s3"}],["path",{"d":"m12,0 8,0","class":"s1"}]],["g",{"id":"umx"},["path",{"d":"m3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,0 20,0","class":"s1"}],["path",{"d":"m20,15 -5,5","class":"s2"}],["path",{"d":"M20,10 10,20","class":"s2"}],["path",{"d":"M20,5 8,17","class":"s2"}],["path",{"d":"M20,0 7,13","class":"s2"}],["path",{"d":"M15,0 6,9","class":"s2"}],["path",{"d":"M10,0 5,5","class":"s2"}],["path",{"d":"M3.5,1.5 5,0","class":"s2"}]],["g",{"id":"umd"},["path",{"d":"m0,0 3,0 c 4,10 7,20 17,20","class":"s1"}]],["g",{"id":"umu"},["path",{"d":"M0,0 20,0","class":"s3"}]],["g",{"id":"umz"},["path",{"d":"m0,0 3,0 c 7,10 12,10 17,10","class":"s4"}]],["g",{"id":"zzz"},["path",{"d":"m0,10 20,0","class":"s1"}]],["g",{"id":"zm0"},["path",{"d":"m0,10 6,0 3,10 11,0","class":"s1"}]],["g",{"id":"zm1"},["path",{"d":"M0,10 6,10 9,0 20,0","class":"s1"}]],["g",{"id":"zmx"},["path",{"d":"m6,10 3,10 11,0","class":"s1"}],["path",{"d":"M0,10 6,10 9,0 20,0","class":"s1"}],["path",{"d":"m20,15 -5,5","class":"s2"}],["path",{"d":"M20,10 10,20","class":"s2"}],["path",{"d":"M20,5 8,17","class":"s2"}],["path",{"d":"M20,0 7,13","class":"s2"}],["path",{"d":"M15,0 6.5,8.5","class":"s2"}],["path",{"d":"M10,0 9,1","class":"s2"}]],["g",{"id":"zmd"},["path",{"d":"m0,10 7,0 c 3,5 8,10 13,10","class":"s1"}]],["g",{"id":"zmu"},["path",{"d":"m0,10 7,0 C 10,5 15,0 20,0","class":"s1"}]],["g",{"id":"zmz"},["path",{"d":"m0,10 20,0","class":"s1"}]],["g",{"id":"gap"},["path",{"d":"m7,-2 -4,0 c -5,0 -5,24 -10,24 l 4,0 C 2,22 2,-2 7,-2 z","class":"s5"}],["path",{"d":"M-7,22 C -2,22 -2,-2 3,-2","class":"s1"}],["path",{"d":"M-3,22 C 2,22 2,-2 7,-2","class":"s1"}]],["g",{"id":"0mv-3"},["path",{"d":"M9,0 20,0 20,20 3,20 z","class":"s6"}],["path",{"d":"M3,20 9,0 20,0","class":"s1"}],["path",{"d":"m0,20 20,0","class":"s1"}]],["g",{"id":"1mv-3"},["path",{"d":"M2.875,0 20,0 20,20 9,20 z","class":"s6"}],["path",{"d":"m3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,0 20,0","class":"s1"}]],["g",{"id":"xmv-3"},["path",{"d":"M9,0 20,0 20,20 9,20 6,10 z","class":"s6"}],["path",{"d":"M0,20 3,20 9,0 20,0","class":"s1"}],["path",{"d":"m0,0 3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,5 3.5,1.5","class":"s2"}],["path",{"d":"M0,10 4.5,5.5","class":"s2"}],["path",{"d":"M0,15 6,9","class":"s2"}],["path",{"d":"M0,20 4,16","class":"s2"}]],["g",{"id":"dmv-3"},["path",{"d":"M9,0 20,0 20,20 3,20 z","class":"s6"}],["path",{"d":"M3,20 9,0 20,0","class":"s1"}],["path",{"d":"m0,20 20,0","class":"s1"}]],["g",{"id":"umv-3"},["path",{"d":"M3,0 20,0 20,20 9,20 z","class":"s6"}],["path",{"d":"m3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,0 20,0","class":"s1"}]],["g",{"id":"zmv-3"},["path",{"d":"M9,0 20,0 20,20 9,20 6,10 z","class":"s6"}],["path",{"d":"m6,10 3,10 11,0","class":"s1"}],["path",{"d":"M0,10 6,10 9,0 20,0","class":"s1"}]],["g",{"id":"vvv-3"},["path",{"d":"M20,20 0,20 0,0 20,0","class":"s6"}],["path",{"d":"m0,20 20,0","class":"s1"}],["path",{"d":"M0,0 20,0","class":"s1"}]],["g",{"id":"vm0-3"},["path",{"d":"M0,20 0,0 3,0 9,20","class":"s6"}],["path",{"d":"M0,0 3,0 9,20","class":"s1"}],["path",{"d":"m0,20 20,0","class":"s1"}]],["g",{"id":"vm1-3"},["path",{"d":"M0,0 0,20 3,20 9,0","class":"s6"}],["path",{"d":"M0,0 20,0","class":"s1"}],["path",{"d":"M0,20 3,20 9,0","class":"s1"}]],["g",{"id":"vmx-3"},["path",{"d":"M0,0 0,20 3,20 6,10 3,0","class":"s6"}],["path",{"d":"m0,0 3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,20 3,20 9,0 20,0","class":"s1"}],["path",{"d":"m20,15 -5,5","class":"s2"}],["path",{"d":"M20,10 10,20","class":"s2"}],["path",{"d":"M20,5 8,17","class":"s2"}],["path",{"d":"M20,0 7,13","class":"s2"}],["path",{"d":"M15,0 7,8","class":"s2"}],["path",{"d":"M10,0 9,1","class":"s2"}]],["g",{"id":"vmd-3"},["path",{"d":"m0,0 0,20 20,0 C 10,20 7,10 3,0","class":"s6"}],["path",{"d":"m0,0 3,0 c 4,10 7,20 17,20","class":"s1"}],["path",{"d":"m0,20 20,0","class":"s1"}]],["g",{"id":"vmu-3"},["path",{"d":"m0,0 0,20 3,0 C 7,10 10,0 20,0","class":"s6"}],["path",{"d":"m0,20 3,0 C 7,10 10,0 20,0","class":"s1"}],["path",{"d":"M0,0 20,0","class":"s1"}]],["g",{"id":"vmz-3"},["path",{"d":"M0,0 3,0 C 10,10 15,10 20,10 15,10 10,10 3,20 L 0,20","class":"s6"}],["path",{"d":"m0,0 3,0 c 7,10 12,10 17,10","class":"s1"}],["path",{"d":"m0,20 3,0 C 10,10 15,10 20,10","class":"s1"}]],["g",{"id":"vmv-3-3"},["path",{"d":"M9,0 20,0 20,20 9,20 6,10 z","class":"s6"}],["path",{"d":"M3,0 0,0 0,20 3,20 6,10 z","class":"s6"}],["path",{"d":"m0,0 3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,20 3,20 9,0 20,0","class":"s1"}]],["g",{"id":"vmv-3-4"},["path",{"d":"M9,0 20,0 20,20 9,20 6,10 z","class":"s7"}],["path",{"d":"M3,0 0,0 0,20 3,20 6,10 z","class":"s6"}],["path",{"d":"m0,0 3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,20 3,20 9,0 20,0","class":"s1"}]],["g",{"id":"vmv-3-5"},["path",{"d":"M9,0 20,0 20,20 9,20 6,10 z","class":"s8"}],["path",{"d":"M3,0 0,0 0,20 3,20 6,10 z","class":"s6"}],["path",{"d":"m0,0 3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,20 3,20 9,0 20,0","class":"s1"}]],["g",{"id":"vmv-4-3"},["path",{"d":"M9,0 20,0 20,20 9,20 6,10 z","class":"s6"}],["path",{"d":"M3,0 0,0 0,20 3,20 6,10 z","class":"s7"}],["path",{"d":"m0,0 3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,20 3,20 9,0 20,0","class":"s1"}]],["g",{"id":"vmv-4-4"},["path",{"d":"M9,0 20,0 20,20 9,20 6,10 z","class":"s7"}],["path",{"d":"M3,0 0,0 0,20 3,20 6,10 z","class":"s7"}],["path",{"d":"m0,0 3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,20 3,20 9,0 20,0","class":"s1"}]],["g",{"id":"vmv-4-5"},["path",{"d":"M9,0 20,0 20,20 9,20 6,10 z","class":"s8"}],["path",{"d":"M3,0 0,0 0,20 3,20 6,10 z","class":"s7"}],["path",{"d":"m0,0 3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,20 3,20 9,0 20,0","class":"s1"}]],["g",{"id":"vmv-5-3"},["path",{"d":"M9,0 20,0 20,20 9,20 6,10 z","class":"s6"}],["path",{"d":"M3,0 0,0 0,20 3,20 6,10 z","class":"s8"}],["path",{"d":"m0,0 3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,20 3,20 9,0 20,0","class":"s1"}]],["g",{"id":"vmv-5-4"},["path",{"d":"M9,0 20,0 20,20 9,20 6,10 z","class":"s7"}],["path",{"d":"M3,0 0,0 0,20 3,20 6,10 z","class":"s8"}],["path",{"d":"m0,0 3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,20 3,20 9,0 20,0","class":"s1"}]],["g",{"id":"vmv-5-5"},["path",{"d":"M9,0 20,0 20,20 9,20 6,10 z","class":"s8"}],["path",{"d":"M3,0 0,0 0,20 3,20 6,10 z","class":"s8"}],["path",{"d":"m0,0 3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,20 3,20 9,0 20,0","class":"s1"}]],["g",{"id":"0mv-4"},["path",{"d":"M9,0 20,0 20,20 3,20 z","class":"s7"}],["path",{"d":"M3,20 9,0 20,0","class":"s1"}],["path",{"d":"m0,20 20,0","class":"s1"}]],["g",{"id":"1mv-4"},["path",{"d":"M2.875,0 20,0 20,20 9,20 z","class":"s7"}],["path",{"d":"m3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,0 20,0","class":"s1"}]],["g",{"id":"xmv-4"},["path",{"d":"M9,0 20,0 20,20 9,20 6,10 z","class":"s7"}],["path",{"d":"M0,20 3,20 9,0 20,0","class":"s1"}],["path",{"d":"m0,0 3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,5 3.5,1.5","class":"s2"}],["path",{"d":"M0,10 4.5,5.5","class":"s2"}],["path",{"d":"M0,15 6,9","class":"s2"}],["path",{"d":"M0,20 4,16","class":"s2"}]],["g",{"id":"dmv-4"},["path",{"d":"M9,0 20,0 20,20 3,20 z","class":"s7"}],["path",{"d":"M3,20 9,0 20,0","class":"s1"}],["path",{"d":"m0,20 20,0","class":"s1"}]],["g",{"id":"umv-4"},["path",{"d":"M3,0 20,0 20,20 9,20 z","class":"s7"}],["path",{"d":"m3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,0 20,0","class":"s1"}]],["g",{"id":"zmv-4"},["path",{"d":"M9,0 20,0 20,20 9,20 6,10 z","class":"s7"}],["path",{"d":"m6,10 3,10 11,0","class":"s1"}],["path",{"d":"M0,10 6,10 9,0 20,0","class":"s1"}]],["g",{"id":"0mv-5"},["path",{"d":"M9,0 20,0 20,20 3,20 z","class":"s8"}],["path",{"d":"M3,20 9,0 20,0","class":"s1"}],["path",{"d":"m0,20 20,0","class":"s1"}]],["g",{"id":"1mv-5"},["path",{"d":"M2.875,0 20,0 20,20 9,20 z","class":"s8"}],["path",{"d":"m3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,0 20,0","class":"s1"}]],["g",{"id":"xmv-5"},["path",{"d":"M9,0 20,0 20,20 9,20 6,10 z","class":"s8"}],["path",{"d":"M0,20 3,20 9,0 20,0","class":"s1"}],["path",{"d":"m0,0 3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,5 3.5,1.5","class":"s2"}],["path",{"d":"M0,10 4.5,5.5","class":"s2"}],["path",{"d":"M0,15 6,9","class":"s2"}],["path",{"d":"M0,20 4,16","class":"s2"}]],["g",{"id":"dmv-5"},["path",{"d":"M9,0 20,0 20,20 3,20 z","class":"s8"}],["path",{"d":"M3,20 9,0 20,0","class":"s1"}],["path",{"d":"m0,20 20,0","class":"s1"}]],["g",{"id":"umv-5"},["path",{"d":"M3,0 20,0 20,20 9,20 z","class":"s8"}],["path",{"d":"m3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,0 20,0","class":"s1"}]],["g",{"id":"zmv-5"},["path",{"d":"M9,0 20,0 20,20 9,20 6,10 z","class":"s8"}],["path",{"d":"m6,10 3,10 11,0","class":"s1"}],["path",{"d":"M0,10 6,10 9,0 20,0","class":"s1"}]],["g",{"id":"vvv-4"},["path",{"d":"M20,20 0,20 0,0 20,0","class":"s7"}],["path",{"d":"m0,20 20,0","class":"s1"}],["path",{"d":"M0,0 20,0","class":"s1"}]],["g",{"id":"vm0-4"},["path",{"d":"M0,20 0,0 3,0 9,20","class":"s7"}],["path",{"d":"M0,0 3,0 9,20","class":"s1"}],["path",{"d":"m0,20 20,0","class":"s1"}]],["g",{"id":"vm1-4"},["path",{"d":"M0,0 0,20 3,20 9,0","class":"s7"}],["path",{"d":"M0,0 20,0","class":"s1"}],["path",{"d":"M0,20 3,20 9,0","class":"s1"}]],["g",{"id":"vmx-4"},["path",{"d":"M0,0 0,20 3,20 6,10 3,0","class":"s7"}],["path",{"d":"m0,0 3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,20 3,20 9,0 20,0","class":"s1"}],["path",{"d":"m20,15 -5,5","class":"s2"}],["path",{"d":"M20,10 10,20","class":"s2"}],["path",{"d":"M20,5 8,17","class":"s2"}],["path",{"d":"M20,0 7,13","class":"s2"}],["path",{"d":"M15,0 7,8","class":"s2"}],["path",{"d":"M10,0 9,1","class":"s2"}]],["g",{"id":"vmd-4"},["path",{"d":"m0,0 0,20 20,0 C 10,20 7,10 3,0","class":"s7"}],["path",{"d":"m0,0 3,0 c 4,10 7,20 17,20","class":"s1"}],["path",{"d":"m0,20 20,0","class":"s1"}]],["g",{"id":"vmu-4"},["path",{"d":"m0,0 0,20 3,0 C 7,10 10,0 20,0","class":"s7"}],["path",{"d":"m0,20 3,0 C 7,10 10,0 20,0","class":"s1"}],["path",{"d":"M0,0 20,0","class":"s1"}]],["g",{"id":"vmz-4"},["path",{"d":"M0,0 3,0 C 10,10 15,10 20,10 15,10 10,10 3,20 L 0,20","class":"s7"}],["path",{"d":"m0,0 3,0 c 7,10 12,10 17,10","class":"s1"}],["path",{"d":"m0,20 3,0 C 10,10 15,10 20,10","class":"s1"}]],["g",{"id":"vvv-5"},["path",{"d":"M20,20 0,20 0,0 20,0","class":"s8"}],["path",{"d":"m0,20 20,0","class":"s1"}],["path",{"d":"M0,0 20,0","class":"s1"}]],["g",{"id":"vm0-5"},["path",{"d":"M0,20 0,0 3,0 9,20","class":"s8"}],["path",{"d":"M0,0 3,0 9,20","class":"s1"}],["path",{"d":"m0,20 20,0","class":"s1"}]],["g",{"id":"vm1-5"},["path",{"d":"M0,0 0,20 3,20 9,0","class":"s8"}],["path",{"d":"M0,0 20,0","class":"s1"}],["path",{"d":"M0,20 3,20 9,0","class":"s1"}]],["g",{"id":"vmx-5"},["path",{"d":"M0,0 0,20 3,20 6,10 3,0","class":"s8"}],["path",{"d":"m0,0 3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,20 3,20 9,0 20,0","class":"s1"}],["path",{"d":"m20,15 -5,5","class":"s2"}],["path",{"d":"M20,10 10,20","class":"s2"}],["path",{"d":"M20,5 8,17","class":"s2"}],["path",{"d":"M20,0 7,13","class":"s2"}],["path",{"d":"M15,0 7,8","class":"s2"}],["path",{"d":"M10,0 9,1","class":"s2"}]],["g",{"id":"vmd-5"},["path",{"d":"m0,0 0,20 20,0 C 10,20 7,10 3,0","class":"s8"}],["path",{"d":"m0,0 3,0 c 4,10 7,20 17,20","class":"s1"}],["path",{"d":"m0,20 20,0","class":"s1"}]],["g",{"id":"vmu-5"},["path",{"d":"m0,0 0,20 3,0 C 7,10 10,0 20,0","class":"s8"}],["path",{"d":"m0,20 3,0 C 7,10 10,0 20,0","class":"s1"}],["path",{"d":"M0,0 20,0","class":"s1"}]],["g",{"id":"vmz-5"},["path",{"d":"M0,0 3,0 C 10,10 15,10 20,10 15,10 10,10 3,20 L 0,20","class":"s8"}],["path",{"d":"m0,0 3,0 c 7,10 12,10 17,10","class":"s1"}],["path",{"d":"m0,20 3,0 C 10,10 15,10 20,10","class":"s1"}]],["g",{"id":"Pclk"},["path",{"d":"M-3,12 0,3 3,12 C 1,11 -1,11 -3,12 z","class":"s9"}],["path",{"d":"M0,20 0,0 20,0","class":"s1"}]],["g",{"id":"Nclk"},["path",{"d":"M-3,8 0,17 3,8 C 1,9 -1,9 -3,8 z","class":"s9"}],["path",{"d":"m0,0 0,20 20,0","class":"s1"}]],["g",{"id":"vvv-2"},["path",{"d":"M20,20 0,20 0,0 20,0","class":"s10"}],["path",{"d":"m0,20 20,0","class":"s1"}],["path",{"d":"M0,0 20,0","class":"s1"}]],["g",{"id":"vm0-2"},["path",{"d":"M0,20 0,0 3,0 9,20","class":"s10"}],["path",{"d":"M0,0 3,0 9,20","class":"s1"}],["path",{"d":"m0,20 20,0","class":"s1"}]],["g",{"id":"vm1-2"},["path",{"d":"M0,0 0,20 3,20 9,0","class":"s10"}],["path",{"d":"M0,0 20,0","class":"s1"}],["path",{"d":"M0,20 3,20 9,0","class":"s1"}]],["g",{"id":"vmx-2"},["path",{"d":"M0,0 0,20 3,20 6,10 3,0","class":"s10"}],["path",{"d":"m0,0 3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,20 3,20 9,0 20,0","class":"s1"}],["path",{"d":"m20,15 -5,5","class":"s2"}],["path",{"d":"M20,10 10,20","class":"s2"}],["path",{"d":"M20,5 8,17","class":"s2"}],["path",{"d":"M20,0 7,13","class":"s2"}],["path",{"d":"M15,0 7,8","class":"s2"}],["path",{"d":"M10,0 9,1","class":"s2"}]],["g",{"id":"vmd-2"},["path",{"d":"m0,0 0,20 20,0 C 10,20 7,10 3,0","class":"s10"}],["path",{"d":"m0,0 3,0 c 4,10 7,20 17,20","class":"s1"}],["path",{"d":"m0,20 20,0","class":"s1"}]],["g",{"id":"vmu-2"},["path",{"d":"m0,0 0,20 3,0 C 7,10 10,0 20,0","class":"s10"}],["path",{"d":"m0,20 3,0 C 7,10 10,0 20,0","class":"s1"}],["path",{"d":"M0,0 20,0","class":"s1"}]],["g",{"id":"vmz-2"},["path",{"d":"M0,0 3,0 C 10,10 15,10 20,10 15,10 10,10 3,20 L 0,20","class":"s10"}],["path",{"d":"m0,0 3,0 c 7,10 12,10 17,10","class":"s1"}],["path",{"d":"m0,20 3,0 C 10,10 15,10 20,10","class":"s1"}]],["g",{"id":"0mv-2"},["path",{"d":"M9,0 20,0 20,20 3,20 z","class":"s10"}],["path",{"d":"M3,20 9,0 20,0","class":"s1"}],["path",{"d":"m0,20 20,0","class":"s1"}]],["g",{"id":"1mv-2"},["path",{"d":"M2.875,0 20,0 20,20 9,20 z","class":"s10"}],["path",{"d":"m3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,0 20,0","class":"s1"}]],["g",{"id":"xmv-2"},["path",{"d":"M9,0 20,0 20,20 9,20 6,10 z","class":"s10"}],["path",{"d":"M0,20 3,20 9,0 20,0","class":"s1"}],["path",{"d":"m0,0 3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,5 3.5,1.5","class":"s2"}],["path",{"d":"M0,10 4.5,5.5","class":"s2"}],["path",{"d":"M0,15 6,9","class":"s2"}],["path",{"d":"M0,20 4,16","class":"s2"}]],["g",{"id":"dmv-2"},["path",{"d":"M9,0 20,0 20,20 3,20 z","class":"s10"}],["path",{"d":"M3,20 9,0 20,0","class":"s1"}],["path",{"d":"m0,20 20,0","class":"s1"}]],["g",{"id":"umv-2"},["path",{"d":"M3,0 20,0 20,20 9,20 z","class":"s10"}],["path",{"d":"m3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,0 20,0","class":"s1"}]],["g",{"id":"zmv-2"},["path",{"d":"M9,0 20,0 20,20 9,20 6,10 z","class":"s10"}],["path",{"d":"m6,10 3,10 11,0","class":"s1"}],["path",{"d":"M0,10 6,10 9,0 20,0","class":"s1"}]],["g",{"id":"vmv-3-2"},["path",{"d":"M9,0 20,0 20,20 9,20 6,10 z","class":"s10"}],["path",{"d":"M3,0 0,0 0,20 3,20 6,10 z","class":"s6"}],["path",{"d":"m0,0 3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,20 3,20 9,0 20,0","class":"s1"}]],["g",{"id":"vmv-4-2"},["path",{"d":"M9,0 20,0 20,20 9,20 6,10 z","class":"s10"}],["path",{"d":"M3,0 0,0 0,20 3,20 6,10 z","class":"s7"}],["path",{"d":"m0,0 3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,20 3,20 9,0 20,0","class":"s1"}]],["g",{"id":"vmv-5-2"},["path",{"d":"M9,0 20,0 20,20 9,20 6,10 z","class":"s10"}],["path",{"d":"M3,0 0,0 0,20 3,20 6,10 z","class":"s8"}],["path",{"d":"m0,0 3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,20 3,20 9,0 20,0","class":"s1"}]],["g",{"id":"vmv-2-3"},["path",{"d":"M9,0 20,0 20,20 9,20 6,10 z","class":"s6"}],["path",{"d":"M3,0 0,0 0,20 3,20 6,10 z","class":"s10"}],["path",{"d":"m0,0 3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,20 3,20 9,0 20,0","class":"s1"}]],["g",{"id":"vmv-2-4"},["path",{"d":"M9,0 20,0 20,20 9,20 6,10 z","class":"s7"}],["path",{"d":"M3,0 0,0 0,20 3,20 6,10 z","class":"s10"}],["path",{"d":"m0,0 3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,20 3,20 9,0 20,0","class":"s1"}]],["g",{"id":"vmv-2-5"},["path",{"d":"M9,0 20,0 20,20 9,20 6,10 z","class":"s8"}],["path",{"d":"M3,0 0,0 0,20 3,20 6,10 z","class":"s10"}],["path",{"d":"m0,0 3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,20 3,20 9,0 20,0","class":"s1"}]],["g",{"id":"vmv-2-2"},["path",{"d":"M9,0 20,0 20,20 9,20 6,10 z","class":"s10"}],["path",{"d":"M3,0 0,0 0,20 3,20 6,10 z","class":"s10"}],["path",{"d":"m0,0 3,0 6,20 11,0","class":"s1"}],["path",{"d":"M0,20 3,20 9,0 20,0","class":"s1"}]],["g",{"id":"arrow0"},["path",{"d":"m-12,-3 9,3 -9,3 c 1,-2 1,-4 0,-6 z","class":"s11"}],["path",{"d":"M0,0 -15,0","class":"s12"}]],["marker",{"id":"arrowhead","style":"fill:#0041c4","markerHeight":"7","markerWidth":"10","markerUnits":"strokeWidth","viewBox":"0 -4 11 8","refX":"15","refY":"0","orient":"auto"},["path",{"d":"M0 -4 11 0 0 4z"}]],["marker",{"id":"arrowtail","style":"fill:#0041c4","markerHeight":"7","markerWidth":"10","markerUnits":"strokeWidth","viewBox":"-11 -4 11 8","refX":"-15","refY":"0","orient":"auto"},["path",{"d":"M0 -4 -11 0 0 4z"}]]],["g",{"id":"waves"},["g",{"id":"lanes"}],["g",{"id":"groups"}]]];
var WaveSkin=WaveSkin||{};WaveSkin.narrow=["svg",{"id":"svg","xmlns":"http://www.w3.org/2000/svg","xmlns:xlink":"http://www.w3.org/1999/xlink","height":"0"},["style",{"type":"text/css"},"text{font-size:11pt;font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;text-align:center;fill-opacity:1;font-family:Helvetica}.muted{fill:#aaa}.warning{fill:#f6b900}.error{fill:#f60000}.info{fill:#0041c4}.success{fill:#00ab00}.h1{font-size:33pt;font-weight:bold}.h2{font-size:27pt;font-weight:bold}.h3{font-size:20pt;font-weight:bold}.h4{font-size:14pt;font-weight:bold}.h5{font-size:11pt;font-weight:bold}.h6{font-size:8pt;font-weight:bold}.s1{fill:none;stroke:#000000;stroke-width:1;stroke-linecap:round;stroke-linejoin:miter;stroke-miterlimit:4;stroke-opacity:1;stroke-dasharray:none}.s2{fill:none;stroke:#000000;stroke-width:0.5;stroke-linecap:round;stroke-linejoin:miter;stroke-miterlimit:4;stroke-opacity:1;stroke-dasharray:none}.s3{color:#000000;fill:none;stroke:#000000;stroke-width:1;stroke-linecap:round;stroke-linejoin:miter;stroke-miterlimit:4;stroke-opacity:1;stroke-dasharray:1, 3;stroke-dashoffset:0;marker:none;visibility:visible;display:inline;overflow:visible;enable-background:accumulate}.s4{color:#000000;fill:none;stroke:#000000;stroke-width:1;stroke-linecap:round;stroke-linejoin:miter;stroke-miterlimit:4;stroke-opacity:1;stroke-dasharray:none;stroke-dashoffset:0;marker:none;visibility:visible;display:inline;overflow:visible}.s5{fill:#ffffff;stroke:none}.s6{color:#000000;fill:#ffffb4;fill-opacity:1;fill-rule:nonzero;stroke:none;stroke-width:1px;marker:none;visibility:visible;display:inline;overflow:visible;enable-background:accumulate}.s7{color:#000000;fill:#ffe0b9;fill-opacity:1;fill-rule:nonzero;stroke:none;stroke-width:1px;marker:none;visibility:visible;display:inline;overflow:visible;enable-background:accumulate}.s8{color:#000000;fill:#b9e0ff;fill-opacity:1;fill-rule:nonzero;stroke:none;stroke-width:1px;marker:none;visibility:visible;display:inline;overflow:visible;enable-background:accumulate}.s9{fill:#000000;fill-opacity:1;stroke:none}.s10{color:#000000;fill:#ffffff;fill-opacity:1;fill-rule:nonzero;stroke:none;stroke-width:1px;marker:none;visibility:visible;display:inline;overflow:visible;enable-background:accumulate}"],["defs",["g",{"id":"socket"},["rect",{"y":"15","x":"4","height":"20","width":"10"}]],["g",{"id":"pclk"},["path",{"d":"M 0,20 0,0 10,0","class":"s1"}]],["g",{"id":"nclk"},["path",{"d":"m 0,0 0,20 10,0","class":"s1"}]],["g",{"id":"000"},["path",{"d":"m 0,20 10,0","class":"s1"}]],["g",{"id":"0m0"},["path",{"d":"m 0,20 1,0 3,-10 3,10 3,0","class":"s1"}]],["g",{"id":"0m1"},["path",{"d":"M 0,20 1,20 7,0 10,0","class":"s1"}]],["g",{"id":"0mx"},["path",{"d":"M 1,20 7,0 10,0","class":"s1"}],["path",{"d":"M 10,15 5,20","class":"s2"}],["path",{"d":"M 10,10 2,18","class":"s2"}],["path",{"d":"M 10,5 4,11","class":"s2"}],["path",{"d":"M 10,0 6,4","class":"s2"}],["path",{"d":"m 0,20 10,0","class":"s1"}]],["g",{"id":"0md"},["path",{"d":"m 1,20 9,0","class":"s3"}],["path",{"d":"m 0,20 1,0","class":"s1"}]],["g",{"id":"0mu"},["path",{"d":"m 0,20 1,0 C 2,13 5,0 10,0","class":"s1"}]],["g",{"id":"0mz"},["path",{"d":"m 0,20 1,0 C 3,14 7,10 10,10","class":"s1"}]],["g",{"id":"111"},["path",{"d":"M 0,0 10,0","class":"s1"}]],["g",{"id":"1m0"},["path",{"d":"m 0,0 1,0 6,20 3,0","class":"s1"}]],["g",{"id":"1m1"},["path",{"d":"M 0,0 1,0 4,10 7,0 10,0","class":"s1"}]],["g",{"id":"1mx"},["path",{"d":"m 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,0 10,0","class":"s1"}],["path",{"d":"M 10,15 6.5,18.5","class":"s2"}],["path",{"d":"M 10,10 5.5,14.5","class":"s2"}],["path",{"d":"M 10,5 4.5,10.5","class":"s2"}],["path",{"d":"M 10,0 3,7","class":"s2"}],["path",{"d":"M 2,3 5,0","class":"s2"}]],["g",{"id":"1md"},["path",{"d":"m 0,0 1,0 c 1,7 4,20 9,20","class":"s1"}]],["g",{"id":"1mu"},["path",{"d":"M 0,0 1,0","class":"s1"}],["path",{"d":"m 1,0 9,0","class":"s3"}]],["g",{"id":"1mz"},["path",{"d":"m 0,0 1,0 c 2,4 6,10 9,10","class":"s1"}]],["g",{"id":"xxx"},["path",{"d":"m 0,20 10,0","class":"s1"}],["path",{"d":"M 0,0 10,0","class":"s1"}],["path",{"d":"M 0,5 5,0","class":"s2"}],["path",{"d":"M 0,10 10,0","class":"s2"}],["path",{"d":"M 0,15 10,5","class":"s2"}],["path",{"d":"M 0,20 10,10","class":"s2"}],["path",{"d":"m 5,20 5,-5","class":"s2"}]],["g",{"id":"xm0"},["path",{"d":"M 0,0 1,0 7,20","class":"s1"}],["path",{"d":"m 0,20 10,0","class":"s1"}],["path",{"d":"M 0,5 2,3","class":"s2"}],["path",{"d":"M 0,10 3,7","class":"s2"}],["path",{"d":"M 0,15 4,11","class":"s2"}],["path",{"d":"M 0,20 5,15","class":"s2"}],["path",{"d":"M 5,20 6,19","class":"s2"}]],["g",{"id":"xm1"},["path",{"d":"M 0,0 10,0","class":"s1"}],["path",{"d":"M 0,20 1,20 7,0","class":"s1"}],["path",{"d":"M 0,5 5,0","class":"s2"}],["path",{"d":"M 0,10 6,4","class":"s2"}],["path",{"d":"M 0,15 3,12","class":"s2"}],["path",{"d":"M 0,20 1,19","class":"s2"}]],["g",{"id":"xmx"},["path",{"d":"m 0,20 10,0","class":"s1"}],["path",{"d":"M 0,0 10,0","class":"s1"}],["path",{"d":"M 0,5 5,0","class":"s2"}],["path",{"d":"M 0,10 10,0","class":"s2"}],["path",{"d":"M 0,15 10,5","class":"s2"}],["path",{"d":"M 0,20 10,10","class":"s2"}],["path",{"d":"m 5,20 5,-5","class":"s2"}]],["g",{"id":"xmd"},["path",{"d":"m 0,0 1,0 c 1,7 4,20 9,20","class":"s1"}],["path",{"d":"m 0,20 10,0","class":"s1"}],["path",{"d":"M 0,5 1.5,3.5","class":"s2"}],["path",{"d":"M 0,10 2.5,7.5","class":"s2"}],["path",{"d":"M 0,15 3.5,11.5","class":"s2"}],["path",{"d":"M 0,20 5,15","class":"s2"}],["path",{"d":"M 5,20 7,18","class":"s2"}]],["g",{"id":"xmu"},["path",{"d":"M 0,0 10,0","class":"s1"}],["path",{"d":"m 0,20 1,0 C 2,13 5,0 10,0","class":"s1"}],["path",{"d":"M 0,5 5,0","class":"s2"}],["path",{"d":"M 0,10 5,5","class":"s2"}],["path",{"d":"M 0,15 2,13","class":"s2"}],["path",{"d":"M 0,20 1,19","class":"s2"}]],["g",{"id":"xmz"},["path",{"d":"m 0,0 1,0 c 2,6 6,10 9,10","class":"s1"}],["path",{"d":"m 0,20 1,0 C 3,14 7,10 10,10","class":"s1"}],["path",{"d":"M 0,5 2,3","class":"s2"}],["path",{"d":"M 0,10 4,6","class":"s2"}],["path",{"d":"m 0,15.5 6,-7","class":"s2"}],["path",{"d":"M 0,20 1,19","class":"s2"}]],["g",{"id":"ddd"},["path",{"d":"m 0,20 10,0","class":"s3"}]],["g",{"id":"dm0"},["path",{"d":"m 0,20 7,0","class":"s3"}],["path",{"d":"m 7,20 3,0","class":"s1"}]],["g",{"id":"dm1"},["path",{"d":"M 0,20 1,20 7,0 10,0","class":"s1"}]],["g",{"id":"dmx"},["path",{"d":"M 1,20 7,0 10,0","class":"s1"}],["path",{"d":"M 10,15 5,20","class":"s2"}],["path",{"d":"M 10,10 1.5,18.5","class":"s2"}],["path",{"d":"M 10,5 4,11","class":"s2"}],["path",{"d":"M 10,0 6,4","class":"s2"}],["path",{"d":"m 0,20 10,0","class":"s1"}]],["g",{"id":"dmd"},["path",{"d":"m 0,20 10,0","class":"s3"}]],["g",{"id":"dmu"},["path",{"d":"m 0,20 1,0 C 2,13 5,0 10,0","class":"s1"}]],["g",{"id":"dmz"},["path",{"d":"m 0,20 1,0 C 3,14 7,10 10,10","class":"s1"}]],["g",{"id":"uuu"},["path",{"d":"M 0,0 10,0","class":"s3"}]],["g",{"id":"um0"},["path",{"d":"m 0,0 1,0 6,20 3,0","class":"s1"}]],["g",{"id":"um1"},["path",{"d":"M 0,0 7,0","class":"s3"}],["path",{"d":"m 7,0 3,0","class":"s1"}]],["g",{"id":"umx"},["path",{"d":"M 1.4771574,0 7,20 l 3,0","class":"s1"}],["path",{"d":"M 0,0 10,0","class":"s1"}],["path",{"d":"M 10,15 6.5,18.5","class":"s2"}],["path",{"d":"M 10,10 5.5,14.5","class":"s2"}],["path",{"d":"M 10,5 4.5,10.5","class":"s2"}],["path",{"d":"M 10,0 3.5,6.5","class":"s2"}],["path",{"d":"M 2.463621,2.536379 5,0","class":"s2"}]],["g",{"id":"umd"},["path",{"d":"m 0,0 1,0 c 1,7 4,20 9,20","class":"s1"}]],["g",{"id":"umu"},["path",{"d":"M 0,0 10,0","class":"s3"}]],["g",{"id":"umz"},["path",{"d":"m 0,0 1,0 c 2,6 6,10 9,10","class":"s4"}]],["g",{"id":"zzz"},["path",{"d":"m 0,10 10,0","class":"s1"}]],["g",{"id":"zm0"},["path",{"d":"m 0,10 1,0 4,10 5,0","class":"s1"}]],["g",{"id":"zm1"},["path",{"d":"M 0,10 1,10 5,0 10,0","class":"s1"}]],["g",{"id":"zmx"},["path",{"d":"m 1,10 4,10 5,0","class":"s1"}],["path",{"d":"M 0,10 1,10 5,0 10,0","class":"s1"}],["path",{"d":"M 10,15 5,20","class":"s2"}],["path",{"d":"M 10,10 4,16","class":"s2"}],["path",{"d":"M 10,5 2.5,12.5","class":"s2"}],["path",{"d":"M 10,0 2,8","class":"s2"}]],["g",{"id":"zmd"},["path",{"d":"m 0,10 1,0 c 2,6 6,10 9,10","class":"s1"}]],["g",{"id":"zmu"},["path",{"d":"m 0,10 1,0 C 3,4 7,0 10,0","class":"s1"}]],["g",{"id":"zmz"},["path",{"d":"m 0,10 10,0","class":"s1"}]],["g",{"id":"gap"},["path",{"d":"m 7,-2 -4,0 c -5,0 -5,24 -10,24 l 4,0 C 2,22 2,-2 7,-2 z","class":"s5"}],["path",{"d":"M -7,22 C -2,22 -2,-2 3,-2","class":"s1"}],["path",{"d":"M -3,22 C 2,22 2,-2 7,-2","class":"s1"}]],["g",{"id":"0mv-3"},["path",{"d":"m 7,0 3,0 0,20 -9,0 z","class":"s6"}],["path",{"d":"M 1,20 7,0 10,0","class":"s1"}],["path",{"d":"m 0,20 10,0","class":"s1"}]],["g",{"id":"1mv-3"},["path",{"d":"m 1,0 9,0 0,20 -3,0 z","class":"s6"}],["path",{"d":"m 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,0 10,0","class":"s1"}]],["g",{"id":"xmv-3"},["path",{"d":"M 7,0 10,0 10,20 7,20 4,10 z","class":"s6"}],["path",{"d":"M 0,20 1,20 7,0 10,0","class":"s1"}],["path",{"d":"m 0,0 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,5 2,3","class":"s2"}],["path",{"d":"M 0,10 3,7","class":"s2"}],["path",{"d":"M 0,15 3,12","class":"s2"}],["path",{"d":"M 0,20 1,19","class":"s2"}]],["g",{"id":"dmv-3"},["path",{"d":"m 7,0 3,0 0,20 -9,0 z","class":"s6"}],["path",{"d":"M 1,20 7,0 10,0","class":"s1"}],["path",{"d":"m 0,20 10,0","class":"s1"}]],["g",{"id":"umv-3"},["path",{"d":"m 1,0 9,0 0,20 -3,0 z","class":"s6"}],["path",{"d":"m 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,0 10,0","class":"s1"}]],["g",{"id":"zmv-3"},["path",{"d":"M 5,0 10,0 10,20 5,20 1,10 z","class":"s6"}],["path",{"d":"m 1,10 4,10 5,0","class":"s1"}],["path",{"d":"M 0,10 1,10 5,0 10,0","class":"s1"}]],["g",{"id":"vvv-3"},["path",{"d":"M 10,20 0,20 0,0 10,0","class":"s6"}],["path",{"d":"m 0,20 10,0","class":"s1"}],["path",{"d":"M 0,0 10,0","class":"s1"}]],["g",{"id":"vm0-3"},["path",{"d":"m 0,20 0,-20 1.000687,-0.00391 6,20","class":"s6"}],["path",{"d":"m 0,0 1.000687,-0.00391 6,20","class":"s1"}],["path",{"d":"m 0,20 10.000687,-0.0039","class":"s1"}]],["g",{"id":"vm1-3"},["path",{"d":"M 0,0 0,20 1,20 7,0","class":"s6"}],["path",{"d":"M 0,0 10,0","class":"s1"}],["path",{"d":"M 0,20 1,20 7,0","class":"s1"}]],["g",{"id":"vmx-3"},["path",{"d":"M 0,0 0,20 1,20 4,10 1,0","class":"s6"}],["path",{"d":"m 0,0 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,20 1,20 7,0 10,0","class":"s1"}],["path",{"d":"M 10,15 6.5,18.5","class":"s2"}],["path",{"d":"M 10,10 5.5,14.5","class":"s2"}],["path",{"d":"M 10,5 4,11","class":"s2"}],["path",{"d":"M 10,0 6,4","class":"s2"}]],["g",{"id":"vmd-3"},["path",{"d":"m 0,0 0,20 10,0 C 5,20 2,7 1,0","class":"s6"}],["path",{"d":"m 0,0 1,0 c 1,7 4,20 9,20","class":"s1"}],["path",{"d":"m 0,20 10,0","class":"s1"}]],["g",{"id":"vmu-3"},["path",{"d":"m 0,0 0,20 1,0 C 2,13 5,0 10,0","class":"s6"}],["path",{"d":"m 0,20 1,0 C 2,13 5,0 10,0","class":"s1"}],["path",{"d":"M 0,0 10,0","class":"s1"}]],["g",{"id":"vmz-3"},["path",{"d":"M 0,0 1,0 C 3,6 7,10 10,10 7,10 3,14 1,20 L 0,20","class":"s6"}],["path",{"d":"m 0,0 1,0 c 2,6 6,10 9,10","class":"s1"}],["path",{"d":"m 0,20 1,0 C 3,14 7,10 10,10","class":"s1"}]],["g",{"id":"vmv-3-3"},["path",{"d":"M 7,0 10,0 10,20 7,20 4,10 z","class":"s6"}],["path",{"d":"M 1,0 0,0 0,20 1,20 4,10 z","class":"s6"}],["path",{"d":"m 0,0 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,20 1,20 7,0 10,0","class":"s1"}]],["g",{"id":"vmv-3-4"},["path",{"d":"M 7,0 10,0 10,20 7,20 4,10 z","class":"s7"}],["path",{"d":"M 1,0 0,0 0,20 1,20 4,10 z","class":"s6"}],["path",{"d":"m 0,0 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,20 1,20 7,0 10,0","class":"s1"}]],["g",{"id":"vmv-3-5"},["path",{"d":"M 7,0 10,0 10,20 7,20 4,10 z","class":"s8"}],["path",{"d":"M 1,0 0,0 0,20 1,20 4,10 z","class":"s6"}],["path",{"d":"m 0,0 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,20 1,20 7,0 10,0","class":"s1"}]],["g",{"id":"vmv-4-3"},["path",{"d":"M 7,0 10,0 10,20 7,20 4,10 z","class":"s6"}],["path",{"d":"M 1,0 0,0 0,20 1,20 4,10 z","class":"s7"}],["path",{"d":"m 0,0 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,20 1,20 7,0 10,0","class":"s1"}]],["g",{"id":"vmv-4-4"},["path",{"d":"M 7,0 10,0 10,20 7,20 4,10 z","class":"s7"}],["path",{"d":"M 1,0 0,0 0,20 1,20 4,10 z","class":"s7"}],["path",{"d":"m 0,0 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,20 1,20 7,0 10,0","class":"s1"}]],["g",{"id":"vmv-4-5"},["path",{"d":"M 7,0 10,0 10,20 7,20 4,10 z","class":"s8"}],["path",{"d":"M 1,0 0,0 0,20 1,20 4,10 z","class":"s7"}],["path",{"d":"m 0,0 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,20 1,20 7,0 10,0","class":"s1"}]],["g",{"id":"vmv-5-3"},["path",{"d":"M 7,0 10,0 10,20 7,20 4,10 z","class":"s6"}],["path",{"d":"M 1,0 0,0 0,20 1,20 4,10 z","class":"s8"}],["path",{"d":"m 0,0 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,20 1,20 7,0 10,0","class":"s1"}]],["g",{"id":"vmv-5-4"},["path",{"d":"M 7,0 10,0 10,20 7,20 4,10 z","class":"s7"}],["path",{"d":"M 1,0 0,0 0,20 1,20 4,10 z","class":"s8"}],["path",{"d":"m 0,0 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,20 1,20 7,0 10,0","class":"s1"}]],["g",{"id":"vmv-5-5"},["path",{"d":"M 7,0 10,0 10,20 7,20 4,10 z","class":"s8"}],["path",{"d":"M 1,0 0,0 0,20 1,20 4,10 z","class":"s8"}],["path",{"d":"m 0,0 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,20 1,20 7,0 10,0","class":"s1"}]],["g",{"id":"0mv-4"},["path",{"d":"m 7,0 3,0 0,20 -9,0 z","class":"s7"}],["path",{"d":"M 1,20 7,0 10,0","class":"s1"}],["path",{"d":"m 0,20 10,0","class":"s1"}]],["g",{"id":"1mv-4"},["path",{"d":"m 1,0 9,0 0,20 -3,0 z","class":"s7"}],["path",{"d":"m 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,0 10,0","class":"s1"}]],["g",{"id":"xmv-4"},["path",{"d":"M 7,0 10,0 10,20 7,20 4,10 z","class":"s7"}],["path",{"d":"M 0,20 1,20 7,0 10,0","class":"s1"}],["path",{"d":"m 0,0 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,5 2,3","class":"s2"}],["path",{"d":"M 0,10 3,7","class":"s2"}],["path",{"d":"M 0,15 4,11","class":"s2"}],["path",{"d":"M 0,20 1,19","class":"s2"}]],["g",{"id":"dmv-4"},["path",{"d":"m 7,0 3,0 0,20 -9,0 z","class":"s7"}],["path",{"d":"M 1,20 7,0 10,0","class":"s1"}],["path",{"d":"m 0,20 10,0","class":"s1"}]],["g",{"id":"umv-4"},["path",{"d":"m 1,0 9,0 0,20 -3,0 z","class":"s7"}],["path",{"d":"m 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,0 10,0","class":"s1"}]],["g",{"id":"zmv-4"},["path",{"d":"M 5,0 10,0 10,20 5,20 1,10 z","class":"s7"}],["path",{"d":"m 1,10 4,10 5,0","class":"s1"}],["path",{"d":"M 0,10 1,10 5,0 10,0","class":"s1"}]],["g",{"id":"0mv-5"},["path",{"d":"m 7,0 3,0 0,20 -9,0 z","class":"s8"}],["path",{"d":"M 1,20 7,0 10,0","class":"s1"}],["path",{"d":"m 0,20 10,0","class":"s1"}]],["g",{"id":"1mv-5"},["path",{"d":"m 1,0 9,0 0,20 -3,0 z","class":"s8"}],["path",{"d":"m 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,0 10,0","class":"s1"}]],["g",{"id":"xmv-5"},["path",{"d":"M 7,0 10,0 10,20 7,20 4,10 z","class":"s8"}],["path",{"d":"M 0,20 1,20 7,0 10,0","class":"s1"}],["path",{"d":"m 0,0 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,5 2,3","class":"s2"}],["path",{"d":"M 0,10 3,7","class":"s2"}],["path",{"d":"M 0,15 4,11","class":"s2"}],["path",{"d":"M 0,20 1,19","class":"s2"}]],["g",{"id":"dmv-5"},["path",{"d":"m 7,0 3,0 0,20 -9,0 z","class":"s8"}],["path",{"d":"M 1,20 7,0 10,0","class":"s1"}],["path",{"d":"m 0,20 10,0","class":"s1"}]],["g",{"id":"umv-5"},["path",{"d":"m 1,0 9,0 0,20 -3,0 z","class":"s8"}],["path",{"d":"m 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,0 10,0","class":"s1"}]],["g",{"id":"zmv-5"},["path",{"d":"M 5,0 10,0 10,20 5,20 1,10 z","class":"s8"}],["path",{"d":"m 1,10 4,10 5,0","class":"s1"}],["path",{"d":"M 0,10 1,10 5,0 10,0","class":"s1"}]],["g",{"id":"vvv-4"},["path",{"d":"M 10,20 0,20 0,0 10,0","class":"s7"}],["path",{"d":"m 0,20 10,0","class":"s1"}],["path",{"d":"M 0,0 10,0","class":"s1"}]],["g",{"id":"vm0-4"},["path",{"d":"M 0,20 0,0 1,0 7,20","class":"s7"}],["path",{"d":"M 0,0 1,0 7,20","class":"s1"}],["path",{"d":"m 0,20 10,0","class":"s1"}]],["g",{"id":"vm1-4"},["path",{"d":"M 0,0 0,20 1,20 7,0","class":"s7"}],["path",{"d":"M 0,0 10,0","class":"s1"}],["path",{"d":"M 0,20 1,20 7,0","class":"s1"}]],["g",{"id":"vmx-4"},["path",{"d":"M 0,0 0,20 1,20 4,10 1,0","class":"s7"}],["path",{"d":"m 0,0 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,20 1,20 7,0 10,0","class":"s1"}],["path",{"d":"M 10,15 6.5,18.5","class":"s2"}],["path",{"d":"M 10,10 5.5,14.5","class":"s2"}],["path",{"d":"M 10,5 4,11","class":"s2"}],["path",{"d":"M 10,0 6,4","class":"s2"}]],["g",{"id":"vmd-4"},["path",{"d":"m 0,0 0,20 10,0 C 5,20 2,7 1,0","class":"s7"}],["path",{"d":"m 0,0 1,0 c 1,7 4,20 9,20","class":"s1"}],["path",{"d":"m 0,20 10,0","class":"s1"}]],["g",{"id":"vmu-4"},["path",{"d":"m 0,0 0,20 1,0 C 2,13 5,0 10,0","class":"s7"}],["path",{"d":"m 0,20 1,0 C 2,13 5,0 10,0","class":"s1"}],["path",{"d":"M 0,0 10,0","class":"s1"}]],["g",{"id":"vmz-4"},["path",{"d":"M 0,0 1,0 C 3,6 7,10 10,10 7,10 3,14 1,20 L 0,20","class":"s7"}],["path",{"d":"m 0,0 1,0 c 2,6 6,10 9,10","class":"s1"}],["path",{"d":"m 0,20 1,0 C 3,14 7,10 10,10","class":"s1"}]],["g",{"id":"vvv-5"},["path",{"d":"M 10,20 0,20 0,0 10,0","class":"s8"}],["path",{"d":"m 0,20 10,0","class":"s1"}],["path",{"d":"M 0,0 10,0","class":"s1"}]],["g",{"id":"vm0-5"},["path",{"d":"M 0,20 0,0 1,0 7,20","class":"s8"}],["path",{"d":"M 0,0 1,0 7,20","class":"s1"}],["path",{"d":"m 0,20 10,0","class":"s1"}]],["g",{"id":"vm1-5"},["path",{"d":"M 0,0 0,20 1,20 7,0","class":"s8"}],["path",{"d":"M 0,0 10,0","class":"s1"}],["path",{"d":"M 0,20 1,20 7,0","class":"s1"}]],["g",{"id":"vmx-5"},["path",{"d":"M 0,0 0,20 1,20 4,10 1,0","class":"s8"}],["path",{"d":"m 0,0 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,20 1,20 7,0 10,0","class":"s1"}],["path",{"d":"M 10,15 6.5,18.5","class":"s2"}],["path",{"d":"M 10,10 5.5,14.5","class":"s2"}],["path",{"d":"M 10,5 4,11","class":"s2"}],["path",{"d":"M 10,0 6,4","class":"s2"}]],["g",{"id":"vmd-5"},["path",{"d":"m 0,0 0,20 10,0 C 5,20 2,7 1,0","class":"s8"}],["path",{"d":"m 0,0 1,0 c 1,7 4,20 9,20","class":"s1"}],["path",{"d":"m 0,20 10,0","class":"s1"}]],["g",{"id":"vmu-5"},["path",{"d":"m 0,0 0,20 1,0 C 2,13 5,0 10,0","class":"s8"}],["path",{"d":"m 0,20 1,0 C 2,13 5,0 10,0","class":"s1"}],["path",{"d":"M 0,0 10,0","class":"s1"}]],["g",{"id":"vmz-5"},["path",{"d":"M 0,0 1,0 C 3,6 7,10 10,10 7,10 3,14 1,20 L 0,20","class":"s8"}],["path",{"d":"m 0,0 1,0 c 2,6 6,10 9,10","class":"s1"}],["path",{"d":"m 0,20 1,0 C 3,14 7,10 10,10","class":"s1"}]],["g",{"id":"Pclk"},["path",{"d":"M -3,12 0,3 3,12 C 1,11 -1,11 -3,12 z","class":"s9"}],["path",{"d":"M 0,20 0,0 10,0","class":"s1"}]],["g",{"id":"Nclk"},["path",{"d":"M -3,8 0,17 3,8 C 1,9 -1,9 -3,8 z","class":"s9"}],["path",{"d":"m 0,0 0,20 10,0","class":"s1"}]],["g",{"id":"vvv-2"},["path",{"d":"M 10,20 0,20 0,0 10,0","class":"s10"}],["path",{"d":"m 0,20 10,0","class":"s1"}],["path",{"d":"M 0,0 10,0","class":"s1"}]],["g",{"id":"vm0-2"},["path",{"d":"m 0,20 0,-20 1.000687,-0.00391 5,20","class":"s10"}],["path",{"d":"m 0,0 1.000687,-0.00391 6,20","class":"s1"}],["path",{"d":"m 0,20 10.000687,-0.0039","class":"s1"}]],["g",{"id":"vm1-2"},["path",{"d":"M 0,0 0,20 3,20 9,0","class":"s10"}],["path",{"d":"M 0,0 10,0","class":"s1"}],["path",{"d":"M 0,20 1,20 7,0","class":"s1"}]],["g",{"id":"vmx-2"},["path",{"d":"M 0,0 0,20 1,20 4,10 1,0","class":"s10"}],["path",{"d":"m 0,0 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,20 1,20 7,0 10,0","class":"s1"}],["path",{"d":"M 10,15 6.5,18.5","class":"s2"}],["path",{"d":"M 10,10 5.5,14.5","class":"s2"}],["path",{"d":"M 10,5 4,11","class":"s2"}],["path",{"d":"M 10,0 6,4","class":"s2"}]],["g",{"id":"vmd-2"},["path",{"d":"m 0,0 0,20 10,0 C 5,20 2,7 1,0","class":"s10"}],["path",{"d":"m 0,0 1,0 c 1,7 4.0217106,19.565788 9,20","class":"s1"}],["path",{"d":"m 0,20 10,0","class":"s1"}]],["g",{"id":"vmu-2"},["path",{"d":"m 0,0 0,20 1,0 C 2,13 5,0 10,0","class":"s10"}],["path",{"d":"m 0,20 1,0 C 2,13 5,0 10,0","class":"s1"}],["path",{"d":"M 0,0 10,0","class":"s1"}]],["g",{"id":"vmz-2"},["path",{"d":"M 0,0 1,0 C 3,6 7,10 10,10 7,10 3,14 1,20 L 0,20","class":"s10"}],["path",{"d":"m 0,0 1,0 c 2,6 6,10 9,10","class":"s1"}],["path",{"d":"m 0,20 1,0 C 3,14 7,10 10,10","class":"s1"}]],["g",{"id":"0mv-2"},["path",{"d":"m 7,0 3,0 0,20 -9,0 z","class":"s10"}],["path",{"d":"M 1,20 7,0 10,0","class":"s1"}],["path",{"d":"m 0,20 10,0","class":"s1"}]],["g",{"id":"1mv-2"},["path",{"d":"m 1,0 9,0 0,20 -3,0 z","class":"s10"}],["path",{"d":"m 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,0 10,0","class":"s1"}]],["g",{"id":"xmv-2"},["path",{"d":"M 7,0 10,0 10,20 7,20 4,10 z","class":"s10"}],["path",{"d":"M 0,20 1,20 7,0 10,0","class":"s1"}],["path",{"d":"m 0,0 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,5 2,3","class":"s2"}],["path",{"d":"M 0,10 3,7","class":"s2"}],["path",{"d":"M 0,15 4,11","class":"s2"}],["path",{"d":"M 0,20 1,19","class":"s2"}]],["g",{"id":"dmv-2"},["path",{"d":"m 7,0 3,0 0,20 -9,0 z","class":"s10"}],["path",{"d":"M 1,20 7,0 10,0","class":"s1"}],["path",{"d":"m 0,20 10,0","class":"s1"}]],["g",{"id":"umv-2"},["path",{"d":"m 1,0 9,0 0,20 -3,0 z","class":"s10"}],["path",{"d":"m 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,0 10,0","class":"s1"}]],["g",{"id":"zmv-2"},["path",{"d":"M 5,0 10,0 10,20 5,20 1,10 z","class":"s10"}],["path",{"d":"m 1,10 4,10 5,0","class":"s1"}],["path",{"d":"M 0,10 1,10 5,0 10,0","class":"s1"}]],["g",{"id":"vmv-3-2"},["path",{"d":"M 7,0 10,0 10,20 7,20 4,10 z","class":"s10"}],["path",{"d":"M 1,0 0,0 0,20 1,20 4,10 z","class":"s6"}],["path",{"d":"m 0,0 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,20 1,20 7,0 10,0","class":"s1"}]],["g",{"id":"vmv-4-2"},["path",{"d":"M 7,0 10,0 10,20 7,20 4,10 z","class":"s10"}],["path",{"d":"M 1,0 0,0 0,20 1,20 4,10 z","class":"s7"}],["path",{"d":"m 0,0 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,20 1,20 7,0 10,0","class":"s1"}]],["g",{"id":"vmv-5-2"},["path",{"d":"M 7,0 10,0 10,20 7,20 4,10 z","class":"s10"}],["path",{"d":"M 1,0 0,0 0,20 1,20 4,10 z","class":"s8"}],["path",{"d":"m 0,0 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,20 1,20 7,0 10,0","class":"s1"}]],["g",{"id":"vmv-2-3"},["path",{"d":"M 7,0 10,0 10,20 7,20 4,10 z","class":"s6"}],["path",{"d":"M 1,0 0,0 0,20 1,20 4,10 z","class":"s10"}],["path",{"d":"m 0,0 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,20 1,20 7,0 10,0","class":"s1"}]],["g",{"id":"vmv-2-4"},["path",{"d":"M 7,0 10,0 10,20 7,20 4,10 z","class":"s7"}],["path",{"d":"M 1,0 0,0 0,20 1,20 4,10 z","class":"s10"}],["path",{"d":"m 0,0 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,20 1,20 7,0 10,0","class":"s1"}]],["g",{"id":"vmv-2-5"},["path",{"d":"M 7,0 10,0 10,20 7,20 4,10 z","class":"s8"}],["path",{"d":"M 1,0 0,0 0,20 1,20 4,10 z","class":"s10"}],["path",{"d":"m 0,0 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,20 1,20 7,0 10,0","class":"s1"}]],["g",{"id":"vmv-2-2"},["path",{"d":"M 7,0 10,0 10,20 7,20 4,10 z","class":"s10"}],["path",{"d":"M 1,0 0,0 0,20 1,20 4,10 z","class":"s10"}],["path",{"d":"m 0,0 1,0 6,20 3,0","class":"s1"}],["path",{"d":"M 0,20 1,20 7,0 10,0","class":"s1"}]],["marker",{"id":"arrowhead","style":"fill:#0041c4","markerHeight":"7","markerWidth":"10","markerUnits":"strokeWidth","viewBox":"0 -4 11 8","refX":"15","refY":"0","orient":"auto"},["path",{"d":"M0 -4 11 0 0 4z"}]],["marker",{"id":"arrowtail","style":"fill:#0041c4","markerHeight":"7","markerWidth":"10","markerUnits":"strokeWidth","viewBox":"-11 -4 11 8","refX":"-15","refY":"0","orient":"auto"},["path",{"d":"M0 -4 -11 0 0 4z"}]]],["g",{"id":"waves"},["g",{"id":"lanes"}],["g",{"id":"groups"}]]];
(function(f){if(typeof exports==="object"&&typeof module!=="undefined"){module.exports=f()}else if(typeof define==="function"&&define.amd){define([],f)}else{var g;if(typeof window!=="undefined"){g=window}else if(typeof global!=="undefined"){g=global}else if(typeof self!=="undefined"){g=self}else{g=this}g.WaveDrom = f()}})(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
'use strict';

var token = /<o>|<ins>|<s>|<sub>|<sup>|<b>|<i>|<tt>|<\/o>|<\/ins>|<\/s>|<\/sub>|<\/sup>|<\/b>|<\/i>|<\/tt>/;

function update (s, cmd) {
    if (cmd.add) {
        cmd.add.split(';').forEach(function (e) {
            var arr = e.split(' ');
            s[arr[0]][arr[1]] = true;
        });
    }
    if (cmd.del) {
        cmd.del.split(';').forEach(function (e) {
            var arr = e.split(' ');
            delete s[arr[0]][arr[1]];
        });
    }
}

var trans = {
    '<o>'    : { add: 'text-decoration overline' },
    '</o>'   : { del: 'text-decoration overline' },

    '<ins>'  : { add: 'text-decoration underline' },
    '</ins>' : { del: 'text-decoration underline' },

    '<s>'    : { add: 'text-decoration line-through' },
    '</s>'   : { del: 'text-decoration line-through' },

    '<b>'    : { add: 'font-weight bold' },
    '</b>'   : { del: 'font-weight bold' },

    '<i>'    : { add: 'font-style italic' },
    '</i>'   : { del: 'font-style italic' },

    '<sub>'  : { add: 'baseline-shift sub;font-size .7em' },
    '</sub>' : { del: 'baseline-shift sub;font-size .7em' },

    '<sup>'  : { add: 'baseline-shift super;font-size .7em' },
    '</sup>' : { del: 'baseline-shift super;font-size .7em' },

    '<tt>'   : { add: 'font-family monospace' },
    '</tt>'  : { del: 'font-family monospace' }
};

function dump (s) {
    return Object.keys(s).reduce(function (pre, cur) {
        var keys = Object.keys(s[cur]);
        if (keys.length > 0) {
            pre[cur] = keys.join(' ');
        }
        return pre;
    }, {});
}

function parse (str) {
    var state, res, i, m, a;

    if (str === undefined) {
        return [];
    }

    if (typeof str === 'number') {
        return [str + ''];
    }

    if (typeof str !== 'string') {
        return [str];
    }

    res = [];

    state = {
        'text-decoration': {},
        'font-weight': {},
        'font-style': {},
        'baseline-shift': {},
        'font-size': {},
        'font-family': {}
    };

    while (true) {
        i = str.search(token);

        if (i === -1) {
            res.push(['tspan', dump(state), str]);
            return res;
        }

        if (i > 0) {
            a = str.slice(0, i);
            res.push(['tspan', dump(state), a]);
        }

        m = str.match(token)[0];

        update(state, trans[m]);

        str = str.slice(i + m.length);

        if (str.length === 0) {
            return res;
        }
    }
}

exports.parse = parse;

},{}],2:[function(require,module,exports){
'use strict';

function appendSaveAsDialog (index, output) {
    var div;
    var menu;

    function closeMenu(e) {
        var left = parseInt(menu.style.left, 10);
        var top = parseInt(menu.style.top, 10);
        if (
            e.x < left ||
            e.x > (left + menu.offsetWidth) ||
            e.y < top ||
            e.y > (top + menu.offsetHeight)
        ) {
            menu.parentNode.removeChild(menu);
            document.body.removeEventListener('mousedown', closeMenu, false);
        }
    }

    div = document.getElementById(output + index);

    div.childNodes[0].addEventListener('contextmenu',
        function (e) {
            var list, savePng, saveSvg;

            menu = document.createElement('div');

            menu.className = 'wavedromMenu';
            menu.style.top = e.y + 'px';
            menu.style.left = e.x + 'px';

            list = document.createElement('ul');
            savePng = document.createElement('li');
            savePng.innerHTML = 'Save as PNG';
            list.appendChild(savePng);

            saveSvg = document.createElement('li');
            saveSvg.innerHTML = 'Save as SVG';
            list.appendChild(saveSvg);

            //var saveJson = document.createElement('li');
            //saveJson.innerHTML = 'Save as JSON';
            //list.appendChild(saveJson);

            menu.appendChild(list);

            document.body.appendChild(menu);

            savePng.addEventListener('click',
                function () {
                    var html, firstDiv, svgdata, img, canvas, context, pngdata, a;

                    html = '';
                    if (index !== 0) {
                        firstDiv = document.getElementById(output + 0);
                        html += firstDiv.innerHTML.substring(166, firstDiv.innerHTML.indexOf('<g id="waves_0">'));
                    }
                    html = [div.innerHTML.slice(0, 166), html, div.innerHTML.slice(166)].join('');
                    svgdata = 'data:image/svg+xml;base64,' + btoa(html);
                    img = new Image();
                    img.src = svgdata;
                    canvas = document.createElement('canvas');
                    canvas.width = img.width;
                    canvas.height = img.height;
                    context = canvas.getContext('2d');
                    context.drawImage(img, 0, 0);

                    pngdata = canvas.toDataURL('image/png');

                    a = document.createElement('a');
                    a.href = pngdata;
                    a.download = 'wavedrom.png';
                    a.click();

                    menu.parentNode.removeChild(menu);
                    document.body.removeEventListener('mousedown', closeMenu, false);
                },
                false
            );

            saveSvg.addEventListener('click',
                function () {
                    var html,
                        firstDiv,
                        svgdata,
                        a;

                    html = '';
                    if (index !== 0) {
                        firstDiv = document.getElementById(output + 0);
                        html += firstDiv.innerHTML.substring(166, firstDiv.innerHTML.indexOf('<g id="waves_0">'));
                    }
                    html = [div.innerHTML.slice(0, 166), html, div.innerHTML.slice(166)].join('');
                    svgdata = 'data:image/svg+xml;base64,' + btoa(html);

                    a = document.createElement('a');
                    a.href = svgdata;
                    a.download = 'wavedrom.svg';
                    a.click();

                    menu.parentNode.removeChild(menu);
                    document.body.removeEventListener('mousedown', closeMenu, false);
                },
                false
            );

            menu.addEventListener('contextmenu',
                function (ee) {
                    ee.preventDefault();
                },
                false
            );

            document.body.addEventListener('mousedown', closeMenu, false);

            e.preventDefault();
        },
        false
    );
}

module.exports = appendSaveAsDialog;

/* eslint-env browser */

},{}],3:[function(require,module,exports){
'use strict';

var // obj2ml = require('./obj2ml'),
    jsonmlParse = require('./jsonml-parse');

// function createElement (obj) {
//     var el;
//
//     el = document.createElement('g');
//     el.innerHTML = obj2ml(obj);
//     return el.firstChild;
// }

module.exports = jsonmlParse;
// module.exports = createElement;

/* eslint-env browser */

},{"./jsonml-parse":16}],4:[function(require,module,exports){
'use strict';

var eva = require('./eva'),
    renderWaveForm = require('./render-wave-form');

function editorRefresh () {
    // var svg,
    // 	ser,
    // 	ssvg,
    // 	asvg,
    // 	sjson,
    // 	ajson;

    renderWaveForm(0, eva('InputJSON_0'), 'WaveDrom_Display_');

    /*
    svg = document.getElementById('svgcontent_0');
    ser = new XMLSerializer();
    ssvg = '<?xml version='1.0' standalone='no'?>\n' +
    '<!DOCTYPE svg PUBLIC '-//W3C//DTD SVG 1.1//EN' 'http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd'>\n' +
    '<!-- Created with WaveDrom -->\n' +
    ser.serializeToString(svg);

    asvg = document.getElementById('download_svg');
    asvg.href = 'data:image/svg+xml;base64,' + window.btoa(ssvg);

    sjson = localStorage.waveform;
    ajson = document.getElementById('download_json');
    ajson.href = 'data:text/json;base64,' + window.btoa(sjson);
    */
}

module.exports = editorRefresh;

},{"./eva":5,"./render-wave-form":29}],5:[function(require,module,exports){
'use strict';

function eva (id) {
    var TheTextBox, source;

    function erra (e) {
        return { signal: [{ name: ['tspan', ['tspan', {class:'error h5'}, 'Error: '], e.message] }]};
    }

    TheTextBox = document.getElementById(id);

    /* eslint-disable no-eval */
    if (TheTextBox.type && TheTextBox.type === 'textarea') {
        try { source = eval('(' + TheTextBox.value + ')'); } catch (e) { return erra(e); }
    } else {
        try { source = eval('(' + TheTextBox.innerHTML + ')'); } catch (e) { return erra(e); }
    }
    /* eslint-enable  no-eval */

    if (Object.prototype.toString.call(source) !== '[object Object]') {
        return erra({ message: '[Semantic]: The root has to be an Object: "{signal:[...]}"'});
    }
    if (source.signal) {
        if (Object.prototype.toString.call(source.signal) !== '[object Array]') {
            return erra({ message: '[Semantic]: "signal" object has to be an Array "signal:[]"'});
        }
    } else if (source.assign) {
        if (Object.prototype.toString.call(source.assign) !== '[object Array]') {
            return erra({ message: '[Semantic]: "assign" object hasto be an Array "assign:[]"'});
        }
    } else {
        return erra({ message: '[Semantic]: "signal:[...]" or "assign:[...]" property is missing inside the root Object'});
    }
    return source;
}

module.exports = eva;

/* eslint-env browser */

},{}],6:[function(require,module,exports){
'use strict';

function findLaneMarkers (lanetext) {
    var gcount = 0,
        lcount = 0,
        ret = [];

    lanetext.forEach(function (e) {
        if (
            (e === 'vvv-2') ||
            (e === 'vvv-3') ||
            (e === 'vvv-4') ||
            (e === 'vvv-5')
        ) {
            lcount += 1;
        } else {
            if (lcount !== 0) {
                ret.push(gcount - ((lcount + 1) / 2));
                lcount = 0;
            }
        }
        gcount += 1;

    });

    if (lcount !== 0) {
        ret.push(gcount - ((lcount + 1) / 2));
    }

    return ret;
}

module.exports = findLaneMarkers;

},{}],7:[function(require,module,exports){
'use strict';

function genBrick (texts, extra, times) {
    var i, j, R = [];

    if (texts.length === 4) {
        for (j = 0; j < times; j += 1) {
            R.push(texts[0]);
            for (i = 0; i < extra; i += 1) {
                R.push(texts[1]);
            }
            R.push(texts[2]);
            for (i = 0; i < extra; i += 1) {
                R.push(texts[3]);
            }
        }
        return R;
    }
    if (texts.length === 1) {
        texts.push(texts[0]);
    }
    R.push(texts[0]);
    for (i = 0; i < (times * (2 * (extra + 1)) - 1); i += 1) {
        R.push(texts[1]);
    }
    return R;
}

module.exports = genBrick;

},{}],8:[function(require,module,exports){
'use strict';

var genBrick = require('./gen-brick');

function genFirstWaveBrick (text, extra, times) {
    var tmp;

    tmp = [];
    switch (text) {
        case 'p': tmp = genBrick(['pclk', '111', 'nclk', '000'], extra, times); break;
        case 'n': tmp = genBrick(['nclk', '000', 'pclk', '111'], extra, times); break;
        case 'P': tmp = genBrick(['Pclk', '111', 'nclk', '000'], extra, times); break;
        case 'N': tmp = genBrick(['Nclk', '000', 'pclk', '111'], extra, times); break;
        case 'l':
        case 'L':
        case '0': tmp = genBrick(['000'], extra, times); break;
        case 'h':
        case 'H':
        case '1': tmp = genBrick(['111'], extra, times); break;
        case '=': tmp = genBrick(['vvv-2'], extra, times); break;
        case '2': tmp = genBrick(['vvv-2'], extra, times); break;
        case '3': tmp = genBrick(['vvv-3'], extra, times); break;
        case '4': tmp = genBrick(['vvv-4'], extra, times); break;
        case '5': tmp = genBrick(['vvv-5'], extra, times); break;
        case 'd': tmp = genBrick(['ddd'], extra, times); break;
        case 'u': tmp = genBrick(['uuu'], extra, times); break;
        case 'z': tmp = genBrick(['zzz'], extra, times); break;
        default:  tmp = genBrick(['xxx'], extra, times); break;
    }
    return tmp;
}

module.exports = genFirstWaveBrick;

},{"./gen-brick":7}],9:[function(require,module,exports){
'use strict';

var genBrick = require('./gen-brick');

function genWaveBrick (text, extra, times) {
    var x1, x2, x3, y1, y2, x4, x5, x6, xclude, atext, tmp0, tmp1, tmp2, tmp3, tmp4;

    x1 = {p:'pclk', n:'nclk', P:'Pclk', N:'Nclk', h:'pclk', l:'nclk', H:'Pclk', L:'Nclk'};

    x2 = {
        '0':'0', '1':'1',
        'x':'x',
        'd':'d',
        'u':'u',
        'z':'z',
        '=':'v',  '2':'v',  '3':'v',  '4':'v', '5':'v'
    };

    x3 = {
        '0': '', '1': '',
        'x': '',
        'd': '',
        'u': '',
        'z': '',
        '=':'-2', '2':'-2', '3':'-3', '4':'-4', '5':'-5'
    };

    y1 = {
        'p':'0', 'n':'1',
        'P':'0', 'N':'1',
        'h':'1', 'l':'0',
        'H':'1', 'L':'0',
        '0':'0', '1':'1',
        'x':'x',
        'd':'d',
        'u':'u',
        'z':'z',
        '=':'v', '2':'v', '3':'v', '4':'v', '5':'v'
    };

    y2 = {
        'p': '', 'n': '',
        'P': '', 'N': '',
        'h': '', 'l': '',
        'H': '', 'L': '',
        '0': '', '1': '',
        'x': '',
        'd': '',
        'u': '',
        'z': '',
        '=':'-2', '2':'-2', '3':'-3', '4':'-4', '5':'-5'
    };

    x4 = {
        'p': '111', 'n': '000',
        'P': '111', 'N': '000',
        'h': '111', 'l': '000',
        'H': '111', 'L': '000',
        '0': '000', '1': '111',
        'x': 'xxx',
        'd': 'ddd',
        'u': 'uuu',
        'z': 'zzz',
        '=': 'vvv-2', '2': 'vvv-2', '3': 'vvv-3', '4': 'vvv-4', '5': 'vvv-5'
    };

    x5 = {
        p:'nclk', n:'pclk', P:'nclk', N:'pclk'
    };

    x6 = {
        p: '000', n: '111', P: '000', N: '111'
    };

    xclude = {
        'hp':'111', 'Hp':'111', 'ln': '000', 'Ln': '000', 'nh':'111', 'Nh':'111', 'pl': '000', 'Pl':'000'
    };

    atext = text.split('');
    //if (atext.length !== 2) { return genBrick(['xxx'], extra, times); }

    tmp0 = x4[atext[1]];
    tmp1 = x1[atext[1]];
    if (tmp1 === undefined) {
        tmp2 = x2[atext[1]];
        if (tmp2 === undefined) {
            // unknown
            return genBrick(['xxx'], extra, times);
        } else {
            tmp3 = y1[atext[0]];
            if (tmp3 === undefined) {
                // unknown
                return genBrick(['xxx'], extra, times);
            }
            // soft curves
            return genBrick([tmp3 + 'm' + tmp2 + y2[atext[0]] + x3[atext[1]], tmp0], extra, times);
        }
    } else {
        tmp4 = xclude[text];
        if (tmp4 !== undefined) {
            tmp1 = tmp4;
        }
        // sharp curves
        tmp2 = x5[atext[1]];
        if (tmp2 === undefined) {
            // hlHL
            return genBrick([tmp1, tmp0], extra, times);
        } else {
            // pnPN
            return genBrick([tmp1, tmp0, tmp2, x6[atext[1]]], extra, times);
        }
    }
}

module.exports = genWaveBrick;

},{"./gen-brick":7}],10:[function(require,module,exports){
'use strict';

var processAll = require('./process-all'),
    eva = require('./eva'),
    renderWaveForm = require('./render-wave-form'),
    editorRefresh = require('./editor-refresh');

module.exports = {
    processAll: processAll,
    eva: eva,
    renderWaveForm: renderWaveForm,
    editorRefresh: editorRefresh
};

},{"./editor-refresh":4,"./eva":5,"./process-all":22,"./render-wave-form":29}],11:[function(require,module,exports){
'use strict';

var jsonmlParse = require('./create-element'),
    w3 = require('./w3');

function insertSVGTemplateAssign (index, parent) {
    var node, e;
    // cleanup
    while (parent.childNodes.length) {
        parent.removeChild(parent.childNodes[0]);
    }
    e =
    ['svg', {id: 'svgcontent_' + index, xmlns: w3.svg, 'xmlns:xlink': w3.xlink, overflow:'hidden'},
        ['style', '.pinname {font-size:12px; font-style:normal; font-variant:normal; font-weight:500; font-stretch:normal; text-align:center; text-anchor:end; font-family:Helvetica} .wirename {font-size:12px; font-style:normal; font-variant:normal; font-weight:500; font-stretch:normal; text-align:center; text-anchor:start; font-family:Helvetica} .wirename:hover {fill:blue} .gate {color:#000; fill:#ffc; fill-opacity: 1;stroke:#000; stroke-width:1; stroke-opacity:1} .gate:hover {fill:red !important; } .wire {fill:none; stroke:#000; stroke-width:1; stroke-opacity:1} .grid {fill:#fff; fill-opacity:1; stroke:none}']
    ];
    node = jsonmlParse(e);
    parent.insertBefore(node, null);
}

module.exports = insertSVGTemplateAssign;

/* eslint-env browser */

},{"./create-element":3,"./w3":31}],12:[function(require,module,exports){
'use strict';

var jsonmlParse = require('./create-element'),
    w3 = require('./w3'),
    waveSkin = require('./wave-skin');

function insertSVGTemplate (index, parent, source, lane) {
    var node, first, e;

    // cleanup
    while (parent.childNodes.length) {
        parent.removeChild(parent.childNodes[0]);
    }

    for (first in waveSkin) { break; }

    e = waveSkin.default || waveSkin[first];

    if (source && source.config && source.config.skin && waveSkin[source.config.skin]) {
        e = waveSkin[source.config.skin];
    }

    if (index === 0) {
        lane.xs     = Number(e[3][1][2][1].width);
        lane.ys     = Number(e[3][1][2][1].height);
        lane.xlabel = Number(e[3][1][2][1].x);
        lane.ym     = Number(e[3][1][2][1].y);
    } else {
        e = ['svg',
            {
                id: 'svg',
                xmlns: w3.svg,
                'xmlns:xlink': w3.xlink,
                height: '0'
            },
            ['g',
                {
                    id: 'waves'
                },
                ['g', {id: 'lanes'}],
                ['g', {id: 'groups'}]
            ]
        ];
    }

    e[e.length - 1][1].id    = 'waves_'  + index;
    e[e.length - 1][2][1].id = 'lanes_'  + index;
    e[e.length - 1][3][1].id = 'groups_' + index;
    e[1].id = 'svgcontent_' + index;
    e[1].height = 0;

    node = jsonmlParse(e);
    parent.insertBefore(node, null);
}

module.exports = insertSVGTemplate;

/* eslint-env browser */

},{"./create-element":3,"./w3":31,"./wave-skin":32}],13:[function(require,module,exports){
'use strict';

//attribute name mapping
var ATTRMAP = {
        rowspan : 'rowSpan',
        colspan : 'colSpan',
        cellpadding : 'cellPadding',
        cellspacing : 'cellSpacing',
        tabindex : 'tabIndex',
        accesskey : 'accessKey',
        hidefocus : 'hideFocus',
        usemap : 'useMap',
        maxlength : 'maxLength',
        readonly : 'readOnly',
        contenteditable : 'contentEditable'
        // can add more attributes here as needed
    },
    // attribute duplicates
    ATTRDUP = {
        enctype : 'encoding',
        onscroll : 'DOMMouseScroll'
        // can add more attributes here as needed
    },
    // event names
    EVTS = (function (/*string[]*/ names) {
        var evts = {}, evt;
        while (names.length) {
            evt = names.shift();
            evts['on' + evt.toLowerCase()] = evt;
        }
        return evts;
    })('blur,change,click,dblclick,error,focus,keydown,keypress,keyup,load,mousedown,mouseenter,mouseleave,mousemove,mouseout,mouseover,mouseup,resize,scroll,select,submit,unload'.split(','));

/*void*/ function addHandler(/*DOM*/ elem, /*string*/ name, /*function*/ handler) {
    if (typeof handler === 'string') {
        handler = new Function('event', handler);
    }

    if (typeof handler !== 'function') {
        return;
    }

    elem[name] = handler;
}

/*DOM*/ function addAttributes(/*DOM*/ elem, /*object*/ attr) {
    if (attr.name && document.attachEvent) {
        try {
            // IE fix for not being able to programatically change the name attribute
            var alt = document.createElement('<' + elem.tagName + ' name=\'' + attr.name + '\'>');
            // fix for Opera 8.5 and Netscape 7.1 creating malformed elements
            if (elem.tagName === alt.tagName) {
                elem = alt;
            }
        } catch (ex) {
            console.log(ex);
        }
    }

    // for each attributeName
    for (var name in attr) {
        if (attr.hasOwnProperty(name)) {
            // attributeValue
            var value = attr[name];
            if (
                name &&
                value !== null &&
                typeof value !== 'undefined'
            ) {
                name = ATTRMAP[name.toLowerCase()] || name;
                if (name === 'style') {
                    if (typeof elem.style.cssText !== 'undefined') {
                        elem.style.cssText = value;
                    } else {
                        elem.style = value;
                    }
//                    } else if (name === 'class') {
//                        elem.className = value;
//                        // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//                        elem.setAttribute(name, value);
//                        // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                } else if (EVTS[name]) {
                    addHandler(elem, name, value);

                    // also set duplicated events
                    if (ATTRDUP[name]) {
                        addHandler(elem, ATTRDUP[name], value);
                    }
                } else if (
                     typeof value === 'string' ||
                     typeof value === 'number' ||
                     typeof value === 'boolean'
                ) {
                    elem.setAttribute(name, value);

                    // also set duplicated attributes
                    if (ATTRDUP[name]) {
                        elem.setAttribute(ATTRDUP[name], value);
                    }
                } else {

                    // allow direct setting of complex properties
                    elem[name] = value;

                    // also set duplicated attributes
                    if (ATTRDUP[name]) {
                        elem[ATTRDUP[name]] = value;
                    }
                }
            }
        }
    }
    return elem;
}

module.exports = addAttributes;

/* eslint-env browser */
/* eslint no-new-func:0 */

},{}],14:[function(require,module,exports){
'use strict';

/*void*/ function appendChild(/*DOM*/ elem, /*DOM*/ child) {
    if (child) {
        // if (
        //     elem.tagName &&
        //     elem.tagName.toLowerCase() === 'table' &&
        //     elem.tBodies
        // ) {
        //     if (!child.tagName) {
        //         // must unwrap documentFragment for tables
        //         if (child.nodeType === 11) {
        //             while (child.firstChild) {
        //                 appendChild(elem, child.removeChild(child.firstChild));
        //             }
        //         }
        //         return;
        //     }
        //     // in IE must explicitly nest TRs in TBODY
        //     var childTag = child.tagName.toLowerCase();// child tagName
        //     if (childTag && childTag !== "tbody" && childTag !== "thead") {
        //         // insert in last tbody
        //         var tBody = elem.tBodies.length > 0 ? elem.tBodies[elem.tBodies.length - 1] : null;
        //         if (!tBody) {
        //             tBody = document.createElement(childTag === "th" ? "thead" : "tbody");
        //             elem.appendChild(tBody);
        //         }
        //         tBody.appendChild(child);
        //     } else if (elem.canHaveChildren !== false) {
        //         elem.appendChild(child);
        //     }
        // } else
        if (
            elem.tagName &&
            elem.tagName.toLowerCase() === 'style' &&
            document.createStyleSheet
        ) {
            // IE requires this interface for styles
            elem.cssText = child;
        } else

        if (elem.canHaveChildren !== false) {
            elem.appendChild(child);
        }
        // else if (
        //     elem.tagName &&
        //     elem.tagName.toLowerCase() === 'object' &&
        //     child.tagName &&
        //     child.tagName.toLowerCase() === 'param'
        // ) {
        //         // IE-only path
        //     try {
        //         elem.appendChild(child);
        //     } catch (ex1) {
        //
        //     }
        //     try {
        //         if (elem.object) {
        //             elem.object[child.name] = child.value;
        //         }
        //     } catch (ex2) {}
        // }
    }
}

module.exports = appendChild;

/* eslint-env browser */

},{}],15:[function(require,module,exports){
'use strict';

var trimWhitespace = require('./jsonml-trim-whitespace');

/*DOM*/ function hydrate(/*string*/ value) {
    var wrapper = document.createElement('div');
    wrapper.innerHTML = value;

    // trim extraneous whitespace
    trimWhitespace(wrapper);

    // eliminate wrapper for single nodes
    if (wrapper.childNodes.length === 1) {
        return wrapper.firstChild;
    }

    // create a document fragment to hold elements
    var frag = document.createDocumentFragment ?
        document.createDocumentFragment() :
        document.createElement('');

    while (wrapper.firstChild) {
        frag.appendChild(wrapper.firstChild);
    }
    return frag;
}

module.exports = hydrate;

/* eslint-env browser */

},{"./jsonml-trim-whitespace":17}],16:[function(require,module,exports){
'use strict';

var hydrate = require('./jsonml-hydrate'),
    w3 = require('./w3'),
    appendChild = require('./jsonml-append-child'),
    addAttributes = require('./jsonml-add-attributes'),
    trimWhitespace = require('./jsonml-trim-whitespace');

var patch,
    parse,
    onerror = null;

/*bool*/ function isElement (/*JsonML*/ jml) {
    return (jml instanceof Array) && (typeof jml[0] === 'string');
}

/*DOM*/ function onError (/*Error*/ ex, /*JsonML*/ jml, /*function*/ filter) {
    return document.createTextNode('[' + ex + '-' + filter + ']');
}

patch = /*DOM*/ function (/*DOM*/ elem, /*JsonML*/ jml, /*function*/ filter) {
    for (var i = 1; i < jml.length; i++) {

        if (
            (jml[i] instanceof Array) ||
            (typeof jml[i] === 'string')
        ) {
            // append children
            appendChild(elem, parse(jml[i], filter));
        // } else if (jml[i] instanceof Unparsed) {
        } else if (
            jml[i] &&
            jml[i].value
        ) {
            appendChild(elem, hydrate(jml[i].value));
        } else if (
            (typeof jml[i] === 'object') &&
            (jml[i] !== null) &&
            elem.nodeType === 1
        ) {
            // add attributes
            elem = addAttributes(elem, jml[i]);
        }
    }

    return elem;
};

parse = /*DOM*/ function (/*JsonML*/ jml, /*function*/ filter) {
    var elem;

    try {
        if (!jml) {
            return null;
        }

        if (typeof jml === 'string') {
            return document.createTextNode(jml);
        }

        // if (jml instanceof Unparsed) {
        if (jml && jml.value) {
            return hydrate(jml.value);
        }

        if (!isElement(jml)) {
            throw new SyntaxError('invalid JsonML');
        }

        var tagName = jml[0]; // tagName
        if (!tagName) {
            // correctly handle a list of JsonML trees
            // create a document fragment to hold elements
            var frag = document.createDocumentFragment ?
                document.createDocumentFragment() :
                document.createElement('');
            for (var i = 2; i < jml.length; i++) {
                appendChild(frag, parse(jml[i], filter));
            }

            // trim extraneous whitespace
            trimWhitespace(frag);

            // eliminate wrapper for single nodes
            if (frag.childNodes.length === 1) {
                return frag.firstChild;
            }
            return frag;
        }

        if (
            tagName.toLowerCase() === 'style' &&
            document.createStyleSheet
        ) {
            // IE requires this interface for styles
            patch(document.createStyleSheet(), jml, filter);
            // in IE styles are effective immediately
            return null;
        }

        elem = patch(document.createElementNS(w3.svg, tagName), jml, filter);

        // trim extraneous whitespace
        trimWhitespace(elem);
        // return (elem && (typeof filter === 'function')) ? filter(elem) : elem;
        return elem;
    } catch (ex) {
        try {
            // handle error with complete context
            var err = (typeof onerror === 'function') ? onerror : onError;
            return err(ex, jml, filter);
        } catch (ex2) {
            return document.createTextNode('[' + ex2 + ']');
        }
    }
};

module.exports = parse;

/* eslint-env browser */
/* eslint yoda:1 */

},{"./jsonml-add-attributes":13,"./jsonml-append-child":14,"./jsonml-hydrate":15,"./jsonml-trim-whitespace":17,"./w3":31}],17:[function(require,module,exports){
'use strict';

/*bool*/ function isWhitespace(/*DOM*/ node) {
    return node &&
        (node.nodeType === 3) &&
        (!node.nodeValue || !/\S/.exec(node.nodeValue));
}

/*void*/ function trimWhitespace(/*DOM*/ elem) {
    if (elem) {
        while (isWhitespace(elem.firstChild)) {
            // trim leading whitespace text nodes
            elem.removeChild(elem.firstChild);
        }
        while (isWhitespace(elem.lastChild)) {
            // trim trailing whitespace text nodes
            elem.removeChild(elem.lastChild);
        }
    }
}

module.exports = trimWhitespace;

/* eslint-env browser */

},{}],18:[function(require,module,exports){
'use strict';

var lane = {
    xs     : 20,    // tmpgraphlane0.width
    ys     : 20,    // tmpgraphlane0.height
    xg     : 120,   // tmpgraphlane0.x
    // yg     : 0,     // head gap
    yh0    : 0,     // head gap title
    yh1    : 0,     // head gap
    yf0    : 0,     // foot gap
    yf1    : 0,     // foot gap
    y0     : 5,     // tmpgraphlane0.y
    yo     : 30,    // tmpgraphlane1.y - y0;
    tgo    : -10,   // tmptextlane0.x - xg;
    ym     : 15,    // tmptextlane0.y - y0
    xlabel : 6,     // tmptextlabel.x - xg;
    xmax   : 1,
    scale  : 1,
    head   : {},
    foot   : {}
};

module.exports = lane;

},{}],19:[function(require,module,exports){
'use strict';

function parseConfig (source, lane) {
    var hscale;

    function tonumber (x) {
        return x > 0 ? Math.round(x) : 1;
    }

    lane.hscale = 1;

    if (lane.hscale0) {
        lane.hscale = lane.hscale0;
    }
    if (source && source.config && source.config.hscale) {
        hscale = Math.round(tonumber(source.config.hscale));
        if (hscale > 0) {
            if (hscale > 100) {
                hscale = 100;
            }
            lane.hscale = hscale;
        }
    }
    lane.yh0 = 0;
    lane.yh1 = 0;
    lane.head = source.head;

    lane.xmin_cfg = 0;
    lane.xmax_cfg = 1e12; // essentially infinity
    if (source && source.config && source.config.hbounds && source.config.hbounds.length==2) {
        source.config.hbounds[0] = Math.floor(source.config.hbounds[0]);
        source.config.hbounds[1] = Math.ceil(source.config.hbounds[1]);
        if (  source.config.hbounds[0] < source.config.hbounds[1] ) {
            // convert hbounds ticks min, max to bricks min, max
            // TODO: do we want to base this on ticks or tocks in
            //  head or foot?  All 4 can be different... or just 0 reference?
            lane.xmin_cfg = 2 * Math.floor(source.config.hbounds[0]);
            lane.xmax_cfg = 2 * Math.floor(source.config.hbounds[1]);
        }
    }

    if (source && source.head) {
        if (
            source.head.tick || source.head.tick === 0 ||
            source.head.tock || source.head.tock === 0
        ) {
            lane.yh0 = 20;
        }
        // if tick defined, modify start tick by lane.xmin_cfg
        if ( source.head.tick || source.head.tick === 0 ) {
            source.head.tick = source.head.tick + lane.xmin_cfg/2;
        }
        // if tock defined, modify start tick by lane.xmin_cfg
        if ( source.head.tock || source.head.tock === 0 ) {
            source.head.tock = source.head.tock + lane.xmin_cfg/2;
        }

        if (source.head.text) {
            lane.yh1 = 46;
            lane.head.text = source.head.text;
        }
    }

    lane.yf0 = 0;
    lane.yf1 = 0;
    lane.foot = source.foot;
    if (source && source.foot) {
        if (
            source.foot.tick || source.foot.tick === 0 ||
            source.foot.tock || source.foot.tock === 0
        ) {
            lane.yf0 = 20;
        }
        // if tick defined, modify start tick by lane.xmin_cfg
        if ( source.foot.tick || source.foot.tick === 0 ) {
            source.foot.tick = source.foot.tick + lane.xmin_cfg/2;
        }
        // if tock defined, modify start tick by lane.xmin_cfg
        if ( source.foot.tock || source.foot.tock === 0 ) {
            source.foot.tock = source.foot.tock + lane.xmin_cfg/2;
        }

        if (source.foot.text) {
            lane.yf1 = 46;
            lane.foot.text = source.foot.text;
        }
    }
}

module.exports = parseConfig;

},{}],20:[function(require,module,exports){
'use strict';

var genFirstWaveBrick = require('./gen-first-wave-brick'),
    genWaveBrick = require('./gen-wave-brick'),
    findLaneMarkers = require('./find-lane-markers');

// text is the wave member of the signal object
// extra = hscale-1 ( padding )
// lane is an object containing all properties for this waveform
function parseWaveLane (text, extra, lane) {
    var Repeats, Top, Next, Stack = [], R = [], i, subCycle;
    var unseen_bricks = [], num_unseen_markers;

    Stack = text.split('');
    Next  = Stack.shift();
    subCycle = false;

    Repeats = 1;
    while (Stack[0] === '.' || Stack[0] === '|') { // repeaters parser
        Stack.shift();
        Repeats += 1;
    }
    R = R.concat(genFirstWaveBrick(Next, extra, Repeats));

    while (Stack.length) {
        Top = Next;
        Next = Stack.shift();
        if (Next === '<') { // sub-cycles on
            subCycle = true;
            Next = Stack.shift();
        }
        if (Next === '>') { // sub-cycles off
            subCycle = false;
            Next = Stack.shift();
        }
        Repeats = 1;
        while (Stack[0] === '.' || Stack[0] === '|') { // repeaters parser
            Stack.shift();
            Repeats += 1;
        }
        if (subCycle) {
            R = R.concat(genWaveBrick((Top + Next), 0, Repeats - lane.period));
        } else {
            R = R.concat(genWaveBrick((Top + Next), extra, Repeats));
        }
    }
    // shift out unseen bricks due to phase shift, and save them in
    //  unseen_bricks array
    for (i = 0; i < lane.phase; i += 1) {
        unseen_bricks.push(R.shift());
    }
    if (unseen_bricks.length > 0) {
        num_unseen_markers = findLaneMarkers( unseen_bricks ).length;
        // if end of unseen_bricks and start of R both have a marker,
        //  then one less unseen marker
        if ( findLaneMarkers( [unseen_bricks[unseen_bricks.length-1]] ).length == 1 &&
             findLaneMarkers( [R[0]] ).length == 1 ) {
            num_unseen_markers -= 1;
        }
    } else {
        num_unseen_markers = 0;
    }

    // R is array of half brick types, each is item is string
    // num_unseen_markers is how many markers are now unseen due to phase
    return [R, num_unseen_markers];
}

module.exports = parseWaveLane;

},{"./find-lane-markers":6,"./gen-first-wave-brick":8,"./gen-wave-brick":9}],21:[function(require,module,exports){
'use strict';

var parseWaveLane = require('./parse-wave-lane');

function data_extract (e, num_unseen_markers) {
    var ret_data;

    ret_data = e.data;
    if (ret_data === undefined) { return null; }
    if (typeof (ret_data) === 'string') { ret_data= ret_data.split(' '); }
    // slice data array after unseen markers
    ret_data = ret_data.slice( num_unseen_markers );
    return ret_data;
}

function parseWaveLanes (sig, lane) {
    var x,
        sigx,
        content = [],
        content_wave,
        parsed_wave_lane,
        num_unseen_markers,
        tmp0 = [];

    for (x in sig) {
        // sigx is each signal in the array of signals being iterated over
        sigx = sig[x];
        lane.period = sigx.period ? sigx.period    : 1;
        // xmin_cfg is min. brick of hbounds, add to lane.phase of all signals
        lane.phase  = (sigx.phase  ? sigx.phase * 2 : 0) + lane.xmin_cfg;
        content.push([]);
        tmp0[0] = sigx.name  || ' ';
        // xmin_cfg is min. brick of hbounds, add 1/2 to sigx.phase of all sigs
        tmp0[1] = (sigx.phase || 0) + lane.xmin_cfg/2;
        if ( sigx.wave ) {
            parsed_wave_lane = parseWaveLane(sigx.wave, lane.period * lane.hscale - 1, lane);
            content_wave = parsed_wave_lane[0] ;
            num_unseen_markers = parsed_wave_lane[1];
        } else {
            content_wave = null;
        }
        content[content.length - 1][0] = tmp0.slice(0);
        content[content.length - 1][1] = content_wave;
        content[content.length - 1][2] = data_extract(sigx,num_unseen_markers);
    }
    // content is an array of arrays, representing the list of signals using
    //  the same order:
    // content[0] = [ [name,phase], parsedwavelaneobj, dataextracted ]
    return content;
}

module.exports = parseWaveLanes;

},{"./parse-wave-lane":20}],22:[function(require,module,exports){
'use strict';

var eva = require('./eva'),
    appendSaveAsDialog = require('./append-save-as-dialog'),
    renderWaveForm = require('./render-wave-form');

function processAll () {
    var points,
        i,
        index,
        node0;
        // node1;

    // first pass
    index = 0; // actual number of valid anchor
    points = document.querySelectorAll('*');
    for (i = 0; i < points.length; i++) {
        if (points.item(i).type && points.item(i).type === 'WaveDrom') {
            points.item(i).setAttribute('id', 'InputJSON_' + index);

            node0 = document.createElement('div');
            //			node0.className += 'WaveDrom_Display_' + index;
            node0.id = 'WaveDrom_Display_' + index;
            points.item(i).parentNode.insertBefore(node0, points.item(i));
            // WaveDrom.InsertSVGTemplate(i, node0);
            index += 1;
        }
    }
    // second pass
    for (i = 0; i < index; i += 1) {
        renderWaveForm(i, eva('InputJSON_' + i), 'WaveDrom_Display_');
        appendSaveAsDialog(i, 'WaveDrom_Display_');
    }
    // add styles
    document.head.innerHTML += '<style type="text/css">div.wavedromMenu{position:fixed;border:solid 1pt#CCCCCC;background-color:white;box-shadow:0px 10px 20px #808080;cursor:default;margin:0px;padding:0px;}div.wavedromMenu>ul{margin:0px;padding:0px;}div.wavedromMenu>ul>li{padding:2px 10px;list-style:none;}div.wavedromMenu>ul>li:hover{background-color:#b5d5ff;}</style>';
}

module.exports = processAll;

/* eslint-env browser */

},{"./append-save-as-dialog":2,"./eva":5,"./render-wave-form":29}],23:[function(require,module,exports){
'use strict';

function rec (tmp, state) {
    var i, name, old = {}, delta = {'x':10};
    if (typeof tmp[0] === 'string' || typeof tmp[0] === 'number') {
        name = tmp[0];
        delta.x = 25;
    }
    state.x += delta.x;
    for (i = 0; i < tmp.length; i++) {
        if (typeof tmp[i] === 'object') {
            if (Object.prototype.toString.call(tmp[i]) === '[object Array]') {
                old.y = state.y;
                state = rec(tmp[i], state);
                state.groups.push({'x':state.xx, 'y':old.y, 'height':(state.y - old.y), 'name':state.name});
            } else {
                state.lanes.push(tmp[i]);
                state.width.push(state.x);
                state.y += 1;
            }
        }
    }
    state.xx = state.x;
    state.x -= delta.x;
    state.name = name;
    return state;
}

module.exports = rec;

},{}],24:[function(require,module,exports){
'use strict';

var tspan = require('tspan'),
    jsonmlParse = require('./create-element'),
    w3 = require('./w3');

 function renderArcs (root, source, index, top, lane) {
     var gg,
         i,
         k,
         text,
         Stack = [],
         Edge = {words: [], from: 0, shape: '', to: 0, label: ''},
         Events = {},
         pos,
         eventname,
         // labeltext,
         label,
         underlabel,
         from,
         to,
         dx,
         dy,
         lx,
         ly,
         gmark,
         lwidth;

     function t1 () {
         if (from && to) {
             gmark = document.createElementNS(w3.svg, 'path');
             gmark.id = ('gmark_' + Edge.from + '_' + Edge.to);
             gmark.setAttribute('d', 'M ' + from.x + ',' + from.y + ' ' + to.x   + ',' + to.y);
             gmark.setAttribute('style', 'fill:none;stroke:#00F;stroke-width:1');
             gg.insertBefore(gmark, null);
         }
     }

     if (source) {
         for (i in source) {
             lane.period = source[i].period ? source[i].period    : 1;
             lane.phase  = (source[i].phase  ? source[i].phase * 2 : 0) + lane.xmin_cfg;
             text = source[i].node;
             if (text) {
                 Stack = text.split('');
                 pos = 0;
                 while (Stack.length) {
                     eventname = Stack.shift();
                     if (eventname !== '.') {
                         Events[eventname] = {
                             'x' : lane.xs * (2 * pos * lane.period * lane.hscale - lane.phase) + lane.xlabel,
                             'y' : i * lane.yo + lane.y0 + lane.ys * 0.5
                         };
                     }
                     pos += 1;
                 }
             }
         }
         gg = document.createElementNS(w3.svg, 'g');
         gg.id = 'wavearcs_' + index;
         root.insertBefore(gg, null);
         if (top.edge) {
             for (i in top.edge) {
                 Edge.words = top.edge[i].split(' ');
                 Edge.label = top.edge[i].substring(Edge.words[0].length);
                 Edge.label = Edge.label.substring(1);
                 Edge.from  = Edge.words[0].substr(0, 1);
                 Edge.to    = Edge.words[0].substr(-1, 1);
                 Edge.shape = Edge.words[0].slice(1, -1);
                 from  = Events[Edge.from];
                 to    = Events[Edge.to];
                 t1();
                 if (from && to) {
                     if (Edge.label) {
                         label = tspan.parse(Edge.label);
                         label.unshift(
                             'text',
                             {
                                 style: 'font-size:10px;',
                                 'text-anchor': 'middle',
                                 'xml:space': 'preserve'
                             }
                         );
                         label = jsonmlParse(label);
                         underlabel = jsonmlParse(['rect',
                             {
                                 height: 9,
                                 style: 'fill:#FFF;'
                             }
                         ]);
                         gg.insertBefore(underlabel, null);
                         gg.insertBefore(label, null);

                         lwidth = label.getBBox().width;

                         underlabel.setAttribute('width', lwidth);
                     }
                     dx = to.x - from.x;
                     dy = to.y - from.y;
                     lx = ((from.x + to.x) / 2);
                     ly = ((from.y + to.y) / 2);

                     switch (Edge.shape) {
                         case '-'  : {
                             break;
                         }
                         case '~'  : {
                             gmark.setAttribute('d', 'M ' + from.x + ',' + from.y + ' c ' + (0.7 * dx) + ', 0 ' + (0.3 * dx) + ', ' + dy + ' ' + dx + ', ' + dy);
                             break;
                         }
                         case '-~' : {
                             gmark.setAttribute('d', 'M ' + from.x + ',' + from.y + ' c ' + (0.7 * dx) + ', 0 ' +         dx + ', ' + dy + ' ' + dx + ', ' + dy);
                             if (Edge.label) { lx = (from.x + (to.x - from.x) * 0.75); }
                             break;
                         }
                         case '~-' : {
                             gmark.setAttribute('d', 'M ' + from.x + ',' + from.y + ' c ' + 0          + ', 0 ' + (0.3 * dx) + ', ' + dy + ' ' + dx + ', ' + dy);
                             if (Edge.label) { lx = (from.x + (to.x - from.x) * 0.25); }
                             break;
                         }
                         case '-|' : {
                             gmark.setAttribute('d', 'm ' + from.x + ',' + from.y + ' ' + dx + ',0 0,' + dy);
                             if (Edge.label) { lx = to.x; }
                             break;
                         }
                         case '|-' : {
                             gmark.setAttribute('d', 'm ' + from.x + ',' + from.y + ' 0,' + dy + ' ' + dx + ',0');
                             if (Edge.label) { lx = from.x; }
                             break;
                         }
                         case '-|-': {
                             gmark.setAttribute('d', 'm ' + from.x + ',' + from.y + ' ' + (dx / 2) + ',0 0,' + dy + ' ' + (dx / 2) + ',0');
                             break;
                         }
                         case '->' : {
                             gmark.setAttribute('style', 'marker-end:url(#arrowhead);stroke:#0041c4;stroke-width:1;fill:none');
                             break;
                         }
                         case '~>' : {
                             gmark.setAttribute('style', 'marker-end:url(#arrowhead);stroke:#0041c4;stroke-width:1;fill:none');
                             gmark.setAttribute('d', 'M ' + from.x + ',' + from.y + ' ' + 'c ' + (0.7 * dx) + ', 0 ' + 0.3 * dx + ', ' + dy + ' ' + dx + ', ' + dy);
                             break;
                         }
                         case '-~>': {
                             gmark.setAttribute('style', 'marker-end:url(#arrowhead);stroke:#0041c4;stroke-width:1;fill:none');
                             gmark.setAttribute('d', 'M ' + from.x + ',' + from.y + ' ' + 'c ' + (0.7 * dx) + ', 0 ' +     dx + ', ' + dy + ' ' + dx + ', ' + dy);
                             if (Edge.label) { lx = (from.x + (to.x - from.x) * 0.75); }
                             break;
                         }
                         case '~->': {
                             gmark.setAttribute('style', 'marker-end:url(#arrowhead);stroke:#0041c4;stroke-width:1;fill:none');
                             gmark.setAttribute('d', 'M ' + from.x + ',' + from.y + ' ' + 'c ' + 0      + ', 0 ' + (0.3 * dx) + ', ' + dy + ' ' + dx + ', ' + dy);
                             if (Edge.label) { lx = (from.x + (to.x - from.x) * 0.25); }
                             break;
                         }
                         case '-|>' : {
                             gmark.setAttribute('style', 'marker-end:url(#arrowhead);stroke:#0041c4;stroke-width:1;fill:none');
                             gmark.setAttribute('d', 'm ' + from.x + ',' + from.y + ' ' + dx + ',0 0,' + dy);
                             if (Edge.label) { lx = to.x; }
                             break;
                         }
                         case '|->' : {
                             gmark.setAttribute('style', 'marker-end:url(#arrowhead);stroke:#0041c4;stroke-width:1;fill:none');
                             gmark.setAttribute('d', 'm ' + from.x + ',' + from.y + ' 0,' + dy + ' ' + dx + ',0');
                             if (Edge.label) { lx = from.x; }
                             break;
                         }
                         case '-|->': {
                             gmark.setAttribute('style', 'marker-end:url(#arrowhead);stroke:#0041c4;stroke-width:1;fill:none');
                             gmark.setAttribute('d', 'm ' + from.x + ',' + from.y + ' ' + (dx / 2) + ',0 0,' + dy + ' ' + (dx / 2) + ',0');
                             break;
                         }
                         case '<->' : {
                             gmark.setAttribute('style', 'marker-end:url(#arrowhead);marker-start:url(#arrowtail);stroke:#0041c4;stroke-width:1;fill:none');
                             break;
                         }
                         case '<~>' : {
                             gmark.setAttribute('style', 'marker-end:url(#arrowhead);marker-start:url(#arrowtail);stroke:#0041c4;stroke-width:1;fill:none');
                             gmark.setAttribute('d', 'M ' + from.x + ',' + from.y + ' ' + 'c ' + (0.7 * dx) + ', 0 ' + (0.3 * dx) + ', ' + dy + ' ' + dx + ', ' + dy);
                             break;
                         }
                         case '<-~>': {
                             gmark.setAttribute('style', 'marker-end:url(#arrowhead);marker-start:url(#arrowtail);stroke:#0041c4;stroke-width:1;fill:none');
                             gmark.setAttribute('d', 'M ' + from.x + ',' + from.y + ' ' + 'c ' + (0.7 * dx) + ', 0 ' +     dx + ', ' + dy + ' ' + dx + ', ' + dy);
                             if (Edge.label) { lx = (from.x + (to.x - from.x) * 0.75); }
                             break;
                         }
                         case '<-|>' : {
                             gmark.setAttribute('style', 'marker-end:url(#arrowhead);marker-start:url(#arrowtail);stroke:#0041c4;stroke-width:1;fill:none');
                             gmark.setAttribute('d', 'm ' + from.x + ',' + from.y + ' ' + dx + ',0 0,' + dy);
                             if (Edge.label) { lx = to.x; }
                             break;
                         }
                         case '<-|->': {
                             gmark.setAttribute('style', 'marker-end:url(#arrowhead);marker-start:url(#arrowtail);stroke:#0041c4;stroke-width:1;fill:none');
                             gmark.setAttribute('d', 'm ' + from.x + ',' + from.y + ' ' + (dx / 2) + ',0 0,' + dy + ' ' + (dx / 2) + ',0');
                             break;
                         }
                         default   : { gmark.setAttribute('style', 'fill:none;stroke:#F00;stroke-width:1'); }
                     }
                     if (Edge.label) {
                         label.setAttribute('x', lx);
                         label.setAttribute('y', ly + 3);
                         underlabel.setAttribute('x', lx - lwidth / 2);
                         underlabel.setAttribute('y', ly - 5);
                     }
                 }
             }
         }
         for (k in Events) {
             if (k === k.toLowerCase()) {
                 if (Events[k].x > 0) {
                     underlabel = jsonmlParse(['rect',
                         {
                             y: Events[k].y - 4,
                             height: 8,
                             style: 'fill:#FFF;'
                         }
                     ]);
                     label = jsonmlParse(['text',
                         {
                             style: 'font-size:8px;',
                             x: Events[k].x,
                             y: Events[k].y + 2,
                             'text-anchor': 'middle'
                         },
                         (k + '')
                     ]);

                     gg.insertBefore(underlabel, null);
                     gg.insertBefore(label, null);

                     lwidth = label.getBBox().width + 2;

                     underlabel.setAttribute('x', Events[k].x - lwidth / 2);
                     underlabel.setAttribute('width', lwidth);
                 }
             }
         }
     }
 }

module.exports = renderArcs;

/* eslint-env browser */

},{"./create-element":3,"./w3":31,"tspan":1}],25:[function(require,module,exports){
'use strict';

var jsonmlParse = require('./create-element');

function render (tree, state) {
    var y, i, ilen;

    state.xmax = Math.max(state.xmax, state.x);
    y = state.y;
    ilen = tree.length;
    for (i = 1; i < ilen; i++) {
        if (Object.prototype.toString.call(tree[i]) === '[object Array]') {
            state = render(tree[i], {x: (state.x + 1), y: state.y, xmax: state.xmax});
        } else {
            tree[i] = {name:tree[i], x: (state.x + 1), y: state.y};
            state.y += 2;
        }
    }
    tree[0] = {name: tree[0], x: state.x, y: Math.round((y + (state.y - 2)) / 2)};
    state.x--;
    return state;
}

function draw_body (type, ymin, ymax) {
    var e,
        iecs,
        circle = ' M 4,0 C 4,1.1 3.1,2 2,2 0.9,2 0,1.1 0,0 c 0,-1.1 0.9,-2 2,-2 1.1,0 2,0.9 2,2 z',
        gates = {
            '~':  'M -11,-6 -11,6 0,0 z m -5,6 5,0' + circle,
            '=':  'M -11,-6 -11,6 0,0 z m -5,6 5,0',
            '&':  'm -16,-10 5,0 c 6,0 11,4 11,10 0,6 -5,10 -11,10 l -5,0 z',
            '~&': 'm -16,-10 5,0 c 6,0 11,4 11,10 0,6 -5,10 -11,10 l -5,0 z' + circle,
            '|':  'm -18,-10 4,0 c 6,0 12,5 14,10 -2,5 -8,10 -14,10 l -4,0 c 2.5,-5 2.5,-15 0,-20 z',
            '~|': 'm -18,-10 4,0 c 6,0 12,5 14,10 -2,5 -8,10 -14,10 l -4,0 c 2.5,-5 2.5,-15 0,-20 z' + circle,
            '^':  'm -21,-10 c 1,3 2,6 2,10 m 0,0 c 0,4 -1,7 -2,10 m 3,-20 4,0 c 6,0 12,5 14,10 -2,5 -8,10 -14,10 l -4,0 c 1,-3 2,-6 2,-10 0,-4 -1,-7 -2,-10 z',
            '~^': 'm -21,-10 c 1,3 2,6 2,10 m 0,0 c 0,4 -1,7 -2,10 m 3,-20 4,0 c 6,0 12,5 14,10 -2,5 -8,10 -14,10 l -4,0 c 1,-3 2,-6 2,-10 0,-4 -1,-7 -2,-10 z' + circle,
            '+':  'm -8,5 0,-10 m -5,5 10,0 m 3,0 c 0,4.418278 -3.581722,8 -8,8 -4.418278,0 -8,-3.581722 -8,-8 0,-4.418278 3.581722,-8 8,-8 4.418278,0 8,3.581722 8,8 z',
            '*':  'm -4,4 -8,-8 m 0,8 8,-8 m 4,4 c 0,4.418278 -3.581722,8 -8,8 -4.418278,0 -8,-3.581722 -8,-8 0,-4.418278 3.581722,-8 8,-8 4.418278,0 8,3.581722 8,8 z'
        },
        iec = {
            BUF: 1, INV: 1, AND: '&',  NAND: '&',
            OR: '\u22651', NOR: '\u22651', XOR: '=1', XNOR: '=1', box: ''
        },
        circled = { INV: 1, NAND: 1, NOR: 1, XNOR: 1 };

    if (ymax === ymin) {
        ymax = 4; ymin = -4;
    }
    e = gates[type];
    iecs = iec[type];
    if (e) {
        return ['path', {class:'gate', d: e}];
    } else {
        if (iecs) {
            return [
                'g', [
                    'path', {
                        class:'gate',
                        d: 'm -16,' + (ymin - 3) + ' 16,0 0,' + (ymax - ymin + 6) + ' -16,0 z' + (circled[type] ? circle : '')
                    }], [
                    'text', [
                        'tspan', {x: '-14', y: '4', class: 'wirename'}, iecs + ''
                    ]
                ]
            ];
        } else {
            return ['text', ['tspan', {x: '-14', y: '4', class: 'wirename'}, type + '']];
        }
    }
}

function draw_gate (spec) { // ['type', [x,y], [x,y] ... ]
    var i,
        ret = ['g'],
        ys = [],
        ymin,
        ymax,
        ilen = spec.length;

    for (i = 2; i < ilen; i++) {
        ys.push(spec[i][1]);
    }

    ymin = Math.min.apply(null, ys);
    ymax = Math.max.apply(null, ys);

    ret.push(
        ['g',
            {transform:'translate(16,0)'},
            ['path', {
                d: 'M  ' + spec[2][0] + ',' + ymin + ' ' + spec[2][0] + ',' + ymax,
                class: 'wire'
            }]
        ]
    );

    for (i = 2; i < ilen; i++) {
        ret.push(
            ['g',
                ['path',
                    {
                        d: 'm  ' + spec[i][0] + ',' + spec[i][1] + ' 16,0',
                        class: 'wire'
                    }
                ]
            ]
        );
    }
    ret.push(
        ['g', { transform: 'translate(' + spec[1][0] + ',' + spec[1][1] + ')' },
            ['title', spec[0]],
            draw_body(spec[0], ymin - spec[1][1], ymax - spec[1][1])
        ]
    );
    return ret;
}

function draw_boxes (tree, xmax) {
    var ret = ['g'], i, ilen, fx, fy, fname, spec = [];
    if (Object.prototype.toString.call(tree) === '[object Array]') {
        ilen = tree.length;
        spec.push(tree[0].name);
        spec.push([32 * (xmax - tree[0].x), 8 * tree[0].y]);
        for (i = 1; i < ilen; i++) {
            if (Object.prototype.toString.call(tree[i]) === '[object Array]') {
                spec.push([32 * (xmax - tree[i][0].x), 8 * tree[i][0].y]);
            } else {
                spec.push([32 * (xmax - tree[i].x), 8 * tree[i].y]);
            }
        }
        ret.push(draw_gate(spec));
        for (i = 1; i < ilen; i++) {
            ret.push(draw_boxes(tree[i], xmax));
        }
    } else {
        fname = tree.name;
        fx = 32 * (xmax - tree.x);
        fy = 8 * tree.y;
        ret.push(
            ['g', { transform: 'translate(' + fx + ',' + fy + ')'},
                ['title', fname],
                ['path', {d:'M 2,0 a 2,2 0 1 1 -4,0 2,2 0 1 1 4,0 z'}],
                ['text',
                    ['tspan', {
                        x:'-4', y:'4',
                        class:'pinname'},
                        fname
                    ]
                ]
            ]
        );
    }
    return ret;
}

function renderAssign (index, source) {
    var tree,
        state,
        xmax,
        svg = ['g'],
        grid = ['g'],
        svgcontent,
        width,
        height,
        i,
        ilen,
        j,
        jlen;

    ilen = source.assign.length;
    state = { x: 0, y: 2, xmax: 0 };
    tree = source.assign;
    for (i = 0; i < ilen; i++) {
        state = render(tree[i], state);
        state.x++;
    }
    xmax = state.xmax + 3;

    for (i = 0; i < ilen; i++) {
        svg.push(draw_boxes(tree[i], xmax));
    }
    width  = 32 * (xmax + 1) + 1;
    height = 8 * (state.y + 1) - 7;
    ilen = 4 * (xmax + 1);
    jlen = state.y + 1;
    for (i = 0; i <= ilen; i++) {
        for (j = 0; j <= jlen; j++) {
            grid.push(['rect', {
                height: 1,
                width: 1,
                x: (i * 8 - 0.5),
                y: (j * 8 - 0.5),
                class: 'grid'
            }]);
        }
    }
    svgcontent = document.getElementById('svgcontent_' + index);
    svgcontent.setAttribute('viewBox', '0 0 ' + width + ' ' + height);
    svgcontent.setAttribute('width', width);
    svgcontent.setAttribute('height', height);
    svgcontent.insertBefore(jsonmlParse(['g', {transform:'translate(0.5, 0.5)'}, grid, svg]), null);
}

module.exports = renderAssign;

/* eslint-env browser */

},{"./create-element":3}],26:[function(require,module,exports){
'use strict';

var w3 = require('./w3');

function renderGaps (root, source, index, lane) {
    var i, gg, g, b, pos, Stack = [], text, subCycle, next;

    if (source) {

        gg = document.createElementNS(w3.svg, 'g');
        gg.id = 'wavegaps_' + index;
        root.insertBefore(gg, null);
        subCycle = false;
        for (i in source) {
            lane.period = source[i].period ? source[i].period    : 1;
            lane.phase  = (source[i].phase  ? source[i].phase * 2 : 0) + lane.xmin_cfg;
            g = document.createElementNS(w3.svg, 'g');
            g.id = 'wavegap_' + i + '_' + index;
            g.setAttribute('transform', 'translate(0,' + (lane.y0 + i * lane.yo) + ')');
            gg.insertBefore(g, null);

            text = source[i].wave;
            if (text) {
                Stack = text.split('');
                pos = 0;
                while (Stack.length) {
                    next = Stack.shift();
                    if (next === '<') { // sub-cycles on
                        subCycle = true;
                        next = Stack.shift();
                    }
                    if (next === '>') { // sub-cycles off
                        subCycle = false;
                        next = Stack.shift();
                    }
                    if (subCycle) {
                        pos += 1;
                    } else {
                        pos += (2 * lane.period);
                    }
                    if (next === '|') {
                        b    = document.createElementNS(w3.svg, 'use');
                        // b.id = 'guse_' + pos + '_' + i + '_' + index;
                        b.setAttributeNS(w3.xlink, 'xlink:href', '#gap');
                        b.setAttribute('transform', 'translate(' + (lane.xs * ((pos - (subCycle ? 0 : lane.period)) * lane.hscale - lane.phase)) + ')');
                        g.insertBefore(b, null);
                    }
                }
            }
        }
    }
}

module.exports = renderGaps;

/* eslint-env browser */

},{"./w3":31}],27:[function(require,module,exports){
'use strict';

var tspan = require('tspan');

function renderGroups (groups, index, lane) {
    var x, y, res = ['g'], ts;

    groups.forEach(function (e, i) {
        res.push(['path',
            {
                id: 'group_' + i + '_' + index,
                d: ('m ' + (e.x + 0.5) + ',' + (e.y * lane.yo + 3.5 + lane.yh0 + lane.yh1)
                    + ' c -3,0 -5,2 -5,5 l 0,' + (e.height * lane.yo - 16)
                    + ' c 0,3 2,5 5,5'),
                style: 'stroke:#0041c4;stroke-width:1;fill:none'
            }
        ]);

        if (e.name === undefined) { return; }

        x = (e.x - 10);
        y = (lane.yo * (e.y + (e.height / 2)) + lane.yh0 + lane.yh1);
        ts = tspan.parse(e.name);
        ts.unshift(
            'text',
            {
                'text-anchor': 'middle',
                class: 'info',
                'xml:space': 'preserve'
            }
        );
        res.push(['g', {transform: 'translate(' + x + ',' + y + ')'}, ['g', {transform: 'rotate(270)'}, ts]]);
    });
    return res;
}

module.exports = renderGroups;

/* eslint-env browser */

},{"tspan":1}],28:[function(require,module,exports){
'use strict';

var tspan = require('tspan'),
    jsonmlParse = require('./create-element');
    // w3 = require('./w3');

function renderMarks (root, content, index, lane) {
    var i, g, marks, mstep, mmstep, gy; // svgns

    function captext (cxt, anchor, y) {
        var tmark;

        if (cxt[anchor] && cxt[anchor].text) {
            tmark = tspan.parse(cxt[anchor].text);
            tmark.unshift(
                'text',
                {
                    x: cxt.xmax * cxt.xs / 2,
                    y: y,
                    'text-anchor': 'middle',
                    fill: '#000',
                    'xml:space': 'preserve'
                }
            );
            tmark = jsonmlParse(tmark);
            g.insertBefore(tmark, null);
        }
    }

    function ticktock (cxt, ref1, ref2, x, dx, y, len) {
        var tmark, step = 1, offset, dp = 0, val, L = [], tmp;

        if (cxt[ref1] === undefined || cxt[ref1][ref2] === undefined) { return; }
        val = cxt[ref1][ref2];
        if (typeof val === 'string') {
            val = val.split(' ');
        } else if (typeof val === 'number' || typeof val === 'boolean') {
            offset = Number(val);
            val = [];
            for (i = 0; i < len; i += 1) {
                val.push(i + offset);
            }
        }
        if (Object.prototype.toString.call(val) === '[object Array]') {
            if (val.length === 0) {
                return;
            } else if (val.length === 1) {
                offset = Number(val[0]);
                if (isNaN(offset)) {
                    L = val;
                } else {
                    for (i = 0; i < len; i += 1) {
                        L[i] = i + offset;
                    }
                }
            } else if (val.length === 2) {
                offset = Number(val[0]);
                step   = Number(val[1]);
                tmp = val[1].split('.');
                if ( tmp.length === 2 ) {
                    dp = tmp[1].length;
                }
                if (isNaN(offset) || isNaN(step)) {
                    L = val;
                } else {
                    offset = step * offset;
                    for (i = 0; i < len; i += 1) {
                        L[i] = (step * i + offset).toFixed(dp);
                    }
                }
            } else {
                L = val;
            }
        } else {
            return;
        }
        for (i = 0; i < len; i += 1) {
            tmp = L[i];
            //  if (typeof tmp === 'number') { tmp += ''; }
            tmark = tspan.parse(tmp);
            tmark.unshift(
                'text',
                {
                    x: i * dx + x,
                    y: y,
                    'text-anchor': 'middle',
                    class: 'muted',
                    'xml:space': 'preserve'
                }
            );
            tmark = jsonmlParse(tmark);
            g.insertBefore(tmark, null);
        }
    }

     mstep  = 2 * (lane.hscale);
     mmstep = mstep * lane.xs;
     marks  = lane.xmax / mstep;
     gy     = content.length * lane.yo;

     g = jsonmlParse(['g', {id: ('gmarks_' + index)}]);
     root.insertBefore(g, root.firstChild);

     for (i = 0; i < (marks + 1); i += 1) {
         g.insertBefore(
             jsonmlParse([
                 'path',
                 {
                     id:    'gmark_' + i + '_' + index,
                     d:     'm ' + (i * mmstep) + ',' + 0 + ' 0,' + gy,
                     style: 'stroke:#888;stroke-width:0.5;stroke-dasharray:1,3'
                 }
             ]),
             null
         );
     }

     captext(lane, 'head', (lane.yh0 ? -33 : -13));
     captext(lane, 'foot', gy + (lane.yf0 ? 45 : 25));

     ticktock(lane, 'head', 'tick',          0, mmstep,      -5, marks + 1);
     ticktock(lane, 'head', 'tock', mmstep / 2, mmstep,      -5, marks);
     ticktock(lane, 'foot', 'tick',          0, mmstep, gy + 15, marks + 1);
     ticktock(lane, 'foot', 'tock', mmstep / 2, mmstep, gy + 15, marks);
 }

module.exports = renderMarks;

/* eslint-env browser */

},{"./create-element":3,"tspan":1}],29:[function(require,module,exports){
'use strict';

var rec = require('./rec'),
    lane = require('./lane'),
    jsonmlParse = require('./create-element'),
    parseConfig = require('./parse-config'),
    parseWaveLanes = require('./parse-wave-lanes'),
    renderMarks = require('./render-marks'),
    renderGaps = require('./render-gaps'),
    renderGroups = require('./render-groups'),
    renderWaveLane = require('./render-wave-lane'),
    renderAssign = require('./render-assign'),
    renderArcs = require('./render-arcs'),
    insertSVGTemplate = require('./insert-svg-template'),
    insertSVGTemplateAssign = require('./insert-svg-template-assign');

function renderWaveForm (index, source, output) {
    var ret,
    root, groups, svgcontent, content, width, height,
    glengths, xmax = 0, i;

    if (source.signal) {
        insertSVGTemplate(index, document.getElementById(output + index), source, lane);
        parseConfig(source, lane);
        ret = rec(source.signal, {'x':0, 'y':0, 'xmax':0, 'width':[], 'lanes':[], 'groups':[]});
        root = document.getElementById('lanes_' + index);
        groups = document.getElementById('groups_' + index);
        content  = parseWaveLanes(ret.lanes, lane);
        glengths = renderWaveLane(root, content, index, lane);
        for (i in glengths) {
            xmax = Math.max(xmax, (glengths[i] + ret.width[i]));
        }
        renderMarks(root, content, index, lane);
        renderArcs(root, ret.lanes, index, source, lane);
        renderGaps(root, ret.lanes, index, lane);
        groups.insertBefore(jsonmlParse(renderGroups(ret.groups, index, lane)), null);
        lane.xg = Math.ceil((xmax - lane.tgo) / lane.xs) * lane.xs;
        width  = (lane.xg + (lane.xs * (lane.xmax + 1)));
        height = (content.length * lane.yo +
        lane.yh0 + lane.yh1 + lane.yf0 + lane.yf1);

        svgcontent = document.getElementById('svgcontent_' + index);
        svgcontent.setAttribute('viewBox', '0 0 ' + width + ' ' + height);
        svgcontent.setAttribute('width', width);
        svgcontent.setAttribute('height', height);
        svgcontent.setAttribute('overflow', 'hidden');
        root.setAttribute('transform', 'translate(' + (lane.xg + 0.5) + ', ' + ((lane.yh0 + lane.yh1) + 0.5) + ')');
    } else if (source.assign) {
        insertSVGTemplateAssign(index, document.getElementById(output + index), source);
        renderAssign(index, source);
    }
}

module.exports = renderWaveForm;

/* eslint-env browser */

},{"./create-element":3,"./insert-svg-template":12,"./insert-svg-template-assign":11,"./lane":18,"./parse-config":19,"./parse-wave-lanes":21,"./rec":23,"./render-arcs":24,"./render-assign":25,"./render-gaps":26,"./render-groups":27,"./render-marks":28,"./render-wave-lane":30}],30:[function(require,module,exports){
'use strict';

var tspan = require('tspan'),
    jsonmlParse = require('./create-element'),
    w3 = require('./w3'),
    findLaneMarkers = require('./find-lane-markers');

function renderWaveLane (root, content, index, lane) {
    var i,
        j,
        k,
        g,
        gg,
        title,
        b,
        labels = [1],
        name,
        xoffset,
        xmax     = 0,
        xgmax    = 0,
        glengths = [];

    for (j = 0; j < content.length; j += 1) {
        name = content[j][0][0];
        if (name) { // check name
            g = jsonmlParse(['g',
                {
                    id: 'wavelane_' + j + '_' + index,
                    transform: 'translate(0,' + ((lane.y0) + j * lane.yo) + ')'
                }
            ]);
            root.insertBefore(g, null);
            title = tspan.parse(name);
            title.unshift(
                'text',
                {
                    x: lane.tgo,
                    y: lane.ym,
                    class: 'info',
                    'text-anchor': 'end',
                    'xml:space': 'preserve'
                }
            );
            title = jsonmlParse(title);
            g.insertBefore(title, null);

            // scale = lane.xs * (lane.hscale) * 2;

            glengths.push(title.getBBox().width);

            xoffset = content[j][0][1];
            xoffset = (xoffset > 0) ? (Math.ceil(2 * xoffset) - 2 * xoffset) :
            (-2 * xoffset);
            gg = jsonmlParse(['g',
                {
                    id: 'wavelane_draw_' + j + '_' + index,
                    transform: 'translate(' + (xoffset * lane.xs) + ', 0)'
                }
            ]);
            g.insertBefore(gg, null);

            if (content[j][1]) {
                for (i = 0; i < content[j][1].length; i += 1) {
                    b = document.createElementNS(w3.svg, 'use');
                    // b.id = 'use_' + i + '_' + j + '_' + index;
                    b.setAttributeNS(w3.xlink, 'xlink:href', '#' + content[j][1][i]);
                    // b.setAttribute('transform', 'translate(' + (i * lane.xs) + ')');
                    b.setAttribute('transform', 'translate(' + (i * lane.xs) + ')');
                    gg.insertBefore(b, null);
                }
                if (content[j][2] && content[j][2].length) {
                    labels = findLaneMarkers(content[j][1]);

                    if (labels.length !== 0) {
                        for (k in labels) {
                            if (content[j][2] && (typeof content[j][2][k] !== 'undefined')) {
                                title = tspan.parse(content[j][2][k]);
                                title.unshift(
                                    'text',
                                    {
                                        x: labels[k] * lane.xs + lane.xlabel,
                                        y: lane.ym,
                                        'text-anchor': 'middle',
                                        'xml:space': 'preserve'
                                    }
                                );
                                title = jsonmlParse(title);
                                gg.insertBefore(title, null);
                            }
                        }
                    }
                }
                if (content[j][1].length > xmax) {
                    xmax = content[j][1].length;
                }
            }
        }
    }
    // xmax if no xmax_cfg,xmin_cfg, else set to config
    lane.xmax = Math.min(xmax, lane.xmax_cfg - lane.xmin_cfg);
    lane.xg = xgmax + 20;
    return glengths;
}

module.exports = renderWaveLane;

/* eslint-env browser */

},{"./create-element":3,"./find-lane-markers":6,"./w3":31,"tspan":1}],31:[function(require,module,exports){
'use strict';

module.exports = {
    svg: 'http://www.w3.org/2000/svg',
    xlink: 'http://www.w3.org/1999/xlink',
    xmlns: 'http://www.w3.org/XML/1998/namespace'
};

},{}],32:[function(require,module,exports){
'use strict';

module.exports = window.WaveSkin;

/* eslint-env browser */

},{}],33:[function(require,module,exports){
/* wavedrom begin */

module.exports = require('wavedrom');

/* wavedrom end */

},{"wavedrom":10}]},{},[33])(33)
});/* foot begin */

// some parameters
var lane = {
    xs     : 10,    // tmpgraphlane0.width
    ys     : 10,    // tmpgraphlane0.height
    xg     : 120,   // tmpgraphlane0.x
    // yg     : 0,     // head gap
    yh0    : 0,     // head gap title
    yh1    : 0,     // head gap
    yf0    : 0,     // foot gap
    yf1    : 0,     // foot gap
    y0     : 5,     // tmpgraphlane0.y
    yo     : 30,    // tmpgraphlane1.y - y0;
    tgo    : -10,   // tmptextlane0.x - xg;
    ym     : 150,    // tmptextlane0.y - y0
    xlabel : 6,     // tmptextlabel.x - xg;
    xmax   : 1,
    scale  : 1,
    head   : {},
    foot   : {}
};

// add div into body
var div = document.createElement('div');
div.id = 'a0';
document.body.appendChild(div);

// added waveform
module.exports.renderWaveForm(0, source, 'a', lane);

var svgcontent_0 = document.getElementById('svgcontent_0');
var ser = new XMLSerializer();
var svg = '<?xml version="1.0" standalone="no"?>\n'
    + '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">\n'
    + '<!-- Created with WaveDrom -->\n'
    + ser.serializeToString(svgcontent_0);

return '{ "width": ' + svgcontent_0.getAttribute('width')
    + ', "height": ' + svgcontent_0.getAttribute('height')
    + ', "svg": ' + JSON.stringify(svg)
    + '}';

}

// console.log(JSON.stringify(typeof argumist()));

var argv = argumist()(system.args);

var sourceContent,
    sourceFileName,
    sourceFileContent;

if (typeof argv.i === 'string') {
    if (argv.i === '-') {
        // Read from stdin
        sourceFileContent = system.stdin.read();
    } else {
        // Read from file
        sourceFileName = argv.i;
        try {
            sourceFileContent = fs.read(sourceFileName);
        } catch (err) {
            console.log(err);
            phantom.exit(1);
        }
    }
} else {
    console.log('use -i <file> option to provide input file name');
    phantom.exit(1);
}

if (!argv.s && !argv.p) {
    console.log('no output file specified');
    phantom.exit(1);
}

try {
    eval('sourceContent = ' + sourceFileContent);
} catch (err) {
    console.log(err);
    phantom.exit(1);
}

if (sourceContent === undefined) {
    console.log('source file is not WaveDrom compatible');
    phantom.exit(1);
}

page.content = '<!DOCTYPE html><meta charset="utf-8"><body></body></html>';

var svgFileName,
    svgFileContent,
    pngFileName,
    pngFileContent,
    report;

try {
    report = page.evaluate(pagegen, sourceContent);
    report = JSON.parse(report);
    page.viewportSize = { width: report.width, height: report.height };

    if (typeof argv.s === 'string') {
        svgFileName = argv.s;
        svgFileContent = report.svg;
        if (argv.s === '-') {
            // Write to stdout
            system.stdout.write(svgFileContent);
        } else {
            // Write to file
            fs.write(svgFileName, svgFileContent, 'w');
        }
    }

    if (typeof argv.p === 'string') {
        pngFileName = argv.p;
        page.render(pngFileName);
    }

    phantom.exit(0);
} catch (err) {
    console.log(err);
    phantom.exit(1);
}

/* foot end */
